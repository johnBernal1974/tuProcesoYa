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
            constraints: const BoxConstraints(maxWidth: 600),
            padding: EdgeInsets.symmetric(horizontal: screenWidth < 600 ? 6.0 : 10.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona el historial de solicitudes de servicios que has realizado:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildCard(context, Icons.description, 'Derechos de\npetición', 'historial_solicitudes_derechos_peticion', blanco),
                    _buildCard(context, Icons.gavel, 'Acciones de\ntutela', 'historial_solicitudes_tutela', blanco),
                    _buildCard(context, Icons.schedule, 'Permiso de\n72 horas', 'historial_solicitudes_permiso_72horas', blanco),
                    _buildCard(context, Icons.home, 'Prisión\ndomiciliaria', 'historial_solicitudes_prision_domiciliaria', blanco),
                    _buildCard(context, Icons.lock_open, 'Libertad\ncondicional', 'historial_solicitudes_libertad_condicional', blanco),
                    _buildCard(context, Icons.assignment_turned_in, 'Extinción de\nla pena', 'historial_solicitudes_extincion_pena', blanco),
                    _buildCard(context, Icons.swap_horiz, 'Traslado de\nproceso', 'historial_solicitudes_traslado_proceso', blanco),
                    _buildCard(context, Icons.calculate_outlined, 'Solicitud\nredenciones', 'historial_solicitudes_redenciones', blanco),
                  ],
                ),
                const SizedBox(height: 24),
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

    final double iconSize = isMobile ? 24.0 : 32.0;
    final double fontSize = isMobile ? 12.0 : 16.0;
    final double padding = isMobile ? 12.0 : 18.0;
    final double margin = isMobile ? 6.0 : 12.0;

    return GestureDetector(
      onTap: () => navegar(context, ruta),
      child: Container(
        padding: EdgeInsets.all(padding),
        margin: EdgeInsets.all(margin),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: primary),
              const SizedBox(height: 10),
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

