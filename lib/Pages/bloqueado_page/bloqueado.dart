import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart'; // Asegúrate de que esta ruta esté bien

class BloqueadoPage extends StatelessWidget {
  const BloqueadoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primary,
        automaticallyImplyLeading: false,
        title: const Text(
          "Cuenta suspendida",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_rounded,
                  color: Colors.orange.shade700, size: isLargeScreen ? 120 : 80),
              const SizedBox(height: 30),
              Text(
                "Tu cuenta ha sido suspendida temporalmente.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isLargeScreen ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Si consideras que esto es un error o deseas solicitar una revisión, por favor escríbenos a:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isLargeScreen ? 16 : 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              SelectableText(
                "contacto@tuprocesoya.com",
                style: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, 'info', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.arrow_back, color: blanco),
                label: const Text("Volver al inicio", style: TextStyle(color: blanco)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
