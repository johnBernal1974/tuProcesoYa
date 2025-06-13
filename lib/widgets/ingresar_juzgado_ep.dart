import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../src/colors/colors.dart';

class IngresarJuzgadoEjecucionWidget extends StatefulWidget {
  const IngresarJuzgadoEjecucionWidget({super.key});

  @override
  State<IngresarJuzgadoEjecucionWidget> createState() => _IngresarJuzgadoEjecucionWidgetState();
}

class _IngresarJuzgadoEjecucionWidgetState extends State<IngresarJuzgadoEjecucionWidget> {
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _nombreJuzgadoController = TextEditingController();

  String? ciudadSeleccionada;
  List<String> ciudades = [];
  bool cargandoCiudades = true;

  Future<void> guardarJuzgado() async {
    final correo = _correoController.text.trim().toLowerCase();
    final nombreJuzgado = _nombreJuzgadoController.text.trim().toUpperCase();

    if (ciudadSeleccionada == null || correo.isEmpty || nombreJuzgado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos.')),
      );
      return;
    }

    if (!correo.contains('@') || !correo.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El correo ingresado no es válido.')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final String juzgadoEP =
        '${ciudadSeleccionada!} - $nombreJuzgado DE EJECUCIÓN DE PENAS Y MEDIDAS DE SEGURIDAD DE ${ciudadSeleccionada!}';

    try {
      // Verificar si el juzgadoEP ya existe
      final juzgadoExistente = await firestore
          .collection('ejecucion_penas')
          .where('juzgadoEP', isEqualTo: juzgadoEP)
          .limit(1)
          .get();

      if (juzgadoExistente.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este juzgado ya fue registrado.')),
        );
        return;
      }

      // Verificar si el correo ya existe
      final correoExistente = await firestore
          .collection('ejecucion_penas')
          .where('email', isEqualTo: correo)
          .limit(1)
          .get();

      if (correoExistente.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este correo ya está registrado.')),
        );
        return;
      }

      // 🔔 Confirmación previa
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar guardado'),
          content: Text(
            '¿Deseas guardar el siguiente juzgado?\n\n$juzgadoEP\n\nCorreo: $correo',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      // Guardar
      final String id = Random().nextInt(1000000).toString();

      await firestore.collection('ejecucion_penas').doc(id).set({
        'email': correo,
        'juzgadoEP': juzgadoEP,
        'created_at': Timestamp.now(),
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
  void initState() {
    super.initState();
    cargarCiudades();
  }

  Future<void> cargarCiudades() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ciudades_ejecucion')
          .orderBy('nombre')
          .get();
      setState(() {
        ciudades = snapshot.docs.map((doc) => doc['nombre'].toString()).toList();
        cargandoCiudades = false;
      });
    } catch (e) {
      debugPrint("❌ Error al cargar ciudades: $e");
      setState(() => cargandoCiudades = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa Juzgado de Ejecución',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            cargandoCiudades
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: guardarJuzgado,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar Juzgado'),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text(
                      '¿No está la ciudad en las opciones?',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _mostrarDialogoAgregarCiudad,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_location_alt),
                      label: const Text('Añadir Ciudad'),
                    ),
                  ],
                ),
              ],
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
                        .collection('ejecucion_penas')
                        .where('juzgadoEP', isGreaterThanOrEqualTo: '$ciudadSeleccionada -')
                        .where('juzgadoEP', isLessThan: '$ciudadSeleccionada.~')
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
                          final nombre = data['juzgadoEP'] ?? 'Sin nombre';
                          final correo = data['email'] ?? 'Sin correo';

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

  void _mostrarDialogoAgregarCiudad() {
    final TextEditingController ciudadController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blancoCards,
          title: const Text("Agregar nueva ciudad"),
          content: TextField(
            controller: ciudadController,
            decoration: const InputDecoration(
              labelText: "Nombre de la ciudad",
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey), // Borde por defecto
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey), // Borde cuando está habilitado
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey), // Borde cuando está enfocado
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevaCiudad = ciudadController.text.trim();
                if (nuevaCiudad.isEmpty) return;

                try {
                  await FirebaseFirestore.instance
                      .collection('ciudades_ejecucion')
                      .doc(nuevaCiudad)
                      .set({'nombre': nuevaCiudad});

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ciudad "$nuevaCiudad" añadida exitosamente')),
                  );
                  await cargarCiudades(); // 🔁 Recargar lista
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al añadir ciudad: $e')),
                  );
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }
}
