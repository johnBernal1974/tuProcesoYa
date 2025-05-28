import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import '../../../commons/main_layaout.dart';
import '../historial_solicitudes_acumulacion/historial_solicitudes_acumulacion.dart';

class SolicitudExitosaAcumulacionPage extends StatelessWidget {
  final String numeroSeguimiento;

  const SolicitudExitosaAcumulacionPage({super.key, required this.numeroSeguimiento});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "¡Genial!",
      content: SizedBox(
        width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo_tu_proceso_ya_transparente.png',
              height: 30,
            ),
            const SizedBox(height: 30),
            const Text(
              "Tu solicitud de Acumulación de Penas ha sido recibida",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text(
              "Número de seguimiento",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              numeroSeguimiento,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const Text(
              "Verificaremos la información enviada para radicar la solicitud de acumulación de penas ante la autoridad correspondiente.",
              style: TextStyle(fontSize: 14, height: 1.1),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.info, color: primary),
                SizedBox(width: 8),
                Text(
                  "Información importante",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(fontSize: 14, height: 1.1, color: Colors.black),
                children: [
                  TextSpan(
                    text:
                    "1. Esta solicitud será revisada por nuestro equipo. La acumulación de penas solo será efectiva cuando sea aceptada por la autoridad competente.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(fontSize: 14, height: 1.1, color: Colors.black),
                children: [
                  TextSpan(
                    text:
                    "2. Te mantendremos informado sobre el estado y resultado de tu solicitud.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HistorialSolicitudesAcumulacionPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text("Ver el historial", style: TextStyle(color: blanco)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
