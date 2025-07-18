import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

class PantallaInicioRegistroPage extends StatelessWidget {
  const PantallaInicioRegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: const Text(
          'Bienvenido',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Opcional: puedes ajustar a start
            children: [
              Image.asset(
                'assets/images/logo_tu_proceso_ya_transparente.png',
                height: isMobile ? 40 : 50,
              ),
              const SizedBox(height: 40),
              Text(
                '¿No tienes una cuenta?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.double_arrow, color: Colors.white),
                label: Text(
                  "Regístrate aquí",
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, "register");
                },
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "login");
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.double_arrow,
                      color: Colors.deepPurple,
                      size: isMobile ? 20 : 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Ya estoy registrado",
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
