import 'dart:convert';
import 'package:crypto/crypto.dart';

class WompiService {
  final String publicKey = "pub_test_0JGU7oYmF0GZ0JX1uSD5nlZul1Ux43A5"; // Usa tu llave pública de Wompi
  final String integritySecret = "test_integrity_ChT6KEX5S6V9lq6W7XeN2CLn8Y9VDKV7"; // Secreto de integridad

  /// Genera la firma de integridad (SHA-256)
  String _generarFirma(String referencia, int monto, String moneda) {
    String cadena = "$referencia$monto$moneda$integritySecret";
    return sha256.convert(utf8.encode(cadena)).toString();
  }

  /// Genera la URL de Web Checkout de Wompi
  Future<String?> generarUrlCheckout({
    required int monto,
    required String referencia,
  }) async {
    String moneda = "COP";
    String firma = _generarFirma(referencia, monto, moneda);

    String url = Uri.https("checkout.wompi.co", "/p/", {
      "public-key": publicKey,
      "currency": moneda,
      "amount-in-cents": monto.toString(),
      "reference": referencia,
      "signature:integrity": firma,
    }).toString();

    return url;
  }
}
