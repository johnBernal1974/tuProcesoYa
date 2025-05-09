import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/colors/colors.dart';
import 'mensajes_whatsApp_opciones.dart';

class WhatsAppCardWidget extends StatefulWidget {
  final String celular;
  final String docId;

  const WhatsAppCardWidget({required this.celular, required this.docId, super.key});

  @override
  State<WhatsAppCardWidget> createState() => _WhatsAppCardWidgetState();
}

class _WhatsAppCardWidgetState extends State<WhatsAppCardWidget> {
  Map<String, bool> opciones = {
    'exclusion_art_68': false,
    'proceso_en_tribunal': false,
    'sin_juzgado_ejecucion': false,


  };

  String? opcionSeleccionada;

  void _seleccionarOpcion(String clave) {
    setState(() {
      opcionSeleccionada = clave;
      opciones.updateAll((key, value) => key == clave);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.grey, width: 1), // 🔹 Borde gris suave
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Encabezado con ícono y título
            Row(
              children: [
                Image.asset("assets/images/icono_whatsapp.png", height: 28),
                const SizedBox(width: 10),
                const Text(
                  "Comunicar al usuario",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(thickness: 1, color: Colors.grey),

            // 🔹 Opciones con checkboxes
            Column(
              children: opciones.entries.map((entry) {
                return CheckboxListTile(
                  value: entry.value,
                  title: Text(_tituloOpcion(entry.key)),
                  onChanged: (bool? value) {
                    if (value == true) {
                      _seleccionarOpcion(entry.key);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 🔹 Botón de enviar mensaje
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  if (opcionSeleccionada != null) {
                    await enviarMensajeWhatsAppEventos(
                      widget.celular,
                      widget.docId,
                      opcionSeleccionada!,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Debes seleccionar una opción antes de enviar.")),
                    );
                  }
                },
                child: const Text(
                  "Enviar mensaje",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _tituloOpcion(String key) {
    switch (key) {
      case 'exclusion_art_68':
        return 'Exclusión art. 68';
      case 'proceso_en_tribunal':
        return 'Proceso en tribunal';
      case 'sin_juzgado_ejecucion':
        return 'Juzgado EP sin asignar';
      default:
        return 'Opción desconocida';
    }
  }
  Future<void> enviarMensajeWhatsAppEventos(String celular, String docId, String tipoMensaje) async {
    if (celular.isEmpty) return;

    if (!celular.startsWith("+57")) {
      celular = "+57$celular";
    }

    String nombreAcudiente = "Estimado usuario";
    int diasPrueba = 7;

    try {
      final doc = await FirebaseFirestore.instance.collection('Ppl').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        nombreAcudiente = doc['nombre_acudiente'] ?? "Estimado usuario";
      }
    } catch (_) {}

    try {
      final config = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
      if (config.docs.isNotEmpty) {
        diasPrueba = config.docs.first.data()['tiempoDePrueba'] ?? 7;
      }
    } catch (_) {}

    String mensaje = Uri.encodeComponent(
      MensajesWhatsapp.generarMensaje(nombreAcudiente, diasPrueba, tipoMensaje),
    );

    String whatsappBusinessUri = "whatsapp://send?phone=$celular&text=$mensaje";
    String webUrl = "https://wa.me/$celular?text=$mensaje";

    if (await canLaunchUrl(Uri.parse(whatsappBusinessUri))) {
      await launchUrl(Uri.parse(whatsappBusinessUri));
    } else {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }

    // ✅ Guardar evento en subcolección 'eventos'
    await FirebaseFirestore.instance
        .collection('Ppl')
        .doc(docId)
        .collection('eventos')
        .doc(tipoMensaje)
        .set({
      'tipo': tipoMensaje,
      'enviadoPor': FirebaseAuth.instance.currentUser?.uid ?? "admin",
      'fecha': FieldValue.serverTimestamp(),
    });
  }
}
