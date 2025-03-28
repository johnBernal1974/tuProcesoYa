import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TextoIAGeneratorCard extends StatefulWidget {
  final String categoria;
  final String subcategoria;
  final List<String> respuestas;
  final TextEditingController controller;

  const TextoIAGeneratorCard({
    super.key,
    required this.categoria,
    required this.subcategoria,
    required this.respuestas,
    required this.controller,
  });

  @override
  State<TextoIAGeneratorCard> createState() => _TextoIAGeneratorCardState();
}

class _TextoIAGeneratorCardState extends State<TextoIAGeneratorCard> {
  String? textoGenerado;
  bool cargando = false;

  Future<void> generarTexto() async {
    setState(() => cargando = true);
    try {
      final response = await http.post(
        Uri.parse('https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/generarTextoIA'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'categoria': widget.categoria,
          'subcategoria': widget.subcategoria,
          'respuestasUsuario': widget.respuestas,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => textoGenerado = data['texto'] ?? '');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error IA: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Consideraciones", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(
              icon: cargando
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.auto_awesome),
              label: cargando ? const Text("Generando...") : const Text("Generar con IA"),
              onPressed: cargando ? null : generarTexto,
            ),


          ],
        ),
        const SizedBox(height: 8),
        if (textoGenerado != null && textoGenerado!.isNotEmpty)
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(textoGenerado!),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Usar este texto"),
                      onPressed: () {
                        setState(() {
                          widget.controller.text = textoGenerado!;
                        });
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        TextField(
          controller: widget.controller,
          minLines: 4,
          maxLines: 20,
          decoration: const InputDecoration(
            hintText: "Escribe aquí tus consideraciones...",
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
