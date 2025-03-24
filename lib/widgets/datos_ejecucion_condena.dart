import 'package:flutter/material.dart';

class DatosEjecucionCondena extends StatelessWidget {
  final int mesesEjecutado;
  final int diasEjecutadoExactos;
  final int mesesRestante;
  final int diasRestanteExactos;
  final double totalDiasRedimidos;
  final double porcentajeEjecutado;
  final Color primary;
  final Color negroLetras;

  const DatosEjecucionCondena({
    Key? key,
    required this.mesesEjecutado,
    required this.diasEjecutadoExactos,
    required this.mesesRestante,
    required this.diasRestanteExactos,
    required this.totalDiasRedimidos,
    required this.porcentajeEjecutado,
    required this.primary,
    required this.negroLetras,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // 🔷 Tarjeta para "Condena transcurrida"
    Widget buildBox(String title, String value) {
      return Container(
        width: 150,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: primary, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth > 600 ? 14 : 12,
                color: negroLetras,
                height: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: screenWidth > 600 ? 14 : 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    String condenaTranscurrida = mesesEjecutado == 1
        ? diasEjecutadoExactos == 1
        ? '$mesesEjecutado mes : $diasEjecutadoExactos día'
        : '$mesesEjecutado mes : $diasEjecutadoExactos días'
        : diasEjecutadoExactos == 1
        ? '$mesesEjecutado meses : $diasEjecutadoExactos día'
        : '$mesesEjecutado meses : $diasEjecutadoExactos días';

    String tiempoRedencion = '${totalDiasRedimidos % 1 == 0 ? totalDiasRedimidos.toStringAsFixed(0) : totalDiasRedimidos.toStringAsFixed(1)} días';

    int totalDiasCumplidos = (mesesEjecutado * 30 + diasEjecutadoExactos + totalDiasRedimidos).toInt();
    int totalMesesCumplidos = totalDiasCumplidos ~/ 30;
    int diasCumplidosExactos = totalDiasCumplidos % 30;
    String condenaTotalCumplida = totalMesesCumplidos == 1
        ? diasCumplidosExactos == 1
        ? '$totalMesesCumplidos mes : $diasCumplidosExactos día'
        : '$totalMesesCumplidos mes : $diasCumplidosExactos días'
        : diasCumplidosExactos == 1
        ? '$totalMesesCumplidos meses : $diasCumplidosExactos día'
        : '$totalMesesCumplidos meses : $diasCumplidosExactos días';

    String condenaRestante = mesesRestante == 1
        ? diasRestanteExactos == 1
        ? '$mesesRestante mes : $diasRestanteExactos día'
        : '$mesesRestante mes : $diasRestanteExactos días'
        : mesesRestante > 0
        ? diasRestanteExactos == 1
        ? '$mesesRestante meses : $diasRestanteExactos día'
        : '$mesesRestante meses : $diasRestanteExactos días'
        : diasRestanteExactos == 1
        ? '$diasRestanteExactos día'
        : '$diasRestanteExactos días';

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        buildBox('Condena\ntranscurrida', condenaTranscurrida),
        buildBox('Tiempo\nredimido', tiempoRedencion),
        buildBox('Condena total\ncumplida', condenaTotalCumplida),
        buildBox('Condena\nrestante', condenaRestante),
        buildBox('Porcentaje\nejecutado', '${porcentajeEjecutado.toStringAsFixed(1)}%'),
      ],
    );
  }
}
