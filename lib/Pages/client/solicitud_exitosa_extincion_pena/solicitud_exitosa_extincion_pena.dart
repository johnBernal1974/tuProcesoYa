
import 'package:flutter/material.dart';
import 'package:tuprocesoya/Pages/client/home/home.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import '../../../commons/main_layaout.dart';
import '../historial_solicitudes_extincion_pena/historial_solicitudes_extincion_pena.dart';
import '../historial_solicitudes_libertad_condicional/historial_solicitudes_libertad_condicional.dart';

class SolicitudExitosaExtincionPenaPage extends StatelessWidget {
  final String numeroSeguimiento;

  const SolicitudExitosaExtincionPenaPage({super.key, required this.numeroSeguimiento});

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
              "Tu solicitud de Extinción de la pena ha sido recibida",
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
              "Verificaremos la información enviada para proceder con la radicación de la solicitud de extinción de la pena ante la autoridad competente. ",
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
                    "1. Nuestro equipo realiza todos los trámites para respaldar tu solicitud. La decisión final la toma un juez, quien actúa de manera ",
                  ),
                  TextSpan(
                    text: "autónoma e independiente.",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                    "2. Una vez radicada la solicitud, la respuesta depende exclusivamente del juzgado y sus tiempos pueden extenderse por carga laboral, trámites internos o solicitudes de información adicional. ",
                  ),
                  TextSpan(
                    text: "No es posible garantizar una fecha exacta de respuesta.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                    " Realizaremos seguimiento y te notificaremos cualquier avance relevante en tu proceso.",
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
                    MaterialPageRoute(builder: (context) => const HistorialSolicitudesExtincionPenaPage()),
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
