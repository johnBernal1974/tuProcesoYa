import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';
import '../../../commons/preguntas_frecuentes.dart';
import '../../../src/colors/colors.dart';

class PreguntasFrecuentesPage extends StatefulWidget {
  const PreguntasFrecuentesPage({super.key});

  @override
  State<PreguntasFrecuentesPage> createState() => _PreguntasFrecuentesPageState();
}

class _PreguntasFrecuentesPageState extends State<PreguntasFrecuentesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final horizontalPadding = isMobile ? 0.0 : 40.0;
    final containerPadding = isMobile ? 10.0 : 20.0;
    final containerMaxWidth = isMobile ? double.infinity : 800.0;

    final filteredPreguntas = preguntasFrecuentes.where((item) =>
    item['pregunta']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item['respuesta']!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return MainLayout(
      pageTitle: 'Preguntas Frecuentes',
      content: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: containerMaxWidth),
            padding: EdgeInsets.all(containerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Antes de comunicarte con nosotros, revisa estas preguntas frecuentes. Tal vez aquí encuentres lo que necesitas.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 20),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            pregunta['respuesta']!,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
