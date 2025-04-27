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
  int _contadorReenvio = 60;
  Timer? _timer;
  bool _puedeReenviar = false;


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
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔵 Primero "¿No tienes cuenta? / Regístrate aquí"
                Column(
                  children: [
                    const Text(
                      '¿No tienes una cuenta?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.double_arrow, color: Colors.black),
                          const SizedBox(width: 8),
                          Text(
                            "Regístrate aquí",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth > 600 ? 28 : 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Divider(color: gris, height: 1),
                const SizedBox(height: 30),

                // 🔵 Después el título "Iniciar Sesión"
                GestureDetector(
                  onTap: () {
                    _clickCounter++;
                    if (_clickCounter == 3) {
                      setState(() {
                        _isOtp = false;
                        _clickCounter = 0;
                      });
                    }

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
                    "Si ya tienes una cuenta creada",
                    style: TextStyle(
                      fontSize: screenWidth > 600 ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                // 🔵 Luego el formulario
                if (_isOtp)
                  formularioOTP()
                else
                  formularioCorreoContrasena(),

                const SizedBox(height: 40),

                // 🔵 Al final "¿Quieres recuperar tu cuenta?"
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
        try {
          final auth = FirebaseAuth.instance;
          final confirmation = await auth.signInWithPhoneNumber(celular);
          setState(() {
            _confirmationResult = confirmation;
            _iniciarTemporizadorReenvio();
          });
          _mostrarMensaje("Código enviado. Ingresa el código recibido.");
        } on FirebaseAuthException catch (e) {
          String errorMsg = "Error al enviar el código. Intenta de nuevo.";
          switch (e.code) {
            case 'invalid-phone-number':
              errorMsg = "El número de teléfono ingresado no es válido.";
              break;
            case 'network-request-failed':
              errorMsg = "Problemas de conexión. Verifica tu internet.";
              break;
            case 'too-many-requests':
              errorMsg = "Demasiados intentos. Espera un momento antes de volver a intentarlo.";
              break;
            default:
              errorMsg = "Error al enviar el código: ${e.message}";
              break;
          }
          _mostrarMensaje(errorMsg, color: Colors.red);
        }
      } else {
        // Segundo paso: confirmar el código
        try {
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
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, 'estamos_validando', (_) => false);
                }
              } else {
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, 'home', (_) => false);
                }
              }
            } else {
              _mostrarMensaje("Usuario no encontrado. Por favor regístrate.");
            }
          }
        } on FirebaseAuthException catch (e) {
          String errorMsg = "Error al verificar el código.";
          switch (e.code) {
            case 'invalid-phone-number':
              errorMsg = "El número de teléfono ingresado no es válido.";
              break;
            case 'invalid-verification-code':
              errorMsg = "El código de verificación es incorrecto.";
              break;
            case 'session-expired':
              errorMsg = "La sesión del código ha expirado. Solicita uno nuevo.";
              break;
            case 'network-request-failed':
              errorMsg = "Problemas de conexión. Revisa tu internet.";
              break;
            case 'too-many-requests':
              errorMsg = "Has intentado demasiadas veces. Por seguridad, debes esperar un momento.";
              break;
            case 'invalid-app-credential':
              errorMsg = "Hubo un error de autenticación. Por favor, intenta nuevamente.";
              break;
            case 'app-not-authorized':
              errorMsg = "Esta aplicación no está autorizada para realizar autenticaciones. Contacta soporte.";
              break;
            default:
              errorMsg = "Error: ${e.message}";
              break;
          }

          _mostrarMensaje(errorMsg, color: Colors.red);
        }
      }
    } finally {
      setState(() => _isLoadingOtp = false);
    }
  }


  void _iniciarTemporizadorReenvio() {
    _contadorReenvio = 60;
    _puedeReenviar = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_contadorReenvio == 0) {
        setState(() {
          _puedeReenviar = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _contadorReenvio--;
        });
      }
    });
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
            prefixIcon: const Icon(Icons.phone),
          ),
          onChanged: (value) {
            setState(() {}); // 🔥 Refresca la vista para habilitar o deshabilitar el botón
          },
        ),

        const SizedBox(height: 20),

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
                  prefixIcon: const Icon(Icons.lock_clock),
                ),
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
            onPressed: _isLoadingOtp || !_esNumeroCelularValido()
                ? null // 🔥 Desactiva el botón si está vacío o no válido
                : _loginConOTP,
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

  bool _esNumeroCelularValido() {
    final celular = _celularController.text.trim();
    return RegExp(r'^\d{10}$').hasMatch(celular);
  }



  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
