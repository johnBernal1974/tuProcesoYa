import 'dart:ui_web' as ui;
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HtmlVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const HtmlVideoPlayer({super.key, required this.videoUrl});

  @override
  State<HtmlVideoPlayer> createState() => _HtmlVideoPlayerState();
}

class _HtmlVideoPlayerState extends State<HtmlVideoPlayer> {
  late final String _viewType;
  late final String _effectiveUrl;

  @override
  void initState() {
    super.initState();

    // 1) viewType único por instancia (evita reutilización del mismo elemento)
    _viewType = 'html-video-element-${DateTime.now().microsecondsSinceEpoch}';

    // 2) (Opcional) cache-buster por si el navegador cachea el stream
    final separator = widget.videoUrl.contains('?') ? '&' : '?';
    _effectiveUrl = '${widget.videoUrl}$separator'
        'cb=${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewType,
            (int viewId) {
          final video = html.VideoElement()
            ..src = _effectiveUrl
            ..controls = true
            ..autoplay = true
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';

          // (Opcional) evita que el video quede con sonido al abrir
          // video.muted = true; // quítalo si no lo quieres

          return video;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text('Reproductor solo disponible en la versión web.'),
      );
    }

    return const SizedBox(
      height: 600,
      width: 600,
      // Usa el viewType ÚNICO registrado en initState
      child: HtmlElementView(viewType: ''),
    ).buildWithViewType(_viewType);
  }
}

// Pequeño helper para construir HtmlElementView con viewType dinámico
extension on SizedBox {
  Widget buildWithViewType(String viewType) {
    return SizedBox(
      height: height,
      width: width,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
