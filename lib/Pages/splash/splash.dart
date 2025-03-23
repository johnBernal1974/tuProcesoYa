import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../administrador/historial_solicitudes_derechos_peticion_admin/historial_solicitudes_derechos_peticion_admin.dart';
import '../administrador/home_admin/home_admin.dart';
import '../client/estamos_validando/estamos_validando.dart';
import '../client/home/home.dart';
import '../login/login.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Verificar autenticación después de una breve pausa
    Future.delayed(const Duration(seconds: 3), _checkAuthentication);
  }

  void _checkAuthentication() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;

      // 🔹 Verificar si el usuario es administrador
      final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(userId).get();

      if (adminDoc.exists) {
        // 🔹 Obtener el rol asegurando que no tenga espacios extra
        String role = adminDoc.data()?['rol']?.toString().trim() ?? "";
        print("Rol obtenido: $role"); // 📌 Depuración

        // 🔹 Verificar si es pasante 1 o pasante 2
        if (role == "pasante 1" || role == "pasante 2") {
          if (context.mounted) {
            print("Redirigiendo a SolicitudesDerechoPeticionAdminPage...");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HistorialSolicitudesDerechoPeticionAdminPage()),
            );
          }
          return;
        }

        // 🔹 Redirigir otros roles a la página de administración
        if (context.mounted) {
          print("Redirigiendo a HomeAdministradorPage...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeAdministradorPage()),
          );
        }
        return;
      }

      // 🔹 Si no es administrador, buscar en la colección 'Ppl'
      final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().trim() ?? "";
        print("Estado del usuario en Ppl: $status"); // 📌 Depuración

        if (status == 'registrado') {
          if (context.mounted) {
            print("Redirigiendo a EstamosValidandoPage...");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => EstamosValidandoPage()),
            );
          }
        } else {
          if (context.mounted) {
            print("Redirigiendo a HomePage...");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      } else {
        // 🔹 Usuario no encontrado, redirigir a LoginPage
        if (context.mounted) {
          print("Usuario no encontrado, redirigiendo a LoginPage...");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } else {
      // 🔹 Usuario no autenticado, redirigir a LoginPage
      if (context.mounted) {
        print("Usuario no autenticado, redirigiendo a LoginPage...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    }
  }




  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_tu_proceso_ya.png',
                width: isLargeScreen ? 300 : 200,
                height: isLargeScreen ? 250 : 150,
              ),
              const SizedBox(height: 20),
              Text(
                "Caminando contigo hacia la libertad",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isLargeScreen ? 24 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
