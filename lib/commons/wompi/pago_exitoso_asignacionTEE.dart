
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../src/colors/colors.dart';

class PagoExitosoAsignacionTeePage extends StatefulWidget {
  final Future<void> Function() onContinuar;
  final double montoPagado;
  final String transaccionId;
  final DateTime fecha;

  const PagoExitosoAsignacionTeePage({
    super.key,
    required this.onContinuar,
    required this.montoPagado,
    required this.transaccionId,
    required this.fecha,
  });

  @override
  State<PagoExitosoAsignacionTeePage> createState() =>
      _PagoExitosoAsignacionTeePageState();
}

class _PagoExitosoAsignacionTeePageState
    extends State<PagoExitosoAsignacionTeePage> {
  bool isLoading = false;

  Future<void> _handleContinuar() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
        content: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.white),
            SizedBox(width: 8),
            Text("Espera un momento..."),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    try {
      await widget.onContinuar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No fue posible completar el registro. Intenta nuevamente.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
      locale: 'es_CO',
      name: '',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primary,
        title: const Text(
          "Pago exitoso",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "¡Pago de solicitud de Asignación TEE "
                    "(Trabajo, Estudio y Enseñanza) "
                    "realizado con éxito!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Monto: \$${formatter.format(widget.montoPagado)}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format(widget.fecha)}",
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _handleContinuar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                ),
                child: const Text(
                  "Continuar",
                  style: TextStyle(color: blanco),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "¡Por favor no salgas de esta página "
                    "sin antes dar clic en el botón CONTINUAR!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
