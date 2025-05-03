import 'package:flutter/material.dart';
import 'package:tuprocesoya/providers/auth_provider.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../splash/splash.dart';

class EstamosValidandoPage extends StatefulWidget {
  @override
  State<EstamosValidandoPage> createState() => _EstamosValidandoPageState();
}

class _EstamosValidandoPageState extends State<EstamosValidandoPage> {
  final MyAuthProvider _authProvider = MyAuthProvider();

  Future<void> _signOut() async {
    await _authProvider.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, 'login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        // actions: [
        //   TextButton.icon(
        //     onPressed: _signOut,
        //     icon: const Icon(Icons.logout, color: Colors.black87),
        //     label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.black87)),
        //   ),
        // ],
      ),
      backgroundColor: blanco,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800), // Ajusta el ancho máximo para la versión de PC
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_tu_proceso_ya_transparente.png',
                    height: 50,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Estamos validando la información que nos has suministrado.',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nuestro equipo de tu proceso ya está trabajando en verificar la información proporcionada para garantizar la seguridad y precisión de tus datos.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'En un máximo de 72 horas recibirás una notificación para informarte que ya puedes acceder a la aplicación con tus credenciales.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Agradecemos la confianza que depositaste en nosotros.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1),
                    textAlign: TextAlign.center,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
