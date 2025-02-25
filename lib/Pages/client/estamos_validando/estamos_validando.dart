import 'package:flutter/material.dart';
import 'package:tuprocesoya/providers/auth_provider.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../splash/splash.dart';

class EstamosValidandoPage extends StatefulWidget {


  @override
  State<EstamosValidandoPage> createState() => _EstamosValidandoPageState();
}

class _EstamosValidandoPageState extends State<EstamosValidandoPage> {

  final MyAuthProvider _authProvider = MyAuthProvider();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bienvenido")),
      backgroundColor: blanco,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800), // Ajusta el ancho máximo para la versión de PC
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo_tu_proceso_ya_transparente.png',
                  height: 50,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Estamos validando la información que nos has suministrado.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center, // Justifica el texto
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nuestro equipo de tu proceso ya está trabajando en verificar la información proporcionada para garantizar la seguridad y precisión de tus datos.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify, // Justifica el texto
                ),
                const SizedBox(height: 20),
                const Text(
                  'Una vez finalizado el proceso, recibirás una notificación para informarte que ya puedes acceder a la aplicación con tus credenciales.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify, // Justifica el texto
                ),
                const SizedBox(height: 20),
                const Text(
                  'Agradecemos tu paciencia y confianza en nuestros servicios.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center, // Justifica el texto
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // Fondo en color primary
                    foregroundColor: Colors.white, // Texto en blanco
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SplashPage()),
                    );
                  },
                  child: const Text('Entendido'),
                ),
                const SizedBox(height: 100),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // Fondo en color primary
                    foregroundColor: Colors.white, // Texto en blanco
                  ),
                  onPressed: () async {
                    await _authProvider.signOut();
                    if(context.mounted){
                      Navigator.of(context).pop();
                      Navigator.pushNamedAndRemoveUntil(context, 'login', (Route<dynamic> route) => false);
                    }
                  },
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}