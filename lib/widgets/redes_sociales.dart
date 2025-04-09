import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RedesSocialesWidget extends StatelessWidget {
  const RedesSocialesWidget({super.key});

  final String facebookUrl = 'https://www.facebook.com/profile.php?id=61575010985735';
  final String instagramUrl = 'https://www.instagram.com/tuprocesoya1?utm_source=qr';
  final String tiktokUrl = 'https://www.tiktok.com/@tuprocesoya2';

  void _abrirUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('❌ No se pudo abrir: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Padding(
          padding: EdgeInsets.only(right: isMobile ? 0 : 24), // 👈 padding derecho en PC
          child: Row(
            mainAxisAlignment: isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _abrirUrl(facebookUrl),
                child: Image.asset(
                  'assets/images/logo_facebook.png',
                  height: 35,
                  width: 35,
                  semanticLabel: 'Facebook',
                ),
              ),
              const SizedBox(width: 30),
              GestureDetector(
                onTap: () => _abrirUrl(instagramUrl),
                child: Image.asset(
                  'assets/images/logo_instagram.png',
                  height: 35,
                  width: 35,
                  semanticLabel: 'Instagram',
                ),
              ),
              const SizedBox(width: 30),
              GestureDetector(
                onTap: () => _abrirUrl(tiktokUrl),
                child: Image.asset(
                  'assets/images/logo_tiktok.png',
                  height: 35,
                  width: 35,
                  semanticLabel: 'TikTok',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
