import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RedPplImageLink extends StatelessWidget {
  final String imageAsset;
  final String linkUrl;

  const RedPplImageLink({
    Key? key,
    required this.imageAsset,
    this.linkUrl = 'https://red-ppl-y-familias.web.app/',
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context, String linkUrl) async {
    final uri = Uri.parse(linkUrl);
    try {
      // Llamamos a launchUrl pero NO mostramos SnackBar si devuelve false.
      // En muchas plataformas (especialmente web) launchUrl puede devolver false
      // aun cuando el navegador abre la URL, por eso evitamos depender del valor de retorno.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Solo en caso de excepción real mostramos el mensaje.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el enlace: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isDesktop = w >= 1000;
    final bool isTablet = w >= 600 && w < 1000;

    final double imageWidth = isDesktop ? 350 : isTablet ? 240 : 150;

    return GestureDetector(
      onTap: () => _launchURL(context, 'https://red-ppl-y-familias.web.app/'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Image.asset(
          imageAsset,
          width: imageWidth,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
