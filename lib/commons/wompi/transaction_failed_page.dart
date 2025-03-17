import 'package:flutter/material.dart';

import '../../src/colors/colors.dart';

class TransactionFailedPage extends StatelessWidget {
  const TransactionFailedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blancoCards,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        title: const Text("Pago Rechazado", style: TextStyle(color: blanco)),
        actions: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 15),
            child: const Image(
                height: 60.0,
                width: 60.0,
                image: AssetImage('assets/images/logo_tu_proceso_ya_transparente.png')),
          )
        ],
        backgroundColor: Colors.red,
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
                    textAlign: TextAlign.center
                ),
                const SizedBox(height: 10),
                const Text(
                  "No pudimos procesar tu pago. Puedes intentarlo nuevamente o salir.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Botón para reintentar pago
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'checkout_wompi'); // Ahora permite volver atrás
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Reintentar",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, 'home', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancelar",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
