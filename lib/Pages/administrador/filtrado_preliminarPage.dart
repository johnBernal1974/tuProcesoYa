import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../widgets/analisis_preliminar/busqueda_preliminar.dart';

class CalculoCondenaPage extends StatefulWidget {
  const CalculoCondenaPage({super.key});

  @override
  State<CalculoCondenaPage> createState() => _CalculoCondenaPageState();
}

class _CalculoCondenaPageState extends State<CalculoCondenaPage> {
  String? _resumenFinal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Cálculo de condena y beneficios'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 12),
                  _botonVerInforme(context),
                  const SizedBox(height: 60),

                  Text(
                    'Análisis individual de PPL',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa este módulo para calcular la condena, verificar los porcentajes cumplidos, '
                        'identificar beneficios penitenciarios y registrar los datos básicos del PPL.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // --------- AQUÍ USAMOS EL WIDGET ----------
                  const CalculoCondenaWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonVerInforme(BuildContext context) {
    return SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.list_alt_sharp, color: Colors.white),
        label: const Text(
          'Ver informe',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, // usa tu color primary
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          Navigator.pushNamed(context, 'reporte_beneficios_page_admin');
        },
      ),
    );
  }
}
