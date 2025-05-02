import 'package:flutter/material.dart';
import 'ia_backend_service.dart'; // Asegúrate de tener el nuevo método generado

class IASuggestionHechosTutela extends StatefulWidget {
  final String categoria;
  final String subcategoria;
  final List<String> respuestasUsuario;
  final TextEditingController hechosController;

  const IASuggestionHechosTutela({
    super.key,
    required this.categoria,
    required this.subcategoria,
    required this.respuestasUsuario,
    required this.hechosController,
  });

  @override
  State<IASuggestionHechosTutela> createState() => _IASuggestionHechosTutelaState();
}

class _IASuggestionHechosTutelaState extends State<IASuggestionHechosTutela> {
  bool cargando = false;
  String? hechosGenerados;
  bool mostrarResultado = false;

  Future<void> _generarHechos() async {
    setState(() {
      cargando = true;
      mostrarResultado = false;
    });

    try {
      final resultado = await IABackendService.generarTextoTutelaExtendido(
        categoria: widget.categoria,
        subcategoria: widget.subcategoria,
        respuestasUsuario: widget.respuestasUsuario,
      );
      print('🧪 Resultado desde IA Backend: $resultado');

      setState(() {
        hechosGenerados = resultado['hechos'] ?? 'No se pudo generar el texto.';
        mostrarResultado = true;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        hechosGenerados = '❌ Error generando hechos: $e';
        mostrarResultado = true;
        cargando = false;
      });
    }
  }

  void _usarHechos() {
    if (hechosGenerados != null) {
      widget.hechosController.text = hechosGenerados!;
      setState(() {
        mostrarResultado = false;
      });
    }
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
              onPressed: cargando ? null : _generarHechos,
            )
          ],
        ),
        if (cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (mostrarResultado && hechosGenerados != null)
          Card(
            elevation: 3,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🧠 Hechos sugeridos por IA", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(hechosGenerados!),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Usar texto"),
                      onPressed: _usarHechos,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
