// lib/commons/ia_backend_service/ia_backend_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class IABackendService {
  static const String baseUrl = 'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/generarTextoIAExtendido';

  static Future<Map<String, String>> generarTextoExtendidoDesdeCloudFunction({
    required String categoria,
    required String subcategoria,
    List<String> respuestasUsuario = const [],
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'categoria': categoria,
        'subcategoria': subcategoria,
        'respuestasUsuario': respuestasUsuario,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'consideraciones': data['consideraciones'] ?? '',
        'fundamentos': data['fundamentos'] ?? '',
        'peticion': data['peticion'] ?? '',
      };
    } else {
      throw Exception('Error al generar texto IA extendido: \${response.body}');
    }
  }

  static Future<Map<String, String>> generarTextoTutelaExtendido({
    required String categoria,
    required String subcategoria,
    List<String> respuestasUsuario = const [],
  }) async {
    final response = await http.post(
      Uri.parse('https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/generarTextoIAExtendido'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'categoria': categoria,
        'subcategoria': subcategoria,
        'tipo': 'tutela', // 🔹 Nuevo parámetro que activa el modo "hechos" para tutela
        'respuestasUsuario': respuestasUsuario,
      }),

    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'hechos': data['hechos'] ?? '',
      };
    } else {
      throw Exception('Error al generar hechos de tutela: ${response.body}');
    }
  }

}
