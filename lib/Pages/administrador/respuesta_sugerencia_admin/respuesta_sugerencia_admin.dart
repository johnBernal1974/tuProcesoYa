import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import 'package:url_launcher/url_launcher.dart';

class RespuestaSugerenciaPage extends StatefulWidget {
  final String userId;
  final String nombre;
  final String sugerencia;
  final String celular;

  const RespuestaSugerenciaPage({
    super.key,
    required this.userId,
    required this.nombre,
    required this.sugerencia,
    required this.celular,
  });

  @override
  _RespuestaSugerenciaPageState createState() => _RespuestaSugerenciaPageState();
}

class _RespuestaSugerenciaPageState extends State<RespuestaSugerenciaPage> {
  final TextEditingController _respuestaController = TextEditingController();
  bool _isLoading = false;

  Future<void> _enviarRespuesta() async {
    String respuestaTexto = _respuestaController.text.trim();
    if (respuestaTexto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa una respuesta antes de enviar.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('buzon_sugerencias').doc(widget.userId).update({
        'respuesta': respuestaTexto,
        'respondido_por': 'Admin', // Reemplaza con el nombre del usuario autenticado
        'fecha_respuesta': FieldValue.serverTimestamp(),
        'contestado': true,
      });

      // Enviar mensaje por WhatsApp
      await enviarMensajeWhatsApp(widget.celular, widget.nombre, widget.sugerencia, respuestaTexto);

      if (mounted) {
        Navigator.pop(context, true); // Regresar con un resultado positivo
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al guardar la respuesta: $e");
      }
    }

    setState(() => _isLoading = false);
  }


  Future<void> enviarMensajeWhatsApp(
      String celular, String nombre, String sugerencia, String respuesta) async {
    if (celular.isEmpty) {
      if (kDebugMode) {
        print('El número de celular es inválido');
      }
      return;
    }
    if (!celular.startsWith("+57")) {
      celular = "+57$celular";
    }

    String mensaje = Uri.encodeComponent(
        "Hola, *$nombre*, gracias por tu comentario:\n _\"$sugerencia\"_\n\n*Respuesta:* $respuesta\n\nCordialmente,\nEquipo de *Tu Proceso Ya*.");
    String whatsappUrl = "https://wa.me/$celular?text=$mensaje";

    await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Respondiendo',
      content: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 800 ? 800 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📌 ${widget.nombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(widget.sugerencia, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _respuestaController,
                  decoration: const InputDecoration(
                    labelText: 'Escribe tu respuesta aquí...',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey), // 🔹 Borde gris
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey), // 🔹 Borde gris cuando no está enfocado
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey), // 🔹 Borde gris cuando está enfocado
                    ),
                  ),
                  maxLines: 3,
                  keyboardType: TextInputType.text,
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _enviarRespuesta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // Usa el color primario del tema
                    foregroundColor: Colors.white, // Color del texto
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar Respuesta'),
                )

              ],
            ),
          ),
        ),
      );

  }
}
