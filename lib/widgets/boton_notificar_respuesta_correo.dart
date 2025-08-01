import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/whatsapp_service.dart';
import '../src/colors/colors.dart';

class BotonNotificarRespuestaWhatsApp extends StatelessWidget {
  final String docId; // ID de la solicitud en su colección
  final String servicio;
  final String seguimiento; // numeroSeguimiento
  final String seccionHistorial;

  const BotonNotificarRespuestaWhatsApp({
    Key? key,
    required this.docId,
    required this.servicio,
    required this.seguimiento,
    required this.seccionHistorial,
  }) : super(key: key);

  /// Obtiene el celularWhatsapp desde Ppl usando numeroSeguimiento → idUser
  Future<String?> _obtenerCelularDesdePpl() async {
    try {
      debugPrint("🔍 Buscando solicitud_usuario con seguimiento: $seguimiento");

      // 1️⃣ Buscar documento en solicitudes_usuario usando numeroSeguimiento
      final query = await FirebaseFirestore.instance
          .collection('solicitudes_usuario')
          .where('numeroSeguimiento', isEqualTo: seguimiento)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        debugPrint("⚠ No se encontró solicitud_usuario para seguimiento: $seguimiento");
        return null;
      }

      final idUser = query.docs.first.data()['idUser'];
      debugPrint("✅ idUser encontrado: $idUser");

      if (idUser == null) return null;

      // 2️⃣ Buscar celularWhatsapp en Ppl
      final pplSnapshot =
      await FirebaseFirestore.instance.collection('Ppl').doc(idUser).get();

      if (!pplSnapshot.exists) {
        debugPrint("⚠ No existe documento en Ppl para idUser $idUser");
        return null;
      }

      final numero = pplSnapshot.data()?['celularWhatsapp'];
      debugPrint("📱 Celular encontrado: $numero");

      return numero;
    } catch (e) {
      debugPrint("❌ Error obteniendo celular: $e");
      return null;
    }
  }

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
          String? numero = await _obtenerCelularDesdePpl();

          // Validar número
          if (numero == null || numero.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se encontró número de WhatsApp.')),
            );
            return;
          }

          // Formatear número
          if (!numero.startsWith('57')) {
            numero = numero.startsWith('0')
                ? '57${numero.substring(1)}'
                : '57$numero';
          }

          if (numero.length != 12) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Número de celular inválido.')),
            );
            return;
          }

          // Enviar mensaje
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
              builder: (_) => AlertDialog(
                backgroundColor: blanco,
                title: const Text('Mensaje enviado'),
                content: const Text('Se notificó por WhatsApp la respuesta.'),
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
