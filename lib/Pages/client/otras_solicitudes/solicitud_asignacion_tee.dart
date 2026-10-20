
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';

class SolicitudAsignacionTeePage extends StatefulWidget {
  const SolicitudAsignacionTeePage({super.key});

  @override
  State<SolicitudAsignacionTeePage> createState() =>
      _SolicitudAsignacionTeePageState();
}

class _SolicitudAsignacionTeePageState
    extends State<SolicitudAsignacionTeePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _procesando = false;

  Future<void> _iniciarSolicitud() async {
    if (_procesando) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: blanco,
        title: const Text('Confirmar solicitud'),
        content: const Text(
          '¿Deseas solicitar la asignación a actividades de '
              'Trabajo, Estudio o Enseñanza (TEE)? '
              'Tu solicitud será registrada para su revisión y trámite.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: blanco),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() => _procesando = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Debes iniciar sesión.');
      }

      final config = await _db
          .collection('configuraciones')
          .limit(1)
          .get();

      if (config.docs.isEmpty) {
        throw Exception('No existe la configuración de precios.');
      }

      final precio = config.docs.first
          .data()['valor_asignacion_tee'];

      if (precio is! num || precio <= 0) {
        throw Exception(
          'El precio de Asignación TEE no está configurado.',
        );
      }

      final valor = precio.toDouble();

      final usuario = await _db
          .collection('Ppl')
          .doc(uid)
          .get();

      if (!usuario.exists) {
        throw Exception('No se encontró el usuario.');
      }

      final saldo =
      ((usuario.data()?['saldo'] ?? 0) as num).toDouble();

      if (saldo >= valor) {
        await _registrarSolicitud(
          uid: uid,
          valor: valor,
          cobrarSaldo: true,
        );
      } else {
        if (!mounted) return;

        final pagar = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: blanco,
            title: const Text('Pago requerido'),
            content: const Text(
              'Para enviar esta solicitud debes realizar '
                  'el pago del servicio.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: const Text('Pagar'),
              ),
            ],
          ),
        );

        if (pagar == true && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckoutPage(
                tipoPago: 'asignacionTEE',
                valor: valor.toInt(),
                onTransaccionAprobada: () async {
                  await _registrarSolicitud(
                    uid: uid,
                    valor: valor,
                    cobrarSaldo: false,
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      _mostrarError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _registrarSolicitud({
    required String uid,
    required double valor,
    required bool cobrarSaldo,
  }) async {
    final solicitudRef =
    _db.collection('asignacionTEE_solicitados').doc();

    final numeroSeguimiento =
    (Random.secure().nextInt(900000000) + 100000000)
        .toString();

    final usuarioRef = _db.collection('Ppl').doc(uid);

    await _db.runTransaction((transaction) async {
      final usuario = await transaction.get(usuarioRef);

      if (!usuario.exists) {
        throw Exception('Usuario no encontrado.');
      }

      if (cobrarSaldo) {
        final saldo =
        ((usuario.data()?['saldo'] ?? 0) as num).toDouble();

        if (saldo < valor) {
          throw Exception('Saldo insuficiente.');
        }

        transaction.update(usuarioRef, {
          'saldo': saldo - valor,
        });
      }

      transaction.set(solicitudRef, {
        'id': solicitudRef.id,
        'idUser': uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': '',
        'tipoSolicitud': 'Asignación TEE',
        'valor': valor,
      });
    });

    final usuario = await usuarioRef.get();
    final datos = usuario.data() ?? {};

    try {
      await ResumenSolicitudesService.guardarResumen(
        idUser: uid,
        nombrePpl:
        '${datos['nombre_ppl'] ?? ''} '
            '${datos['apellido_ppl'] ?? ''}'.trim(),
        tipo: 'Asignación TEE',
        numeroSeguimiento: numeroSeguimiento,
        status: 'Solicitado',
        idOriginal: solicitudRef.id,
        origen: 'asignacionTEE_solicitados',
        fecha: Timestamp.now(),
      );
    } catch (e) {
      debugPrint('Pendiente sincronizar resumen TEE: $e');
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: blanco,
        title: const Text('Solicitud registrada'),
        content: Text(
          'Tu solicitud de Asignación TEE fue registrada '
              'correctamente.\n\n'
              'Número de seguimiento:\n'
              '$numeroSeguimiento',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: blanco),
            ),
          ),
        ],
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text(
          'Solicitud Asignación TEE',
          style: TextStyle(color: blanco),
        ),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: blanco),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Solicita tu Asignación TEE',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'La Asignación TEE (Trabajo, Estudio y '
                    'Enseñanza) es el procedimiento mediante '
                    'el cual una persona privada de la libertad '
                    'solicita ser vinculada a las actividades '
                    'laborales, educativas o de enseñanza '
                    'disponibles dentro del establecimiento '
                    'penitenciario.\n\n'
                    'Estas actividades contribuyen al proceso '
                    'de resocialización, permiten adquirir '
                    'conocimientos y desarrollar habilidades y, '
                    'cuando cumplen los requisitos legales, '
                    'pueden generar tiempo de redención de pena.\n\n'
                    'En Colombia, la Ley 65 de 1993 y sus '
                    'modificaciones regulan el trabajo, el '
                    'estudio, la enseñanza y la redención de pena '
                    'de las personas privadas de la libertad.\n\n'
                    'El objetivo de esta solicitud es pedir '
                    'formalmente al establecimiento penitenciario '
                    'que evalúe la vinculación de la persona '
                    'privada de la libertad a un programa de '
                    'Trabajo, Estudio o Enseñanza (TEE), '
                    'de acuerdo con los requisitos establecidos '
                    'y la disponibilidad de cupos.\n\n'
                    'La asignación no es automática y está '
                    'sujeta a la evaluación de la autoridad '
                    'penitenciaria competente.\n\n'
                    'Al presionar el siguiente botón, iniciarás '
                    'el proceso para que tu solicitud sea '
                    'registrada, revisada y tramitada.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                ),
                onPressed:
                _procesando ? null : _iniciarSolicitud,
                child: _procesando
                    ? const CircularProgressIndicator(
                  color: blanco,
                )
                    : const Text(
                  'Solicitar Asignación TEE',
                  style: TextStyle(
                    fontSize: 18,
                    color: blanco,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
