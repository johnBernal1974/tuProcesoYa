
import 'dart:ui_web' as ui;

import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HtmlVideoPlayer extends StatelessWidget {
  final String videoUrl;

  const HtmlVideoPlayer({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text('Reproductor solo disponible en la versión web.'),
      );
    }

    const viewID = 'html-video-element';

    // Esta línea solo funciona en Web
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
      final video = html.VideoElement()
        ..src = videoUrl
        ..controls = true
        ..autoplay = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      return video;
    });

    return const SizedBox(
      height: 600,
      width: 600,
      child: HtmlElementView(viewType: viewID),
    );
  }
}
