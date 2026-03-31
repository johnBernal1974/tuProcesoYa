import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseConfigLoader {
  static const String _prodUrl =
      "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getFirestoreConfig";

  static const String _pilotoUrl =
      "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getFirestoreConfigPiloto";

  static Future<Map<String, dynamic>> load() async {
    const env = String.fromEnvironment('ENV', defaultValue: 'prod');

    const url = env == 'piloto' ? _pilotoUrl : _prodUrl;

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error cargando Firebase config ($env)");
    }
  }
}
