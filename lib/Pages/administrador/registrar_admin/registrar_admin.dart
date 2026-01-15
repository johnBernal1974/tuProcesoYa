import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

    // ✅ Validación campos
    if (_nombreController.text.trim().isEmpty ||
        _apellidosController.text.trim().isEmpty ||
        _celularController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _confirmEmailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }

    if (_emailController.text.trim() != _confirmEmailController.text.trim()) {
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
      // ✅ 1) Verifica sesión admin
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No estás autenticado.")),
        );
        return;
      }

      // ✅ 2) Refresh token (web)
      final idToken = await user.getIdToken(true);
      debugPrint("TOKEN LEN: ${idToken?.length}");
      debugPrint("UID ACTUAL: ${user.uid}  EMAIL: ${user.email}");

      // ✅ 3) Callable
      final functions = FirebaseFunctions.instanceFor(region: "us-central1");
      final callable = functions.httpsCallable("crearUsuarioOperador");

      // ✅ 4) Payload
      final payload = {
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'celular': _celularController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        // 👇 si tienes dropdown de rol, lo mandas aquí
        'rol': 'operador 1', // o el valor que selecciones
      };

      final result = await callable.call(payload);

      final data = (result.data as Map?) ?? {};
      final ok = data['ok'] == true;
      final uidNuevo = data['uid']?.toString();

      if (!ok) throw Exception("La función no retornó ok=true");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Operador creado ✅ UID: ${uidNuevo ?? '-'}")),
      );

      // ✅ Limpia formulario
      _nombreController.clear();
      _apellidosController.clear();
      _celularController.clear();
      _emailController.clear();
      _confirmEmailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      // ✅ Navega donde quieras
      Navigator.pushReplacementNamed(context, 'operadores_page');

    } on FirebaseFunctionsException catch (e) {
      final code = e.code;
      final msg = e.message ?? e.code;

      debugPrint("FunctionsException: code=$code msg=$msg details=${e.details}");

      if (!mounted) return;

      if (code == "permission-denied") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No tienes permisos para crear operadores.")),
        );
      } else if (code == "already-exists") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ya existe un usuario con ese email.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $msg")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
