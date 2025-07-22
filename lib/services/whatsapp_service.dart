import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsappService {
  /// 🟢 Notificación de solicitud nueva (ya lo tenías)
  static Future<void> enviarNotificacion({
    required String numero,
    required String docId,
    required String servicio,
    required String seguimiento,
  }) async {
    final url = Uri.parse(
      'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendNewSolicitudMessage',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "to": numero,
        "docId": docId,
        "servicio": servicio,
        "seguimiento": seguimiento,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al enviar WhatsApp: ${response.body}');
    }
  }

  /// 🟡 Notificación de que hay una respuesta
  static Future<void> enviarNotificacionRespuesta({
    required String numero,
    required String docId,
    required String servicio,
    required String seguimiento,
    required String seccionHistorial,
  }) async {
    final url = Uri.parse(
      'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendRespuestaSolicitudMessage',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "to": numero,
        "docId": docId,
        "tipoSolicitud": servicio,
        "numeroSeguimiento": seguimiento,
        "seccionHistorial": seccionHistorial,
      }),
    );

    print("Código de respuesta: ${response.statusCode}");
    print("Respuesta del servidor: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Error al enviar WhatsApp de respuesta: ${response.body}');
    }

  }
}
