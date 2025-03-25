import 'dart:convert';
import 'package:http/http.dart' as http;

class WompiService {
  static const _endpoint = "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/wompiCheckoutUrl";

  /// Solicita la URL de Web Checkout desde Firebase Functions
  static Future<String?> obtenerCheckoutUrl({
    required String referencia,
    required int monto,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"referencia": referencia, "monto": monto}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        print("❌ Error ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Excepción al obtener URL de Wompi: $e");
      return null;
    }
  }
}


