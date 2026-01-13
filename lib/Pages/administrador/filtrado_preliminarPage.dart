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
}
