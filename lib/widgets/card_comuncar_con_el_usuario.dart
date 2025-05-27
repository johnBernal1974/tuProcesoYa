import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/colors/colors.dart';
import 'mensajes_whatsApp_opciones.dart';

class WhatsAppCardWidget extends StatefulWidget {
  final String celularWhatsApp;
  final String docId;

  const WhatsAppCardWidget({required this.celularWhatsApp, required this.docId, super.key});

  @override
  State<WhatsAppCardWidget> createState() => _WhatsAppCardWidgetState();
}

class _WhatsAppCardWidgetState extends State<WhatsAppCardWidget> {
  Map<String, bool> opciones = {
    'exclusion_art_68': false,
    'proceso_en_tribunal': false,
    'sin_juzgado_ejecucion': false,
    'sin_fecha_captura': false,
  };

  Map<String, bool> opcionesGuardarEliminar = {
    'proceso_en_tribunal': false,
    'sin_juzgado_ejecucion': false,
    'sin_fecha_captura': false,
  };

  String? opcionSeleccionada;

  void _seleccionarOpcion(String clave) {
    setState(() {
      opcionSeleccionada = clave;
      opciones.updateAll((key, value) => key == clave);
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarEventosDesdeFirestore();
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _cardComunicacionWhatsApp(),
        const SizedBox(height: 20),
        _cardEventosAdministrativos(),
      ],
    );
  }

  Future<void> _cargarEventosDesdeFirestore() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Ppl')
        .doc(widget.docId)
        .collection('eventos')
        .get();

    final eventosGuardados = snapshot.docs.map((doc) => doc.id).toSet();

    setState(() {
      opcionesGuardarEliminar = {
        for (var key in opcionesGuardarEliminar.keys)
          key: eventosGuardados.contains(key),
      };
    });
  }

  // 🔹 CARD 1 - Comunicación por WhatsApp
  Widget _cardComunicacionWhatsApp() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.grey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Divider(thickness: 1),
            ...opciones.entries.map((entry) {
              return CheckboxListTile(
                value: entry.value,
                title: Text(_tituloOpcion(entry.key)),
                onChanged: (bool? value) {
                  if (value == true) {
                    _seleccionarOpcion(entry.key);
                  }
                },
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  if (opcionSeleccionada != null) {
                    await enviarMensajeWhatsAppEventos(
                      widget.celularWhatsApp,
                      widget.docId,
                      opcionSeleccionada!,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Debes seleccionar una opción antes de enviar.")),
                    );
                  }
                },
                child: const Text("Enviar mensaje", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 CARD 2 - Eventos administrativos
  Widget _cardEventosAdministrativos() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.grey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Eventos administrativos (guardar/eliminar)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1),
            ...opcionesGuardarEliminar.entries.map((entry) {
              return CheckboxListTile(
                value: entry.value,
                title: Text(_tituloOpcion(entry.key)),
                onChanged: (bool? value) {
                  setState(() {
                    opcionesGuardarEliminar[entry.key] = value ?? false;
                  });
                },
              );
            }),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary, // fondo púrpura
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _guardarEventosAdministrativos,
                child: const Text(
                  "Guardar eventos administrativos",
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
      case 'sin_fecha_captura':
        return 'Sin fecha de captura';
      case 'sin_condena':
        return 'Sin condena registrada';
      case 'sin_juzgado_que_condeno':
        return 'Sin juzgado que condenó';
      default:
        return 'Opción desconocida';
    }
  }

  Future<void> _guardarEventosAdministrativos() async {
    for (var entry in opcionesGuardarEliminar.entries) {
      final eventoRef = FirebaseFirestore.instance
          .collection('Ppl')
          .doc(widget.docId)
          .collection('eventos')
          .doc(entry.key);

      if (entry.value) {
        await eventoRef.set({
          'tipo': entry.key,
          'enviadoPor': FirebaseAuth.instance.currentUser?.uid ?? "admin",
          'fecha': FieldValue.serverTimestamp(),
        });
      } else {
        await eventoRef.delete();
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Eventos administrativos actualizados")),
      );
    }
  }

  Future<void> enviarMensajeWhatsAppEventos(String celular, String docId, String tipoMensaje) async {
    if (celular.isEmpty) return;
    if (!celular.startsWith("+57")) celular = "+57$celular";

    String nombreAcudiente = "Estimado usuario";
    int diasPrueba = 7;

    try {
      final doc = await FirebaseFirestore.instance.collection('Ppl').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        nombreAcudiente = doc['nombre_acudiente'] ?? nombreAcudiente;
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

    final whatsappBusinessUri = Uri.parse("whatsapp://send?phone=$celular&text=$mensaje");
    final webUrl = Uri.parse("https://wa.me/$celular?text=$mensaje");

    if (await canLaunchUrl(whatsappBusinessUri)) {
      await launchUrl(whatsappBusinessUri);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }

    // 🔥 Eliminado: ya no se guarda nada aquí
  }

}
