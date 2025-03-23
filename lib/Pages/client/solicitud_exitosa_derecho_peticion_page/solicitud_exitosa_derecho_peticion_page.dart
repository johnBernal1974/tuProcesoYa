import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../../commons/main_layaout.dart';
import '../historial_solicitudes_derecho_peticion/historial_solicitudes_derecho_peticion.dart';

class SolicitudExitosaDerechoPeticionPage extends StatelessWidget {
  final String numeroSeguimiento;

  const SolicitudExitosaDerechoPeticionPage({super.key, required this.numeroSeguimiento});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "¡Genial!",
      content: SizedBox(
          // Si el ancho de la pantalla es mayor o igual a 800, usa 800, de lo contrario ocupa todo el ancho disponible
          width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo_tu_proceso_ya_transparente.png',
                  height: 30,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Tu solicitud de derecho de petición ha sido recibida",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                const Text(
                  "Numero de seguimiento",
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
                // Mensaje principal
                const Text(
                  "Estaremos realizando las verificaciones necesarias de la información y los documentos que subiste. "
                      "El documento se radicará a la autoridad correspondiente en las próximas 72 horas.",
                  style: TextStyle(fontSize: 14, height: 1.1),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),

                // Información importante
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
                        text: "1. Nuestro equipo llevará a cabo todas las gestiones necesarias de la mejor manera posible para respaldar tu "
                            "solicitud. Sin embargo, es importante recordar que la decisión final queda a criterio del juez, quien actúa de manera ",
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
                        text: "2. Una vez radicado el derecho de petición por nuestra plataforma, recuerda que hay "
                            "un tiempo estipulado de respuesta de ",
                      ),
                      TextSpan(
                        text: "15 días hábiles.",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: " Te estaremos informando el resultado de la diligencia.",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),

                // Botón para volver a Home
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HistorialSolicitudesDerechosPeticionPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text("Ver el historial", style: TextStyle(
                      color: blanco
                    ),),
                  ),
                ),
              ],
            ),
        ),
       );
  }
}
