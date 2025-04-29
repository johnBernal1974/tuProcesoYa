import 'package:flutter/material.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesPage extends StatelessWidget {
  const HistorialSolicitudesPage({super.key});

  void navegar(BuildContext context, String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1000
        ? 3
        : screenWidth >= 600
        ? 3
        : 2;

    return MainLayout(
      pageTitle: 'Historial de solicitudes',
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(6.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600), // Limita el ancho máximo
            padding: const EdgeInsets.all(10.0), // Agrega espacio alrededor del contenido
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el historial de solicitudes de servicios que has realizado:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildCard(context, Icons.description, 'Derechos de\npetición', 'historial_solicitudes_derechos_peticion', blanco),
                    _buildCard(context, Icons.gavel, 'Acciones de\ntutela', 'historial_solicitudes_tutela', blanco),
                    _buildCard(context, Icons.schedule, 'Permiso de\n72 horas', 'historial_solicitudes_permiso_72horas', blanco),
                    _buildCard(context, Icons.home, 'Prisión\ndomiciliaria', 'historial_solicitudes_prision_domiciliaria', blanco),
                    _buildCard(context, Icons.lock_open, 'Libertad\ncondicional', 'historial_solicitudes_libertad_condicional', blanco),
                    _buildCard(context, Icons.assignment_turned_in, 'Extinción de\nla pena', 'historial_solicitudes_extincion_pena', blanco),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String titulo, String ruta, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final double iconSize = isMobile ? 26.0 : 32.0;
    final double fontSize = isMobile ? 13.0 : 16.0;

    return GestureDetector(
      onTap: () => navegar(context, ruta),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: primary),
              const SizedBox(height: 12),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
