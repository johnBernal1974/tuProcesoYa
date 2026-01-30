import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import '../../../widgets/beneficios_obtenidos_por_plataforma.dart';

class PplBeneficiosPlataformaPage extends StatelessWidget {
  const PplBeneficiosPlataformaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      pageTitle: 'Beneficios adquiridos por la plataforma',
      content: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PplConBeneficiosPlataformaWidget(),
      ),
    );
  }
}
