import 'package:flutter/material.dart';
import 'package:tuprocesoya/Pages/client/home/home.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import '../../../commons/main_layaout.dart';
import '../historial_solicitudes_desistimiento_apelacion/historial_solicitudes_desistimiento_apelacion.dart';
// import '../historial_solicitudes_desistimiento/historial_solicitudes_desistimiento.dart';
// Si ya tienes una página de historial para desistimientos, importa aquí.

class SolicitudExitosaDesistimientoPage extends StatelessWidget {
  final String numeroSeguimiento;

  const SolicitudExitosaDesistimientoPage({super.key, required this.numeroSeguimiento});

  @override
  Widget build(BuildContext context) {
    // ancho máximo para pantallas grandes (igual que el otro componente)
    final double maxWidth = MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity;

    return MainLayout(
      pageTitle: "¡Listo!",
      content: SizedBox(
        width: maxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Puedes mantener el logo que usas en la app
            Image.asset(
              'assets/images/logo_tu_proceso_ya_transparente.png',
              height: 30,
            ),
            const SizedBox(height: 30),

            // Título principal
            const Text(
              "Tu solicitud de Desistimiento de Apelación ha sido recibida",
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

            // Número de seguimiento dinámico
            Text(
              numeroSeguimiento,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            const Text(
              "Verificaremos la información enviada y remitiremos el escrito de desistimiento a las autoridades competentes.",
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

            // Punto 1
            RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(fontSize: 14, height: 1.1, color: Colors.black),
                children: [
                  TextSpan(
                    text:
                    "1. El desistimiento será preparado y enviado por nuestro equipo a los canales oficiales correspondientes. La efectiva aceptación del desistimiento depende de la gestión y de la resolución que emita la autoridad competente.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Punto 2
            RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(fontSize: 14, height: 1.1, color: Colors.black),
                children: [
                  TextSpan(
                    text:
                    "2. Estaremos informado sobre cualquier notificación, respuesta o actuación que surja a partir del envío.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Botones centrales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón: Ver historial (ajusta la navegación según tu app)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("Ir al inicio", style: TextStyle(color: blanco)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistorialSolicitudesDesistimientoPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text("Ver historial", style: TextStyle(color: primary)),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
