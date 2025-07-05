import 'dart:convert';
import 'package:http/http.dart' as http;

class WhatsappService {
  static Future<void> enviarNotificacion({
    required String numero,
    required String docId,
    required String servicio,
    required String seguimiento,
  }) async {
    final url = Uri.parse(
        'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendNewSolicitudMessage'
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
}
