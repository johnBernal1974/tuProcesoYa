import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart'; // Asegúrate de que el color primary esté definido aquí

import '../../commons/admin_provider.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final MyAuthProvider _authProvider = MyAuthProvider();

  bool _isLoading = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: negro, size: 30),
        title: const Text(
          "Bienvenido",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 600), // Limita el ancho máximo
              padding: const EdgeInsets.all(16.0), // Agrega espacio alrededor del contenido
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 🔹 Asegura que los elementos estén en la parte superior
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Text(
                    "Iniciar Sesión",
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // FORMULARIO
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // CAMPO DE CORREO
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Correo Electrónico",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "El correo es obligatorio";
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return "Introduce un correo válido";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // CAMPO DE CONTRASEÑA
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: "Contraseña",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                              child: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "La contraseña es obligatoria";
                            }
                            if (value.length < 6) {
                              return "La contraseña debe tener al menos 6 caracteres";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // BOTÓN DE LOGIN
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: primary,
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              "Ingresar",
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LINK PARA REGISTRARSE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta?'),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLoading = true;
                          });
                          Navigator.pushNamed(context, "register").then((_) {
                            setState(() {
                              _isLoading = false;
                            });
                          });
                        },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        )
                            : Text(
                          "Regístrate aquí",
                          style: TextStyle(
                            color: primary,
                            fontSize: screenWidth > 600 ? 18 : 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // LINK "Olvidé mi contraseña"
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "forgot_password");
                    },
                    child: Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(
                        color: primary,
                        fontSize: screenWidth > 600 ? 18 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ),
        ),
      );
  }



  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final success = await _authProvider.login(email, password, context);
      if (success) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        // Verifica si el usuario es administrador
        final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(userId).get();

        if (adminDoc.exists) {
          // ✅ Cargar el nombre del admin antes de navegar
          await AdminProvider().loadAdminData();
          // El usuario es administrador
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, 'home_admin', (route) => false);
          }
        } else {
          // El usuario no es administrador, se consulta el documento del usuario
          final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(userId).get();
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            final status = data['status'] ?? '';
            if (status == 'registrado') {
              // Si el status es "registrado", ir a EstamosValidandoPage
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, 'estamos_validando', (route) => false);
              }
            } else {
              // De lo contrario, ir a HomePage
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
              }
            }
          } else {
            // Si no se encuentra el documento del usuario, por defecto ir a HomePage
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
            }
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

}
