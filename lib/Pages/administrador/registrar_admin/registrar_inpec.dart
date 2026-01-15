import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';

class RegistrarInpecPage extends StatefulWidget {
  const RegistrarInpecPage({super.key});

  @override
  State<RegistrarInpecPage> createState() => _RegistrarInpecPageState();
}

class _RegistrarInpecPageState extends State<RegistrarInpecPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _centroReclusionController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // ✅ Roles INPEC
  final List<String> _rolesInpec = const [
    'oficinaJuridica',
  ];

  String? _rolSeleccionado = 'oficinaJuridica';

  @override
  void dispose() {
    _centroReclusionController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerInpec() async {
    if (!_formKey.currentState!.validate()) return;

    // Verifica vacíos
    if (_centroReclusionController.text.trim().isEmpty ||
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

    // Coincidencia email / password
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
      // ✅ DEBUG: confirma que sigues logueado como admin ANTES
      final before = FirebaseAuth.instance.currentUser;
      debugPrint("ANTES -> UID: ${before?.uid} EMAIL: ${before?.email}");

      final callable = FirebaseFunctions.instance.httpsCallable('crearUsuarioInpec');

      final result = await callable.call({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'centro_reclusion': _centroReclusionController.text.trim(),
        'rolInpec': _rolSeleccionado ?? 'oficinaJuridica',

        // Si tu function no usa celular, puedes quitar esto.
        // Si sí lo quieres guardar, lo ideal es que también lo reciba la function:
        'celular': _celularController.text.trim(),
      });

      final data = (result.data as Map?) ?? {};
      final ok = data['ok'] == true;
      final uidNuevo = data['uid']?.toString();

      if (!ok) {
        throw Exception("La función no retornó ok=true");
      }

      // ✅ DEBUG: confirma que sigues logueado como admin DESPUÉS
      final after = FirebaseAuth.instance.currentUser;
      debugPrint("DESPUÉS -> UID: ${after?.uid} EMAIL: ${after?.email}");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario INPEC creado ✅ UID: ${uidNuevo ?? '-'}")),
      );

      // ✅ Opcional: limpia el formulario
      _centroReclusionController.clear();
      _celularController.clear();
      _emailController.clear();
      _confirmEmailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() => _rolSeleccionado = 'oficinaJuridica');

      // ✅ Navega donde tú quieras
      Navigator.pushReplacementNamed(context, 'inpec_page_admin');

    } on FirebaseFunctionsException catch (e) {
      // Errores controlados desde la function
      final msg = e.message ?? e.code;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $msg")),
      );
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
      pageTitle: "Registrar INPEC",
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
                      controller: _centroReclusionController,
                      decoration: _inputDecoration("Centro de reclusión"),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Obligatorio" : null,
                    ),
                    const SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: _rolSeleccionado,
                      items: _rolesInpec
                          .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _rolSeleccionado = v),
                      decoration: _inputDecoration("Rol"),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Selecciona un rol" : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _celularController,
                      decoration: _inputDecoration("Celular"),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return "Obligatorio";
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return "Debe tener 10 dígitos";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration("Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return "Obligatorio";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return "Email inválido";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _confirmEmailController,
                      decoration: _inputDecoration("Confirmar Email"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (value.isEmpty) return "Obligatorio";
                        if (value != _emailController.text.trim()) {
                          return "No coincide con el email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _passwordController,
                      decoration: _inputDecoration("Contraseña"),
                      obscureText: true,
                      validator: (v) {
                        final value = (v ?? '');
                        if (value.isEmpty) return "Obligatorio";
                        if (value.length < 6) return "Mínimo 6 caracteres";
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: _inputDecoration("Confirmar Contraseña"),
                      obscureText: true,
                      validator: (v) {
                        final value = (v ?? '');
                        if (value.isEmpty) return "Obligatorio";
                        if (value != _passwordController.text) {
                          return "No coincide con la contraseña";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 80),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _registerInpec,
                      child: const Text("Registrar"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
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
