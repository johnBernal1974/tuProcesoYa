import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

/// Widget que muestra un reproductor audio embebido en la UI.
class AudioPlayerWeb extends StatefulWidget {
  final Uint8List bytes;

  const AudioPlayerWeb({super.key, required this.bytes});

  @override
  State<AudioPlayerWeb> createState() => _AudioPlayerWebState();
}

class _AudioPlayerWebState extends State<AudioPlayerWeb> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();

    // Un identificador único para el widget
    _viewId = 'audio-player-${UniqueKey()}';

    // Crear un blob con el audio
    final blob = html.Blob([widget.bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Registrar el reproductor
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final audio = html.AudioElement()
        ..src = url
        ..controls = true
        ..style.width = '250px'; // Ajusta el tamaño
      return audio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 50,
      child: HtmlElementView(
        viewType: _viewId,
      ),
    );
  }
}
