// lib/services/whatsapp_otp_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class WhatsAppOtpService {
  // REEMPLAZA por la URL de tus Cloud Functions (sin path final)
  // ej: https://us-central1-tu-proyecto.cloudfunctions.net
  static const String baseUrl = 'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envía el OTP al teléfono (phone en formato E.164 sin +, ej: 573001234567)
  Future<bool> sendOtp(String phone) async {
    final url = Uri.parse('$baseUrl/sendOtpWhatsApp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // puedes _log_gar aquí para debug
        return false;
      }
    } catch (e) {
      print('sendOtp error: $e');
      return false;
    }
  }

  /// Verifica el OTP. Si OK, el endpoint devuelve un customToken y este método hace signInWithCustomToken.
  /// Retorna el User si el login fue exitoso, o null si falla.
  Future<User?> verifyOtpAndSignIn(String phone, String code) async {
    final url = Uri.parse('$baseUrl/verifyOtpWhatsApp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'code': code}),
      );

      if (response.statusCode != 200) {
        print('verifyOtp failed: ${response.body}');
        return null;
      }

      final body = jsonDecode(response.body);
      final customToken = body['customToken'] as String?;
      if (customToken == null) {
        print('No customToken in response');
        return null;
      }

      final userCredential = await _auth.signInWithCustomToken(customToken);
      return userCredential.user;
    } catch (e) {
      print('verifyOtpAndSignIn error: $e');
      return null;
    }
  }
}
