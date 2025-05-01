import 'package:flutter/material.dart';
import '../../commons/ia_backend_service/ia_backend_service.dart';

class IASuggestionCardTutela extends StatefulWidget {
  final String categoria;
  final String subcategoria;
  final List<String>? respuestasUsuario; // Ahora puede ser null
  final TextEditingController hechosController;
  final TextEditingController derechosVulneradosController;
  final TextEditingController pretensionesController;
  final TextEditingController normasAplicablesController;
  final TextEditingController pruebasController;
  final TextEditingController juramentoController;

  const IASuggestionCardTutela({
    super.key,
    required this.categoria,
    required this.subcategoria,
    this.respuestasUsuario, // Puede omitirse si no hay respuestas
    required this.hechosController,
    required this.derechosVulneradosController,
    required this.pretensionesController,
    required this.normasAplicablesController,
    required this.pruebasController,
    required this.juramentoController,
  });

  @override
  State<IASuggestionCardTutela> createState() => _IASuggestionCardState();
}

class _IASuggestionCardState extends State<IASuggestionCardTutela> {
  bool cargando = false;
  String? hechos;
  String? derechosVulnerados;
  String? pretensiones;
  String? normasAplicables;
  String? pruebas;
  String? juramento;
  bool mostrarSugerencias = false;

  Future<void> _generarTextoExtendido() async {
    setState(() {
      cargando = true;
      mostrarSugerencias = false;
    });

    try {
      final resultado = await IABackendService.generarTextoTutelaExtendido(
        categoria: widget.categoria,
        subcategoria: widget.subcategoria,
        respuestasUsuario: widget.respuestasUsuario ?? [],
      );

      setState(() {
        hechos = resultado['hechos'];
        derechosVulnerados = resultado['derechos_vulnerados'];
        pretensiones = resultado['pretensiones'];
        normasAplicables = resultado['normas_aplicables'];
        pruebas = resultado['pruebas'];
        juramento = resultado['juramento'];
        cargando = false;
        mostrarSugerencias = true;
      });
    } catch (e) {
      setState(() {
        hechos = derechosVulnerados = pretensiones = normasAplicables = pruebas = juramento = '❌ Error generando texto con IA: $e';
        cargando = false;
        mostrarSugerencias = true;
      });
    }
  }

  void _usarTexto() {
    widget.hechosController.text = hechos ?? '';
    widget.derechosVulneradosController.text = derechosVulnerados ?? '';
    widget.pretensionesController.text = pretensiones ?? '';
    widget.normasAplicablesController.text = normasAplicables ?? '';
    widget.pruebasController.text = pruebas ?? '';
    widget.juramentoController.text = juramento ?? '';
    setState(() {
      mostrarSugerencias = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Hechos", style: TextStyle(fontWeight: FontWeight.w900)),
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generar IA"),
              onPressed: cargando ? null : _generarTextoExtendido,
            )
          ],
        ),
        if (cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (mostrarSugerencias && hechos != null && derechosVulnerados != null && pretensiones != null
            && normasAplicables != null && pruebas != null && juramento != null)
          Card(
            elevation: 3,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🧠 Sugerencias de IA", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildSection("Hechos", hechos!),
                  _buildSection("Derechos Vulnerados", derechosVulnerados!),
                  _buildSection("Pretensiones", pretensiones!),
                  _buildSection("Normas Aplicaboles", normasAplicables!),
                  _buildSection("Pruebas", pruebas!),
                  _buildSection("Juramento", juramento!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Usar textos"),
                      onPressed: _usarTexto,
                    ),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String titulo, String contenido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(contenido),
        ],
      ),
    );
  }
}
