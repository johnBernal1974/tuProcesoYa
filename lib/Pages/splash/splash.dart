import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Verifica si el usuario está autenticado
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final userId = user.uid;
      // Verifica si el usuario es administrador consultando la colección "admin"
      final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(userId).get();

      if (adminDoc.exists) {
        // Usuario es administrador, redirige a la página de administrador
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeAdministradorPage()),
          );
        }
      } else {
        // Usuario no es administrador, consultamos su documento en la colección "users"
        final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(userId).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final status = data['status'] ?? '';

          // Si el status es "registrado", redirige a EstamosValidandoPage, de lo contrario a HomePage
          if (status == 'registrado') {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => EstamosValidandoPage()),
              );
            }
          } else {
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            }
          }
        } else {
          // Si no se encuentra el documento del usuario, redirige a HomePage (o maneja el error de otra forma)
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        }
      }
    } else {
      // Usuario no autenticado, redirige a LoginPage
      if (context.mounted) {
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
