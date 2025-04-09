import 'dart:async';

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
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final MyAuthProvider _authProvider = MyAuthProvider();

  bool _isLoading = false;
  bool _obscureText = true;

  ConfirmationResult? _confirmationResult;
  bool _isLoadingOtp = false;


  bool _isOtp = true;
  int _clickCounter = 0;
  Timer? _tapTimer;

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
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
              constraints: const BoxConstraints(maxWidth: 600), // Limita el ancho máximo
              padding: const EdgeInsets.all(20.0), // Agrega espacio alrededor del contenido
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // 🔹 Asegura que los elementos estén en la parte superior
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _clickCounter++;
                      if (_clickCounter == 3) {
                        setState(() {
                          _isOtp = false;
                          _clickCounter = 0;
                        });
                      }

                      // Reinicia el contador si pasan más de 1.5s entre toques
                      _tapTimer?.cancel();
                      _tapTimer = Timer(const Duration(seconds: 2), () {
                        _clickCounter = 0;
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _isOtp = false;
                      });
                    },
                    child: Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        fontSize: screenWidth > 600 ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  if (_isOtp)
                    formularioOTP()
                  else
                    formularioCorreoContrasena(),
                  const SizedBox(height: 20),
                  // LINK PARA REGISTRARSE
                  if (_isOtp)
                    const SizedBox(height: 40),
                  Column(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tienes cuenta?', style: TextStyle(
                            fontSize: 13
                          ),),
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
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.double_arrow, color: primary), // Puedes cambiar el ícono si lo deseas
                                const SizedBox(width: 8),
                                Text(
                                  "Regístrate aquí",
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: screenWidth > 600 ? 18 : 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
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
                          "¿Quieres recuperar tu cuenta?",
                          style: TextStyle(
                            color: gris,
                            fontSize: screenWidth > 600 ? 18 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    ],
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

        if (userId != null) {
          // 🔹 Verifica si el usuario es administrador
          final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(userId).get();

          if (adminDoc.exists) {
            // ✅ Validar si está bloqueado
            final status = adminDoc.data()?['status']?.toString().trim();
            if (status == 'bloqueado') {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/bloqueado', (_) => false);
              }
              return;
            }

            // ✅ Cargar datos del administrador (incluyendo su rol)
            await AdminProvider().loadAdminData();
            String role = AdminProvider().rol ?? "";
            print("Rol obtenido en login: $role");

            if (role == "pasante 1" || role == "pasante 2") {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, 'historial_solicitudes_derecho_peticion_admin', (route) => false);
              }
              return;
            }

            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, 'home_admin', (route) => false);
            }
            return;
          }

          // 🔹 Si no es administrador, buscar en la colección 'Ppl'
          final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(userId).get();

          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().trim() ?? "";
            print("Estado del usuario en Ppl: $status");

            if (status == 'bloqueado') {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/bloqueado', (_) => false);
              }
              return;
            }

            if (status == 'registrado') {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, 'estamos_validando', (route) => false);
              }
            } else {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
              }
            }
          } else {
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

  Future<void> _loginConOTP() async {
    String celular = _celularController.text.trim();
    final codigo = _otpController.text.trim();

    // Añadir +57 si no lo tiene
    if (!celular.startsWith('+')) {
      if (celular.length == 10 && RegExp(r'^\d{10}$').hasMatch(celular)) {
        celular = '+57$celular';
      } else {
        _mostrarMensaje("Ingresa un número válido de 10 dígitos.");
        return;
      }
    }

    if (codigo.isNotEmpty && codigo.length != 6) {
      _mostrarMensaje("El código de verificación debe tener 6 dígitos.");
      return;
    }

    try {
      setState(() => _isLoadingOtp = true);

      if (_confirmationResult == null) {
        // Primer paso: enviar el código
        final auth = FirebaseAuth.instance;
        final confirmation = await auth.signInWithPhoneNumber(celular);
        setState(() {
          _confirmationResult = confirmation;
        });
        _mostrarMensaje("Código enviado. Ingresa el código recibido.");
      } else {
        // Segundo paso: confirmar el código
        final cred = await _confirmationResult!.confirm(codigo);

        if (cred.user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('Ppl')
              .doc(cred.user!.uid)
              .get();

          if (userDoc.exists) {
            final data = userDoc.data()!;
            final status = data['status']?.toString().trim() ?? "";

            if (status == 'bloqueado') {
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, 'bloqueo_page', (_) => false);
              }
              return;
            }

            if (status == 'registrado') {
              if(context.mounted){
                Navigator.pushNamedAndRemoveUntil(context, 'estamos_validando', (_) => false);
              }

            } else {
              if(context.mounted){
                Navigator.pushNamedAndRemoveUntil(context, 'home', (_) => false);
              }
            }
          } else {
            _mostrarMensaje("Usuario no encontrado. Por favor regístrate.");
          }
        }
      }
    } catch (e) {
      _mostrarMensaje("Error al verificar el código: ${e.toString()}");
    } finally {
      setState(() => _isLoadingOtp = false);
    }
  }


  void _mostrarMensaje(String mensaje, {Color color = Colors.black, int duracionSegundos = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: color,
        duration: Duration(seconds: duracionSegundos),
      ),
    );
  }

  Widget formularioCorreoContrasena(){
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // CAMPO DE CORREO
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Correo Electrónico",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: const TextStyle(color: gris),
              floatingLabelStyle: const TextStyle(color: primary, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: gris, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: gris, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
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
              labelStyle: const TextStyle(color: gris),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: gris, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: gris, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 2),
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
          const SizedBox(height: 50),
          // BOTÓN DE LOGIN
          SizedBox(
            width: 300,
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
    );
  }

  Widget formularioOTP() {
    return Column(
      children: [
        const Text("Inicia sesión con el número de celular que registraste."),
        const SizedBox(height: 25),
        // CAMPO DE CELULAR
        TextFormField(
          controller: _celularController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Número de celular",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: const TextStyle(color: gris),
            floatingLabelStyle: const TextStyle(color: primary, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: gris, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: gris, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            prefixIcon: const Icon(Icons.phone),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "El número es obligatorio";
            }
            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
              return "El número debe tener 10 dígitos";
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        // SOLO MOSTRAR EL CAMPO OTP SI YA SE ENVIÓ EL CÓDIGO
        if (_confirmationResult != null)
          Column(
            children: [
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Código de verificación",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: const TextStyle(color: gris),
                  floatingLabelStyle: const TextStyle(color: primary, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: gris, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: gris, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.lock_clock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ingresa el código OTP";
                  }
                  if (value.length != 6) {
                    return "El código debe tener 6 dígitos";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
            ],
          ),

        const SizedBox(height: 10),

        // BOTÓN DE VERIFICACIÓN / CONTINUAR
        SizedBox(
          width: 300,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: primary,
            ),
            onPressed: _isLoadingOtp ? null : _loginConOTP,
            child: _isLoadingOtp
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              _confirmationResult == null ? "Enviar código" : "Verificar código",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }




}
