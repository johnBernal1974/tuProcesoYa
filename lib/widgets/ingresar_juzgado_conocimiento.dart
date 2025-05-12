import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../src/colors/colors.dart';

class IngresarJuzgadoCondenoWidget extends StatefulWidget {
  const IngresarJuzgadoCondenoWidget({super.key});

  @override
  State<IngresarJuzgadoCondenoWidget> createState() => _IngresarJuzgadoCondenoWidgetState();
}

class _IngresarJuzgadoCondenoWidgetState extends State<IngresarJuzgadoCondenoWidget> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _nombreJuzgadoController = TextEditingController();

  String? ciudadSeleccionada;

  final List<String> ciudades = [
    'Antioquia', 'Arauca', 'Armenia', 'Barranquilla', 'Bello', 'Bogotá', 'Bucaramanga', 'Buenaventura', 'Buga',
    'Cali', 'Cartagena', 'Cartago', 'Chiquinquirá', 'Cúcuta', 'Duitama', 'Envigado', 'Florencia',
    'Funza', 'Fusagasugá', 'Garzón', 'Girardota', 'Ibagué', 'Manizales', 'Medellín', 'Mocoa',
    'Montería', 'Neiva', 'Palmira', 'Pasto', 'Pereira', 'Popayán', 'Prueba', 'Quibdó', 'Riohacha',
    'Rionegro', 'Santa Marta', 'Sincelejo', 'Soacha', 'Sogamoso', 'Tuluá', 'Tunja', 'Valledupar',
    'Villavicencio', 'Yopal', 'Zipaquirá'
  ];

  Future<void> guardarJuzgado() async {
    final correo = _correoController.text.trim().toLowerCase();
    final nombre = _nombreJuzgadoController.text.trim().toUpperCase();

    if (ciudadSeleccionada == null || correo.isEmpty || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos.')),
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('juzgado_condeno').doc(ciudadSeleccionada).set({
        'name': ciudadSeleccionada,
      }, SetOptions(merge: true));

      final String id = Random().nextInt(1000000).toString();

      await firestore
          .collection('juzgado_condeno')
          .doc(ciudadSeleccionada)
          .collection('juzgados')
          .doc(id)
          .set({
        'correo': correo,
        'nombre': nombre,
      });

      _correoController.clear();
      _nombreJuzgadoController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Juzgado guardado correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // 🔹 Asegura que todo el fondo sea blanco
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Ajustado para mejor espaciado
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa Juzgado de Conocimiento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              dropdownColor: Colors.amber.shade50,
              value: ciudadSeleccionada,
              items: ciudades.map((ciudad) {
                return DropdownMenuItem(
                  value: ciudad,
                  child: Text(ciudad),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  ciudadSeleccionada = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(
                labelText: 'Correo del juzgado',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombreJuzgadoController,
              decoration: const InputDecoration(
                labelText: 'Nombre del juzgado (se guardará en mayúsculas)',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: guardarJuzgado,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Juzgado'),
            ),
            const SizedBox(height: 32),
            if (ciudadSeleccionada != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Juzgados registrados en ${ciudadSeleccionada!}:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('juzgado_condeno')
                        .doc(ciudadSeleccionada)
                        .collection('juzgados')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No hay juzgados registrados.');
                      }

                      final juzgados = snapshot.data!.docs;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: juzgados.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nombre = data['nombre'] ?? 'Sin nombre';
                          final correo = data['correo'] ?? 'Sin correo';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                correo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Divider(thickness: 1),
                              const SizedBox(height: 4),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),

                ],
              ),
          ],
        ),
      ),
    );
  }

}
