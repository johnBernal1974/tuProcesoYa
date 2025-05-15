import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../src/colors/colors.dart';


class PagoExitosoSuscripcionPage extends StatelessWidget {
  final double montoPagado;
  final String transaccionId;
  final DateTime fecha;
  final Future<void> Function()? onContinuar; // ✅ Agregado

  const PagoExitosoSuscripcionPage({
    super.key,
    required this.montoPagado,
    required this.transaccionId,
    required this.fecha,
    this.onContinuar, // ✅ Agregado
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
      locale: 'es_CO',
      name: '',
      decimalDigits: 0,
    );
    return WillPopScope(
      onWillPop: () async => false, // ❌ Bloquea botón físico
      child: Scaffold(
        backgroundColor: blanco,
        appBar: AppBar(
          automaticallyImplyLeading: false, // ❌ Quita flecha de retroceso
          backgroundColor: primary,
          title: const Text("Pago exitoso", style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "¡Suscribción realizada con éxito!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  "Monto: \$${formatter.format(montoPagado)}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format(fecha)}",
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    if (onContinuar != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.hourglass_bottom, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Procesando..."),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      await onContinuar!();
                    } else {
                      Navigator.pushNamedAndRemoveUntil(context, 'home', (r) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                  child: const Text("Continuar", style: TextStyle(color: blanco)),
                ),
                const SizedBox(height: 30),
                const Text(
                  "¡Por favor no salgas de esta página sin antes dar click en el botón CONTINUAR!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
