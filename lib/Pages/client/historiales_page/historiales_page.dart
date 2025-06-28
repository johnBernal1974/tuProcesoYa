import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesPage extends StatelessWidget {
  HistorialSolicitudesPage({super.key});

  void navegar(BuildContext context, String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  // Lista de colecciones y rutas
  final List<Map<String, dynamic>> _solicitudesConfig = [
    {
      "collection": "derechos_peticion_solicitados",
      "title": "Derechos de\npetición",
      "icon": Icons.description,
      "route": "historial_solicitudes_derechos_peticion",
    },
    {
      "collection": "tutelas_solicitados",
      "title": "Acciones de\ntutela",
      "icon": Icons.gavel,
      "route": "historial_solicitudes_tutela",
    },
    {
      "collection": "permiso_solicitados",
      "title": "Permiso de\n72 horas",
      "icon": Icons.schedule,
      "route": "historial_solicitudes_permiso_72horas",
    },
    {
      "collection": "domiciliaria_solicitados",
      "title": "Prisión\ndomiciliaria",
      "icon": Icons.home,
      "route": "historial_solicitudes_prision_domiciliaria",
    },
    {
      "collection": "condicional_solicitados",
      "title": "Libertad\ncondicional",
      "icon": Icons.lock_open,
      "route": "historial_solicitudes_libertad_condicional",
    },
    {
      "collection": "extincion_pena_solicitados",
      "title": "Extinción de\nla pena",
      "icon": Icons.assignment_turned_in,
      "route": "historial_solicitudes_extincion_pena",
    },
    {
      "collection": "trasladoProceso_solicitados",
      "title": "Traslado de\nproceso",
      "icon": Icons.swap_horiz,
      "route": "historial_solicitudes_traslado_proceso",
    },
    {
      "collection": "redenciones_solicitados",
      "title": "Solicitud\nredenciones",
      "icon": Icons.calculate_outlined,
      "route": "historial_solicitudes_redenciones",
    },
    {
      "collection": "acumulacion_solicitados",
      "title": "Solicitud\nAcumulación",
      "icon": Icons.join_left_sharp,
      "route": "historial_solicitudes_acumulacion",
    },
  ];

  Future<List<Map<String, dynamic>>> _obtenerSolicitudes(String userId) async {
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> resultado = [];

    for (var config in _solicitudesConfig) {
      final snapshot = await firestore
          .collection(config["collection"])
          .where('idUser', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        resultado.add(config);
      }
    }

    return resultado;
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
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait(
          _solicitudesConfig.map((config) async {
            final querySnapshot = await FirebaseFirestore.instance
                .collection(config['collection'])
                .where('idUser', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .limit(1)
                .get();

            print('Consulta a colección ${config['collection']}: ${querySnapshot.docs.length} documentos encontrados');

            return {
              "config": config,
              "hasData": querySnapshot.docs.isNotEmpty,
            };
          }),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final results = snapshot.data!;
          final filteredConfigs = results.where((r) => r['hasData'] == true).toList();

          print('Total de colecciones con datos: ${filteredConfigs.length}');

          if (filteredConfigs.isEmpty) {
            return const Center(
              child: Text("No tienes solicitudes registradas."),
            );
          }

          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: filteredConfigs.map((result) {
              final config = result['config'] as Map<String, dynamic>;
              return _buildCard(
                context,
                config['icon'],
                config['title'],
                config['route'],
                blanco,
              );
            }).toList(),
          );
        },
      ),

    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String titulo, String ruta, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final double iconSize = isMobile ? 34.0 : 34.0;
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
              Icon(icon, size: iconSize, color: Colors.black54),
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
