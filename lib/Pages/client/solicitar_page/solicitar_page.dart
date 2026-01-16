import 'package:flutter/material.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';
import '../../../widgets/info_tiempos_judiciales.dart';

class SolicitarServiciosPage extends StatelessWidget {
  SolicitarServiciosPage({super.key});

  void navegar(BuildContext context, String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  // Lista de servicios disponibles
  final List<Map<String, dynamic>> _serviciosConfig = [
    {
      "title": "Solicitud Readecuación Redencion, según art. 19 de la ley 2466 de 2025.",
      "icon": Icons.calculate_rounded, // Puedes cambiar el ícono si prefieres otro
      "route": "solicitud_readecuacion_redenciones_page",
    },
    {
      "title": "Derecho de petición",
      "icon": Icons.description,
      "route": "derecho_peticion",
    },
    {
      "title": "Acción de tutela",
      "icon": Icons.gavel,
      "route": "tutela",
    },
    {
      "title": "Traslado de proceso",
      "icon": Icons.swap_horiz,
      "route": "solicitud_traslado_proceso_page",
    },
    {
      "title": "Solicitud de redenciones",
      "icon": Icons.calculate_outlined,
      "route": "solicitud_redenciones_page",
    },
    {
      "title": "Solicitud de acumulación",
      "icon": Icons.join_left_sharp,
      "route": "solicitud_acumulacion_page",
    },
    {
      "title": "Solicitud de apelación",
      "icon": Icons.rate_review,
      "route": "solicitud_apelacion_page",
    },
    {
      "title": "Solicitud de desistimiento de apelación",
      "icon": Icons.cancel,
      "route": "solicitud_desistimiento_apelacion_page",
    },
    {
      "title": "Solicitud traslado penitenciaría",
      "icon": Icons.door_back_door_outlined,
      "route": "solicitud_trasladoPenitenciaria_page",
    },
    {
      "title": "Solicitud copia de sentencia",
      "icon": Icons.copy,
      "route": "solicitud_copia_sentencia_page",
    },
    {
      "title": "Solicitud asignación de Juzgado de ejecución de penas",
      "icon": Icons.assistant_direction_sharp,
      "route": "solicitud_asignacion_jep_page",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return MainLayout(
      pageTitle: 'Solicitar servicio',
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InfoTiemposJudiciales(),
                const SizedBox(height: 24),
                const Text(
                  'Selecciona el servicio que deseas solicitar:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _serviciosConfig.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final servicio = _serviciosConfig[index];
                    return _buildServicioCard(
                      context,
                      servicio["icon"],
                      servicio["title"],
                      servicio["route"],
                      esDestacada: index == 0,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicioCard(BuildContext context, IconData icon, String titulo, String ruta, {bool esDestacada = false}) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(12, esDestacada ? 26 : 14, 12, 14),
          decoration: BoxDecoration(
            color: esDestacada ? Colors.green.shade100 : blanco,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.black54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, color: primary),
                onPressed: () => navegar(context, ruta),
                tooltip: "Solicitar",
              ),
            ],
          ),
        ),
        if (esDestacada)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: const Text(
                '¡Reforma laboral!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
