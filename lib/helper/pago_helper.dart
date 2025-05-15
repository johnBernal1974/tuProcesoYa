// lib/helpers/pago_helper.dart
import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/wompi/wompi_service.dart';

class PagoHelper {
  /// Muestra un dialogo de carga mientras se obtiene el URL del checkout de Wompi
  static Future<void> iniciarFlujoPago({
    required BuildContext context,
    required int centavos,
    required String referencia,
    required Widget Function(String url) buildCheckoutWidget,
    VoidCallback? onTransaccionAprobada, // 👈 nuevo parámetro opcional
  }) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text("Espera un momento...", style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );

    // Obtener URL de checkout
    final url = await WompiService.obtenerCheckoutUrl(
      monto: centavos,
      referencia: referencia,
    );

    // Cerrar diálogo si sigue montado
    if (context.mounted) Navigator.of(context).pop();

    // Navegar al WebView si se obtuvo URL
    if (url != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => buildCheckoutWidget(url)), // 👈 asegúrate que el builder lo reciba también
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo iniciar el pago."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

}
