import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:tuprocesoya/src/colors/colors.dart'; // Asegúrate de que el color primary esté definido aquí

import '../../commons/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();
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
  bool _tienesCuenta = false;



  static const _baseUrl = 'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net';

  bool _otpEnviadoWA = false; // controla si ya enviamos código por WhatsApp

  String _aE164SinMas(String celular10) {
    // Espera 10 dígitos colombianos y retorna E.164 SIN '+', ej: 57XXXXXXXXXX
    final onlyDigits = celular10.replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.length == 10) return '57$onlyDigits';
    // si ya viene con 57 + 10 dígitos
    if (onlyDigits.length == 12 && onlyDigits.startsWith('57')) return onlyDigits;
    return onlyDigits; // fallback (evita crashear)
  }

  Future<Map<String, dynamic>> _postJson(String url, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final text = res.body.isEmpty ? '{}' : res.body;
    final data = jsonDecode(text) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Error $url');
    }
    return data;
  }

  Future<({int status, Map<String, dynamic> data})> _postJsonWithStatus(
      String url,
      Map<String, dynamic> body,
      ) async {
    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final text = res.body.isEmpty ? '{}' : res.body;
    final data = jsonDecode(text) as Map<String, dynamic>;
    return (status: res.statusCode, data: data);
  }





  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: blanco, size: 30),
        title: const Text(
          "Tu Proceso Ya",
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
                Column(
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
                        _isOtp ? "Ingresar a la cuenta" : "Iniciar sesión",
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // 🔥 Este espacio adicional debajo del título
                    if (_isOtp)
                      formularioOTP()
                    else
                      formularioCorreoContrasena(),

                    const SizedBox(height: 40),

                    if (_isOtp) // 🔵 El botón de recuperar solo para usuarios normales
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

                const SizedBox(height: 30),
                if(_tienesCuenta)
                Column(
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
                        _isOtp ? "Ingresar a la cuenta" : "Iniciar sesión",
                        style: TextStyle(
                          fontSize: screenWidth > 600 ? 24 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // 🔥 Este espacio adicional debajo del título
                    if (_isOtp)
                      formularioOTP()
                    else
                      formularioCorreoContrasena(),

                    const SizedBox(height: 40),

                    if (_isOtp) // 🔵 El botón de recuperar solo para usuarios normales
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await _authProvider.login(email, password, context);
    if (!success) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 🔹 1) Verifica si es administrador
    final adminDoc =
    await FirebaseFirestore.instance.collection('admin').doc(userId).get();

    if (adminDoc.exists) {
      // ✅ Validar si está bloqueado
      final status = adminDoc.data()?['status']?.toString().trim();
      if (status == 'bloqueado') {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/bloqueado', (_) => false);
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // ✅ Cargar rol del admin
      await AdminProvider().loadAdminData();
      final role = (AdminProvider().rol ?? "").trim();
      final roleNorm = role.toLowerCase();

      print("Rol obtenido en login: $role");

      // ✅ Ruteo por rol
      if (roleNorm == "pasante 1" || roleNorm == "pasante 2") {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            'historial_solicitudes_derecho_peticion_admin',
                (route) => false,
          );
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // ✅ NUEVO: rol "filtrado" entra directo a Filtrado inicial
      if (roleNorm == "filtrado") {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            'filtrado_inicial_page_admin',
                (route) => false,
          );
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // ✅ resto de admins
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, 'home_admin', (route) => false);
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 🔹 2) Si no es admin, buscar en Ppl
    final userDoc =
    await FirebaseFirestore.instance.collection('Ppl').doc(userId).get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().trim() ?? "";
      print("Estado del usuario en Ppl: $status");

      if (status == 'bloqueado') {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/bloqueado', (_) => false);
        }
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (status == 'registrado') {
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, 'estamos_validando', (route) => false);
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

    if (mounted) setState(() => _isLoading = false);
  }


  Future<void> _loginConOTP() async {
    final whatsApp = _whatsAppController.text.trim();

    // valida 10 dígitos
    if (!RegExp(r'^\d{10}$').hasMatch(whatsApp)) {
      _mostrarMensaje("Ingresa un número válido de 10 dígitos.", color: Colors.red);
      return;
    }

    final phoneE164SinMas = _aE164SinMas(whatsApp); // E.164 SIN '+'
    setState(() => _isLoadingOtp = true);

    try {
      // 1) PRIMER CLICK: enviar OTP SOLO si el número existe (login)
      if (!_otpEnviadoWA) {
        final r = await _postJsonWithStatus(
          '$_baseUrl/sendOtpWhatsAppLogin',   // <- endpoint de LOGIN
          {'phone': phoneE164SinMas},
        );

        if (r.status == 404) {
          _mostrarMensaje("Este número no está registrado. Crea tu cuenta primero.", color: Colors.red);
          return;
        }
        if (r.status >= 400) {
          final err = r.data['error']?.toString() ?? 'Error enviando OTP';
          final det = r.data['details']?.toString();
          _mostrarMensaje(det != null ? '$err: $det' : err, color: Colors.red);
          return;
        }

        setState(() {
          _otpEnviadoWA = true;
          _iniciarTemporizadorReenvio();
        });
        _mostrarMensaje("Código enviado por WhatsApp ✅", color: primary);
        return; // esperar a que el usuario escriba el OTP
      }

      // 2) SEGUNDO CLICK / onCompleted: verificar OTP (login)
      final codigo = _otpController.text.trim();
      if (codigo.length != 6) {
        _mostrarMensaje("El código debe tener 6 dígitos.", color: Colors.red);
        return;
      }

      final r = await _postJsonWithStatus(
        '$_baseUrl/verifyOtpWhatsAppLogin',  // <- endpoint de LOGIN
        {'phone': phoneE164SinMas, 'code': codigo},
      );

      if (r.status == 404) {
        _mostrarMensaje("Este número no está registrado.", color: Colors.red);
        return;
      }
      if (r.status >= 400) {
        final msg = r.data['error']?.toString() ?? 'Error verificando OTP';
        if (msg.contains('OTP expirado')) {
          _mostrarMensaje("El código expiró. Solicita uno nuevo.", color: Colors.red);
        } else if (msg.contains('Demasiados intentos')) {
          _mostrarMensaje("Demasiados intentos. Intenta más tarde.", color: Colors.red);
        } else if (msg.contains('Código inválido')) {
          _mostrarMensaje("El código es incorrecto.", color: Colors.red);
        } else if (msg.contains('No OTP solicitado')) {
          _mostrarMensaje("Primero solicita el código.", color: Colors.red);
        } else {
          final det = r.data['details']?.toString();
          _mostrarMensaje(det != null ? '$msg: $det' : msg, color: Colors.red);
        }
        return;
      }

      // 3) LOGIN con Custom Token
      final customToken = r.data['customToken'] as String?;
      if (customToken == null || customToken.isEmpty) {
        _mostrarMensaje("No se pudo obtener el token. Intenta de nuevo.", color: Colors.red);
        return;
      }

      final cred = await FirebaseAuth.instance.signInWithCustomToken(customToken);
      final uid = cred.user?.uid;
      if (uid == null) {
        _mostrarMensaje("No se pudo iniciar sesión.", color: Colors.red);
        return;
      }

      // === tu navegación existente ===
      final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(uid).get();
      if (adminDoc.exists) {
        final status = adminDoc.data()?['status']?.toString().trim();
        if (status == 'bloqueado') {
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/bloqueado', (_) => false);
          return;
        }
        await AdminProvider().loadAdminData();
        final role = AdminProvider().rol ?? "";
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

      final pplDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
      if (pplDoc.exists) {
        final status = pplDoc.data()?['status']?.toString().trim() ?? "";
        if (status == 'bloqueado') {
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/bloqueado', (_) => false);
          return;
        }
        if (status == 'registrado') {
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, 'estamos_validando', (route) => false);
        } else {
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
        }
      } else {
        if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      }

    } catch (e) {
      _mostrarMensaje("Error: $e", color: Colors.red);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    return Column(
      children: [
        Text("Introduce el número de celular que registraste.", style: TextStyle(
            fontSize: isMobile ? 13 : 22
        ),),
        const SizedBox(height: 25),

        // CAMPO DE CELULAR
        TextFormField(
          controller: _whatsAppController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: "Número de WhatsApp",
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

        if (_otpEnviadoWA)
          Column(
            children: [
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                autoDisposeControllers: false,
                autoFocus: true,
                enablePinAutofill: true,
                cursorColor: primary,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 44,
                  inactiveColor: Colors.grey.shade400,
                  activeColor: primary,
                  selectedColor: primary,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                ),
                animationDuration: const Duration(milliseconds: 180),
                enableActiveFill: true,
                onChanged: (_) {},
                onCompleted: (code) async {
                  // Cuando el usuario termina los 6 dígitos, verificamos
                  await _loginConOTP();
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
            onPressed: _isLoadingOtp || !_esNumeroCelularValido()
                ? null
                : _loginConOTP,
            child: _isLoadingOtp
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
              _otpEnviadoWA ? "Verificar código" : "Solicitar código",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        if (_otpEnviadoWA) ...[
          const SizedBox(height: 10),
          _puedeReenviar
              ? TextButton(
            onPressed: () async {
              setState(() => _otpEnviadoWA = false); // Reiniciamos para enviar
              await _loginConOTP();
            },
            child: const Text(
              "¿No recibiste el código? Reenviar",
              style: TextStyle(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              ),
            ),
          )
              : Text(
            "Podrás reenviar el código en $_contadorReenvio segundos",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ]

      ],
    );
  }

  bool _esNumeroCelularValido() {
    final celular = _whatsAppController.text.trim();
    return RegExp(r'^\d{10}$').hasMatch(celular);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
