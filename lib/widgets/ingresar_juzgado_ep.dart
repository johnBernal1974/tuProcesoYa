import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class IngresarJuzgadoEjecucionWidget extends StatefulWidget {
  const IngresarJuzgadoEjecucionWidget({super.key});

  @override
  State<IngresarJuzgadoEjecucionWidget> createState() => _IngresarJuzgadoEjecucionWidgetState();
}

class _IngresarJuzgadoEjecucionWidgetState extends State<IngresarJuzgadoEjecucionWidget> {
  final TextEditingController _emailController = TextEditingController();

  final List<String> _ciudadesDisponibles = [
    'ARMENIA',
    'BARRANQUILLA',
    'BOGOTÁ',
    'BUCARAMANGA',
    'CALI',
    'CARTAGENA',
    'CÚCUTA',
    'FLORENCIA',
    'IBAGUÉ',
    'MANIZALES',
    'MEDELLÍN',
    'MOCOA',
    'MONTERÍA',
    'NEIVA',
    'PASTO',
    'PEREIRA',
    'POPAYÁN',
    'QUIPILE',
    'RIOHACHA',
    'SANTA MARTA',
    'SINCELEJO',
    'TUNJA',
    'VALLEDUPAR',
    'VILLAVICENCIO',
    'YOPAL'
  ];

  final List<String> _numerosJuzgado = List.generate(50, (i) => (i + 1).toString().padLeft(3, '0'));

  String? _ciudadSeleccionada;
  String? _numeroJuzgadoSeleccionado;
  bool _guardando = false;

  InputDecoration _decoracionCampo(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nuevo Juzgado de Ejecución", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              dropdownColor: Colors.amber.shade50,
              value: _ciudadSeleccionada,
              decoration: _decoracionCampo("Ciudad del juzgado"),
              items: _ciudadesDisponibles.map((ciudad) {
                return DropdownMenuItem(value: ciudad, child: Text(ciudad));
              }).toList(),
              onChanged: (val) => setState(() => _ciudadSeleccionada = val),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              dropdownColor: Colors.amber.shade50,
              value: _numeroJuzgadoSeleccionado,
              decoration: _decoracionCampo("Número del juzgado"),
              items: _numerosJuzgado.map((numero) {
                return DropdownMenuItem(value: numero, child: Text("JUZGADO $numero"));
              }).toList(),
              onChanged: (val) => setState(() => _numeroJuzgadoSeleccionado = val),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _emailController,
              decoration: _decoracionCampo('Correo del juzgado'),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (_ciudadSeleccionada == null || _numeroJuzgadoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona ciudad y número de juzgado")),
      );
      return;
    }

    final nombre = "${_ciudadSeleccionada!} - JUZGADO $_numeroJuzgadoSeleccionado DE EJECUCIÓN DE PENAS Y MEDIDAS DE SEGURIDAD DE ${_ciudadSeleccionada!}".toUpperCase();
    final email = _emailController.text.trim().toLowerCase();

    setState(() => _guardando = true);

    try {
      await FirebaseFirestore.instance.collection('ejecucion_penas').add({
        'juzgadoEP': nombre,
        'email': email,
        'ciudad': _ciudadSeleccionada!,
        'created_at': DateTime.now(),
      });

      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar el juzgado")),
      );
    }

    setState(() => _guardando = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
