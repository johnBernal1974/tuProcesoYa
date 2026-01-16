import 'package:flutter/material.dart';

class InfoTiemposJudiciales extends StatelessWidget {
  const InfoTiemposJudiciales({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              textAlign: TextAlign.justify,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.3,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text:
                    "Importante: ",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextSpan(
                    text:
                    "los tiempos de respuesta de las solicitudes judiciales dependen exclusivamente del juzgado competente. "
                        "Estos pueden variar según la carga laboral del despacho, el reparto, la complejidad del caso "
                        "y la necesidad de requerir información adicional. ",
                  ),

                  TextSpan(
                    text:
                    "Para Tu Proceso YA, no es posible garantizar una fecha exacta de respuesta.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                    " Nuestro equipo realizará seguimiento permanente y te notificará cualquier avance relevante en tu proceso.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
