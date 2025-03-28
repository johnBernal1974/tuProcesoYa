// lib/widgets/texto_ia_con_card.dart
import 'package:flutter/material.dart';
import '../../commons/ia_backend_service/ia_backend_service.dart';

class TextoIAConCard extends StatefulWidget {
  final String categoria;
  final String subcategoria;
  final List<String> respuestasUsuario;
  final TextEditingController controllerDestino;

  const TextoIAConCard({
    super.key,
    required this.categoria,
    required this.subcategoria,
    required this.respuestasUsuario,
    required this.controllerDestino,
  });

  @override
  State<TextoIAConCard> createState() => _TextoIAConCardState();
}

class _TextoIAConCardState extends State<TextoIAConCard> {
  String? textoGeneradoIA;
  bool mostrarCard = false;
  bool cargando = false;

  Future<void> _generarTexto() async {
    setState(() {
      cargando = true;
    });

    try {
      final texto = await IABackendService.generarTextoDesdeCloudFunction(
        categoria: widget.categoria,
        subcategoria: widget.subcategoria,
        respuestasUsuario: widget.respuestasUsuario,
      );

      setState(() {
        textoGeneradoIA = texto;
        mostrarCard = true;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        textoGeneradoIA = "❌ Error generando texto con IA:\n$e";
        mostrarCard = true;
        cargando = false;
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
            const Text(
              "💡 TEXTO IA PERSONALIZADO",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            TextButton.icon(
              icon: cargando
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.auto_awesome),
              label: cargando ? const Text("Generando...") : const Text("Generar con IA"),
              onPressed: cargando ? null : _generarTexto,
            ),

          ],
        ),
        const SizedBox(height: 10),

        if (mostrarCard && textoGeneradoIA != null)
          Card(
            elevation: 2,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📝 Sugerencia de IA:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(textoGeneradoIA!),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        widget.controllerDestino.text = textoGeneradoIA!;
                        setState(() {
                          mostrarCard = false;
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Usar este texto"),
                    ),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}
