import 'dart:async';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgendaListener {
  static final AgendaListener _instance = AgendaListener._internal();
  factory AgendaListener() => _instance;

  AgendaListener._internal();

  Timer? _timer;
  final Set<String> _alertasMostradas = {};
  bool _iniciado = false;
  bool _mostrandoNotificacion = false;
  Function? _abrirCalendarioCallback;

  OverlayEntry? _notificacionActual;



  void configurarAbrirCalendario(Function callback) {
    _abrirCalendarioCallback = callback;
  }


  void iniciar(BuildContext context) {
    if (_iniciado) return;
    _iniciado = true;

    _timer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final ahora = DateTime.now();

      final snapshot = await FirebaseFirestore.instance
          .collection('agenda')
          .where('estado', isEqualTo: 'Pendiente')
          .where('fecha', isGreaterThanOrEqualTo: DateTime(ahora.year, ahora.month, ahora.day))
          .where('fecha', isLessThan: DateTime(ahora.year, ahora.month, ahora.day + 1))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fecha = (data['fecha'] as Timestamp).toDate();
        final diferencia = fecha.difference(ahora);

        if (_alertasMostradas.contains(doc.id)) continue;

        if (diferencia.inMinutes <= 0 && diferencia.inMinutes >= -1) {
          _alertasMostradas.add(doc.id);
          if (context.mounted) {
            _mostrarNotificacion(
              context,
              "⏰ ¡Actividad ahora!",
              "📝 ${data['comentario']}",
            );
          }
        } else if (diferencia.inMinutes > 0 && diferencia.inMinutes <= 300) {
          _alertasMostradas.add(doc.id);
          if (context.mounted) {
            _mostrarNotificacion(
              context,
              "⏳ Actividad próxima",
              "Faltan ${diferencia.inMinutes} min: 📝 ${data['comentario']}",
            );
          }
        }
      }
    });
  }

  void _mostrarNotificacion(BuildContext context, String titulo, String mensaje) {
    if (_mostrandoNotificacion) return;
    _mostrandoNotificacion = true;

    _reproducirSonido();

    final overlay = Overlay.of(context, rootOverlay: true);
    final controller = AnimationController(
      vsync: Navigator.of(context), // Usa el `TickerProvider` del contexto
      duration: const Duration(milliseconds: 500),
    );

    final animation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // desde la derecha
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    _notificacionActual = OverlayEntry(
      builder: (context) => Positioned(
        top: 30,
        right: 20,
        child: SlideTransition(
          position: animation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _abrirCalendarioCallback?.call();
                _notificacionActual?.remove();
                _mostrandoNotificacion = false;
                controller.dispose();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white, // Fondo blanco
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple, width: 2), // Borde morado
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxWidth: 320),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.deepPurple, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mensaje,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        _notificacionActual?.remove();
                        _mostrandoNotificacion = false;
                        controller.dispose();
                      },
                      child: const Icon(Icons.close, color: Colors.deepPurple, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay?.insert(_notificacionActual!);
    controller.forward();
  }


  void _reproducirSonido() {
    final audio = html.AudioElement('sounds/notificacion_agenda.mp3')..play();
  }

  void detener() {
    _timer?.cancel();
    _iniciado = false;
    _mostrandoNotificacion = false;
    _notificacionActual?.remove();
  }
}
