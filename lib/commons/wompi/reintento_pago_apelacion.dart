import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../src/colors/colors.dart';
import 'checkout_page.dart';

class ReintentoPagoApelacionPage extends StatelessWidget {
  final String referencia;
  final int? valor;
  final VoidCallback? onTransaccionAprobada;

  const ReintentoPagoApelacionPage({
    super.key,
    required this.referencia,
    this.valor,
    this.onTransaccionAprobada,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blancoCards,
      appBar: AppBar(
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        title: const Text("Pago Rechazado", style: TextStyle(color: blanco)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          color: blanco,
          surfaceTintColor: blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 80, color: Colors.red),
                const SizedBox(height: 15),
                const Text(
                  "Transacción rechazada",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "No pudimos procesar tu pago de apelación. Puedes intentar nuevamente o salir.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      print("🔁 Intentando reintentar el pago...");

                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        print("⚠️ Usuario no autenticado");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tu sesión ha expirado. Inicia sesión nuevamente."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (valor == null) {
                        print("⚠️ Valor no definido");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("El valor del pago no está disponible."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final nuevaReferencia = 'apelacion_${user.uid}_${const Uuid().v4()}';
                      print("📌 Nueva referencia generada: $nuevaReferencia");

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(
                            tipoPago: 'apelacion',
                            valor: valor!,
                            referencia: nuevaReferencia,
                            onTransaccionAprobada: onTransaccionAprobada,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Reintentar", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
