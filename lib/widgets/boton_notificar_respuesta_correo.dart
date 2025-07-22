import 'package:flutter/material.dart';

import '../services/whatsapp_service.dart';
import '../src/colors/colors.dart';

class BotonNotificarRespuestaWhatsApp extends StatelessWidget {
  final String celular;
  final String docId;
  final String servicio;
  final String seguimiento;
  final String seccionHistorial;

  const BotonNotificarRespuestaWhatsApp({
    Key? key,
    required this.celular,
    required this.docId,
    required this.servicio,
    required this.seguimiento,
    required this.seccionHistorial,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () async {
        try {
          String numero = celular.trim();

          // Validación: número vacío
          if (numero.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El número de celular no está disponible.')),
            );
            return;
          }

          // Formateo del número
          if (!numero.startsWith('57')) {
            if (numero.startsWith('0')) {
              numero = '57${numero.substring(1)}';
            } else {
              numero = '57$numero';
            }
          }

          if (numero.length != 12) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El número de celular no es válido.')),
            );
            return;
          }

          // Imprimir datos enviados
          print({
            "numero": numero,
            "docId": docId,
            "servicio": servicio,
            "seguimiento": seguimiento,
            "seccionHistorial": seccionHistorial,
          });

          // Enviar notificación
          await WhatsappService.enviarNotificacionRespuesta(
            numero: numero,
            docId: docId,
            servicio: servicio,
            seguimiento: seguimiento,
            seccionHistorial: seccionHistorial,
          );

          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: blanco,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('Mensaje enviado'),
                content: const Text(
                  'Se notificó por WhatsApp que hay una respuesta a la solicitud.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar WhatsApp: $e')),
          );
        }
      },

      icon: Image.asset(
        'assets/images/icono_whatsapp.png',
        height: 24,
        width: 24,
      ),
      label: const Text("Notificar respuesta"),
    );
  }
}
