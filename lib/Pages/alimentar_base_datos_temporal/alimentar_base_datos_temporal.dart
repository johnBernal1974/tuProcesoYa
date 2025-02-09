import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddDelitoPage extends StatefulWidget {
  @override
  _AddDelitoPageState createState() => _AddDelitoPageState();
}

class _AddDelitoPageState extends State<AddDelitoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _delitoController = TextEditingController();

  /// Método para agregar un delito a la colección "delitos"
  Future<void> _addDelito() async {
    if (_formKey.currentState!.validate()) {
      String delitoText = _delitoController.text;

      // Se agrega un documento en la colección "delitos"
      // Usamos .add() para que Firestore genere automáticamente el ID del documento.
      await FirebaseFirestore.instance.collection('delitos').add({
        'delito': delitoText, // Nodo llamado "delito" con el valor ingresado
        'created_at': FieldValue.serverTimestamp(), // Fecha de creación (opcional)
      });

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delito agregado correctamente')),
      );

      // Limpiar el campo de texto
      _delitoController.clear();
    }
  }

  @override
  void dispose() {
    _delitoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar Delito"),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: 600, // Puedes ajustar este ancho según tu diseño
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo de texto para ingresar el delito
                  TextFormField(
                    controller: _delitoController,
                    decoration: const InputDecoration(
                      labelText: 'Delito',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa un delito';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addDelito,
                    child: const Text('Agregar Delito'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
