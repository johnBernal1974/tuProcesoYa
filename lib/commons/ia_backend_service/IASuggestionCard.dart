// lib/widgets/ia_suggestion_card.dart
import 'package:flutter/material.dart';
import '../../commons/ia_backend_service/ia_backend_service.dart';

class IASuggestionCard extends StatefulWidget {
  final String categoria;
  final String subcategoria;
  final List<String> respuestasUsuario;
  final TextEditingController consideracionesController;
  final TextEditingController fundamentosController;
  final TextEditingController peticionController;

  const IASuggestionCard({
    super.key,
    required this.categoria,
    required this.subcategoria,
    required this.respuestasUsuario,
    required this.consideracionesController,
    required this.fundamentosController,
    required this.peticionController,
  });

  @override
  State<IASuggestionCard> createState() => _IASuggestionCardState();
}

class _IASuggestionCardState extends State<IASuggestionCard> {
  bool cargando = false;
  String? consideracion;
  String? fundamentos;
  String? peticion;

  Future<void> _generarTextoExtendido() async {
    setState(() => cargando = true);

    try {
      final resultado = await IABackendService.generarTextoExtendidoDesdeCloudFunction(
        categoria: widget.categoria,
        subcategoria: widget.subcategoria,
        respuestasUsuario: widget.respuestasUsuario,
      );

      setState(() {
        consideracion = resultado['consideracion'];
        fundamentos = resultado['fundamentos'];
        peticion = resultado['peticion'];
        cargando = false;
      });
    } catch (e) {
      setState(() {
        consideracion = fundamentos = peticion = '❌ Error generando texto con IA: $e';
        cargando = false;
      });
    }
  }

  void _usarTexto() {
    widget.consideracionesController.text = consideracion ?? '';
    widget.fundamentosController.text = fundamentos ?? '';
    widget.peticionController.text = peticion ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("💡 TEXTO IA EXTENDIDO", style: TextStyle(fontWeight: FontWeight.w900)),
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text("Generar IA"),
              onPressed: cargando ? null : _generarTextoExtendido,
            )
          ],
        ),
        if (cargando) const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        if (consideracion != null && fundamentos != null && peticion != null)
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
                  _buildSection("Consideraciones", consideracion!),
                  _buildSection("Fundamentos de Derecho", fundamentos!),
                  _buildSection("Petición Concreta", peticion!),
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
