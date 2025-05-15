import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_extincion_pena/solicitud_exitosa_extincion_pena.dart';
import '../solucitud_exitosa_traslado_proceso/solucitud_exitosa_traslado_proceso.dart';

class SolicitudTrasladoProcesoPage extends StatefulWidget {
  const SolicitudTrasladoProcesoPage({super.key});

  @override
  State<SolicitudTrasladoProcesoPage> createState() => _SolicitudTrasladoProcesoPageState();
}

class _SolicitudTrasladoProcesoPageState extends State<SolicitudTrasladoProcesoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud traslado de proceso', style: TextStyle(color: blanco)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: '🧾 Solicitud de traslado de proceso de ejecución de la pena\n\n',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const TextSpan(
                      text:
                      'En algunos casos, las personas privadas de la libertad son trasladadas a centros penitenciarios ubicados en ciudades distintas a donde se dictó su condena. '
                          'Esto puede generar dificultades para acceder a beneficios como la ',
                    ),
                    const TextSpan(
                      text: 'libertad condicional, los permisos de 72 horas o las redenciones',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                      ', ya que el juez que lleva su proceso sigue estando en otro lugar.\n\n',
                    ),
                    const TextSpan(
                      text: 'Con esta solicitud, puedes pedir que el ',
                    ),
                    const TextSpan(
                      text: 'proceso de ejecución de la pena sea trasladado ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                      'al juzgado de ejecución de penas del lugar donde actualmente estás recluido, facilitando así el ',
                    ),
                    const TextSpan(
                      text:
                      'acceso a la justicia, el seguimiento de tu condena y la presentación de nuevas solicitudes.\n\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                      'Este trámite no cambia tu condena, pero permite que el juez que vigila su cumplimiento esté más cerca de ti.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: () async {
                  final confirmado = await mostrarConfirmacionEnvio(context);
                  if (confirmado) {
                    await verificarSaldoYEnviarSolicitud();
                  }
                },
                child: const Text('Solicitar Traslado de proceso', style: TextStyle(fontSize: 18, color: blanco)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> mostrarConfirmacionEnvio(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text('Confirmar envío'),
          content: const Text('¿Estás seguro de solicitar el traslado de proceso? Esta acción será enviada para su revisión y trámite.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar', style: TextStyle(color: blanco)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorTrasladoProceso = (configSnapshot.docs.first.data()['valor_traslado_proceso'] ?? 0).toDouble();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Pago requerido"),
        content: const Text("Para enviar esta solicitud debes realizar el pago del servicio."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutPage(
                    tipoPago: 'traslado',
                    valor: valorTrasladoProceso.toInt(),
                    onTransaccionAprobada: () async {
                      await enviarSolicitudTrasladoProceso(valorTrasladoProceso);
                    },
                  ),
                ),
              );
            },
            child: const Text("Pagar"),
          ),
        ],
      ),
    );
  }

  Future<void> enviarSolicitudTrasladoProceso(double valorTrasladoProceso) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: blancoCards,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Enviando solicitud..."),
          ],
        ),
      ),
    );

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String docId = firestore.collection('traslado_proceso_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      await firestore.collection('traslado_proceso_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
      });

      await descontarSaldo(valorTrasladoProceso);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaTrasladoProcesoPage(numeroSeguimiento: numeroSeguimiento),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Hubo un problema al guardar la solicitud."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar")),
            ],
          ),
        );
      }
    }
  }

  Future<void> descontarSaldo(double valor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('Ppl').doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final datos = snapshot.data();
      final double saldoActual = (datos?['saldo'] ?? 0).toDouble();
      final double nuevoSaldo = saldoActual - valor;

      if (nuevoSaldo >= 0) {
        await docRef.update({'saldo': nuevoSaldo});
      } else {
        debugPrint('⚠️ Saldo insuficiente, no se pudo descontar');
      }
    }
  }
}
