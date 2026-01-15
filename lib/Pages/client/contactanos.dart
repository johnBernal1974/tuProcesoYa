import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactanosPage extends StatelessWidget {
  const ContactanosPage({super.key});

  static const String telefono = '3001312777';

  Future<void> _llamar() async {
    final Uri uri = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _abrirWhatsapp() async {
    const String telefono = '3001312777';

    final String mensaje = Uri.encodeComponent(
      'Hola, he cambiado mi numero de WhatsApp y requiero de su soporte.\n\nMil gracias.',
    );

    final Uri uri = Uri.parse(
      'https://wa.me/57$telefono?text=$mensaje',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir WhatsApp');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contáctanos'),
        backgroundColor:primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // 👈 vuelve a donde estaba
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const LogoApp(height: 60),
              const SizedBox(height: 40),
              const Text(
                '¿Cambiaste tu número de whatsApp\ny quieres actualizarlo?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              /// 📞 Llamada
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: _llamar,
                    borderRadius: BorderRadius.circular(12),
                    child: const Card(
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call, color: Colors.green, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Llamar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  /// 💬 WhatsApp
                  InkWell(
                    onTap: _abrirWhatsapp,
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/icono_whatsapp.png', // 👈 si tienes el logo
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) =>
                              const Icon(Icons.chat, color: Colors.green, size: 30),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Tel: $telefono',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class LogoApp extends StatelessWidget {
  final double height;
  final bool center;

  const LogoApp({
    super.key,
    this.height = 50,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/logo_tu_proceso_ya_transparente.png',
      height: height,
      fit: BoxFit.contain,
    );

    return center ? Center(child: logo) : logo;
  }
}

