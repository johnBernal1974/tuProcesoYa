import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../commons/preguntas_frecuentes.dart';

class PreguntasExpandiblesWidget extends StatefulWidget {
  const PreguntasExpandiblesWidget({super.key});

  @override
  State<PreguntasExpandiblesWidget> createState() => _PreguntasExpandiblesWidgetState();
}

class _PreguntasExpandiblesWidgetState extends State<PreguntasExpandiblesWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredPreguntas = preguntasFrecuentes.where((item) =>
    item['pregunta']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item['respuesta']!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        title: const Text(
          'Preguntas Frecuentes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar una pregunta...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim();
              });
            },
          ),
          const SizedBox(height: 20),
          ...filteredPreguntas.map((pregunta) {
            return Card(
              surfaceTintColor: blanco,
              color: blanco,
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                title: Text(
                  pregunta['pregunta']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      pregunta['respuesta']!.trim(),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.start,
                    )
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
