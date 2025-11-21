import 'package:flutter/material.dart';

class BeneficiosPenitenciariosWidget extends StatelessWidget {
  /// % ejecutado (0-100). Idealmente ya incluye redenciones.
  final double porcentajeEjecutado;

  /// Total de condena en días reales (meses*30 + dias).
  final int totalDiasCondena;

  /// Situación jurídica del PPL para mostrar/ocultar beneficios.
  final String situacion;

  /// Colores opcionales para borde/fondo
  final Color? cardColor;
  final Color? borderColor;

  const BeneficiosPenitenciariosWidget({
    super.key,
    required this.porcentajeEjecutado,
    required this.totalDiasCondena,
    required this.situacion,
    this.cardColor,
    this.borderColor,
  });

  int _calcularDias(double metaPorcentaje) {
    final diferencia = porcentajeEjecutado - metaPorcentaje;
    return (diferencia.abs() / 100 * totalDiasCondena).ceil(); // 👈 antes round()
  }

  Widget _buildBenefitMinimalSection({
    required String titulo,
    required bool condition,
    required int remainingTime,
  }) {
    return Card(
      color: cardColor ?? Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: condition ? Colors.green.shade700 : Colors.red.shade700,
          width: 2.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              condition ? "Hace $remainingTime días" : "Faltan $remainingTime días",
              style: TextStyle(
                color: condition ? Colors.green.shade700 : Colors.red.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esPantallaAncha = constraints.maxWidth > 700;

        final bool enReclusion = situacion == "En Reclusión";
        final bool enDomiciliaria = situacion == "En Prisión domiciliaria";

        final widget72h = _buildBenefitMinimalSection(
          titulo: "72 Horas",
          condition: porcentajeEjecutado >= 33.33,
          remainingTime: _calcularDias(33),
        );

        final widgetDomiciliaria = _buildBenefitMinimalSection(
          titulo: "Domiciliaria",
          condition: porcentajeEjecutado >= 50,
          remainingTime: _calcularDias(50),
        );

        final widgetCondicional = _buildBenefitMinimalSection(
          titulo: "Condicional",
          condition: porcentajeEjecutado >= 60,
          remainingTime: _calcularDias(60),
        );

        final widgetExtincion = _buildBenefitMinimalSection(
          titulo: "Extinción",
          condition: porcentajeEjecutado >= 100,
          remainingTime: _calcularDias(100),
        );

        // ✅ PC: todo en fila
        if (esPantallaAncha) {
          return Card(
            color: cardColor ?? Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor ?? Colors.grey.shade300),
            ),
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  if (enReclusion) ...[
                    widget72h,
                    const SizedBox(width: 16),
                    widgetDomiciliaria,
                    const SizedBox(width: 16),
                  ],
                  widgetCondicional,
                  const SizedBox(width: 16),
                  widgetExtincion,
                ],
              ),
            ),
          );
        }

        // ✅ Móvil: 2 columnas
        return Card(
          color: cardColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor ?? Colors.grey.shade300),
          ),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      if (enReclusion) widget72h,
                      widgetCondicional,
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      if (enReclusion || enDomiciliaria)
                        if (enReclusion) widgetDomiciliaria,
                      widgetExtincion,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
