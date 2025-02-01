import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddCentroReclusionPage extends StatefulWidget {
  @override
  _AddCentroReclusionPageState createState() => _AddCentroReclusionPageState();
}

class _AddCentroReclusionPageState extends State<AddCentroReclusionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _directorController = TextEditingController();
  final _subdirectorController = TextEditingController();
  final _correoPrincipalController = TextEditingController();
  final _correoDireccionController = TextEditingController();
  final _correoJuridicaController = TextEditingController();
  final _correoSanidadController = TextEditingController();
  String? _selectedRegional;

  final List<String> _regionalList = [
    'Regional Central',
    'Regional Noroeste',
    'Regional Norte',
    'Regional Oriente',
    'Regional Occidental',
    'Regional Viejo Caldas'
  ];

  Future<void> _addCentroReclusion() async {
    if (_formKey.currentState!.validate() && _selectedRegional != null) {
      // Datos capturados
      String nombreCentro = _nombreController.text;
      String direccion = _direccionController.text;
      String telefono = _telefonoController.text;
      String director = _directorController.text;
      String subdirector = _subdirectorController.text;
      String correoPrincipal = _correoPrincipalController.text;
      String correoDireccion = _correoDireccionController.text;
      String correoJuridica = _correoJuridicaController.text;
      String correoSanidad = _correoSanidadController.text;

      // Guardar datos en Firestore bajo la regional seleccionada
      await FirebaseFirestore.instance
          .collection('regional')
          .doc(_selectedRegional) // Documento de la regional
          .collection('centros_reclusion') // Subcolección de centros de reclusión
          .doc(nombreCentro) // Documento del centro de reclusión
          .set({
        'nombre': nombreCentro,
        'direccion': direccion,
        'telefono': telefono,
        'director': director,
        'subdirector': subdirector,
        'correo_principal': correoPrincipal,
        'correo_direccion': correoDireccion,
        'correo_juridica': correoJuridica,
        'correo_sanidad': correoSanidad,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Confirmación y limpieza del formulario
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Centro de reclusión agregado')));
      _nombreController.clear();
      _direccionController.clear();
      _telefonoController.clear();
      _directorController.clear();
      _subdirectorController.clear();
      _correoPrincipalController.clear();
      _correoDireccionController.clear();
      _correoJuridicaController.clear();
      _correoSanidadController.clear();
      setState(() {
        _selectedRegional = null; // Resetear selección
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agregar Centro de Reclusión"),
      ),
      body: Container(
        color: Colors.white, // Fondo blanco
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: 600, // Limitar el ancho del formulario a la mitad de la pantalla
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Dropdown para seleccionar la regional
                  DropdownButtonFormField<String>(
                    value: _selectedRegional,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Regional',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRegional = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor selecciona una regional';
                      }
                      return null;
                    },
                    items: _regionalList.map((regional) {
                      return DropdownMenuItem<String>(
                        value: regional,
                        child: Text(regional),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  // Campos de texto con bordes grises y borde enfocado en primary
                  _buildTextFormField(_nombreController, 'Nombre del Centro'),
                  _buildTextFormField(_direccionController, 'Dirección'),
                  _buildTextFormField(_telefonoController, 'Teléfono'),
                  _buildTextFormField(_directorController, 'Director'),
                  _buildTextFormField(_subdirectorController, 'Subdirector'),
                  _buildTextFormField(_correoPrincipalController, 'Correo Principal'),
                  _buildTextFormField(_correoDireccionController, 'Correo Dirección'),
                  _buildTextFormField(_correoJuridicaController, 'Correo Jurídica'),
                  _buildTextFormField(_correoSanidadController, 'Correo Sanidad'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addCentroReclusion,
                    child: const Text('Agregar Centro'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método para crear un TextFormField reutilizable con bordes grises
  TextFormField _buildTextFormField(TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).primaryColor), // Borde enfocado en color primary
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Añadir espacio interno
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa $labelText';
        }
        return null;
      },
    );
  }
}
