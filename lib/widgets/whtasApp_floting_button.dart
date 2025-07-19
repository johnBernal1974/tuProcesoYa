import 'dart:html' as html;
import 'package:flutter/material.dart';

class WhatsAppChatFloatingButton extends StatefulWidget {
  final String? acudienteNombre;
  final bool? isPaid;
  final String numeroCliente;
  final bool hasUnread;
  final VoidCallback onTap;

  const WhatsAppChatFloatingButton({
    Key? key,
    this.acudienteNombre,
    this.isPaid,
    required this.numeroCliente,
    required this.hasUnread,
    required this.onTap,
  }) : super(key: key);

  @override
  State<WhatsAppChatFloatingButton> createState() => _WhatsAppChatFloatingButtonState();
}

class _WhatsAppChatFloatingButtonState extends State<WhatsAppChatFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  bool _showInfo = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _widthAnimation = Tween<double>(
      begin: 56,
      end: 240,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Solo expandir si tiene mensajes no leídos
    if (widget.hasUnread) {
      _showInfo = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.forward();
        _playSound();
      });
    }
  }

  void _playSound() {
    final audio = html.AudioElement('sounds/sound_whatsapp.mp3');
    audio.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();

    if (_showInfo) {
      setState(() {
        _showInfo = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _handleTap,
          child: Container(
            width: _showInfo ? _widthAnimation.value : 56,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/icono_whatsapp.png',
                    width: 32,
                    height: 32,
                  ),
                ),
                if (_showInfo &&
                    _widthAnimation.value > 100 &&
                    widget.acudienteNombre != null &&
                    widget.acudienteNombre!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.acudienteNombre!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.isPaid != null)
                          Row(
                            children: [
                              Icon(
                                widget.isPaid! ? Icons.check_circle : Icons.cancel,
                                color: widget.isPaid! ? Colors.green : Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.isPaid! ? "Suscripción al día" : "Sin pago",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.isPaid! ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
