import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';

class RegistrarOperadoresPage extends StatefulWidget {
  const RegistrarOperadoresPage({super.key});

  @override
  State<RegistrarOperadoresPage> createState() => _RegistrarOperadoresPageState();
}

class _RegistrarOperadoresPageState extends State<RegistrarOperadoresPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerOperador() async {
    if (!_formKey.currentState!.validate()) return;

    // Verifica si hay campos vacíos
    if (_nombreController.text.isEmpty ||
        _apellidosController.text.isEmpty ||
        _celularController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _confirmEmailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }

    // Validaciones de coincidencia
    if (_emailController.text != _confirmEmailController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Los correos electrónicos no coinciden")),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = userCredential.user!.uid;

// 🔍 Obtener la versión actual desde la colección 'configuraciones'
      final configDoc = await FirebaseFirestore.instance
          .collection('configuraciones')
          .doc('h7NXeT2STxoHVv049o3J')
          .get();

      final versionApp = configDoc.data()?['version_app'] ?? '1.0.0';

      await FirebaseFirestore.instance.collection('admin').doc(uid).set({
        'name': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'celular': _celularController.text.trim(),
        'email': _emailController.text.trim(),
        'fecha_registro': FieldValue.serverTimestamp(),
        'status': 'registrado',
        'rol': '',
        'version': versionApp, // 🔥 Asignar versión desde Firestore
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Operador registrado con éxito")),
        );
        Navigator.pushReplacementNamed(context, 'operadores_page');
      }

      print("**** Operador registrado exitosamente");
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Registrar Operador",
      content: SingleChildScrollView(
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width >= 1000 ? 600 : double.infinity,
          padding: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreController,
                    decoration: _inputDecoration("Nombre"),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _apellidosController,
                    decoration: _inputDecoration("Apellidos"),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _celularController,
                    decoration: _inputDecoration("Celular"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration("Email"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmEmailController,
                    decoration: _inputDecoration("Confirmar Email"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _inputDecoration("Contraseña"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: _inputDecoration("Confirmar Contraseña"),
                    obscureText: true,
                  ),
                  const SizedBox(height: 80),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: _registerOperador,
                    child: const Text("Registrar"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
   );
  }

  // Función para el estilo del input
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }
}
