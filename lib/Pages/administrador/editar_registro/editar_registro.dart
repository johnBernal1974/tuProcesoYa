import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';

class EditarRegistroPage extends StatefulWidget {
  final DocumentSnapshot doc;

  const EditarRegistroPage({Key? key, required this.doc}) : super(key: key);

  @override
  _EditarRegistroPageState createState() => _EditarRegistroPageState();
}

class _EditarRegistroPageState extends State<EditarRegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  late String _tipoDocumento;



  List<String> _opciones = [
    'Cédula de Ciudadanía',
    'Pasaporte',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializa los controllers con los valores del documento
    _nombreController.text = widget.doc.get('nombre_ppl');
    _apellidoController.text = widget.doc.get('apellido_ppl');
    _numeroDocumentoController.text =
        widget.doc.get('numero_documento_ppl').toString();
    _tipoDocumento = widget.doc.get('tipo_documento_ppl');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _numeroDocumentoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Datos generales',
      content: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Puedes mostrar el id en pantalla si lo deseas
            Text('ID del documento: ${widget.doc.id}'),
            const SizedBox(height: 20),
            const Text('Información del PPL', style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18
            ),),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su nombre';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _apellidoController,
              decoration: const InputDecoration(labelText: 'Apellido'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su apellido';
                }
                return null;
              },
            ),
            DropdownButtonFormField(
              value: _tipoDocumento,
              onChanged: (String? newValue) {
                setState(() {
                  _tipoDocumento = newValue!;
                });
              },
              items: _opciones.map((String option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Tipo de Documento',
              ),
            ),
            TextFormField(
              controller: _numeroDocumentoController,
              decoration:
              const InputDecoration(labelText: 'Número de Documento'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su número de documento';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Actualiza el documento en Firestore
                  widget.doc.reference.update({
                    'nombre_ppl': _nombreController.text,
                    'apellido_ppl': _apellidoController.text,
                    'numero_documento_ppl': int.tryParse(
                        _numeroDocumentoController.text) ??
                        0,
                    'tipo_documento_ppl':_tipoDocumento
                  }).then((_) {
                    Navigator.pop(context);
                  });
                }
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}