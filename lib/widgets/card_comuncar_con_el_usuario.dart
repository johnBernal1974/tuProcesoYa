import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      child: InkWell(
        onTap: () async {
          if (opcionSeleccionada != null) {
            await enviarMensajeWhatsAppEventos(widget.celular, widget.docId, opcionSeleccionada!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Debes seleccionar una opción antes de enviar.")),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset("assets/images/icono_whatsapp.png", height: 32), // Reemplaza con tu icono
                  const SizedBox(width: 10),
                  const Text(
                    "Comunicar al usuario",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              )
            ],
          ),
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
  }

}
