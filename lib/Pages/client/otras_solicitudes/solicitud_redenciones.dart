import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_redenciones/solicitud_exitosa_redenciones.dart';

class SolicitudRedencionPage extends StatefulWidget {
  const SolicitudRedencionPage({Key? key}) : super(key: key);

  @override
  State<SolicitudRedencionPage> createState() => _SolicitudRedencionPageState();
}

class _SolicitudRedencionPageState extends State<SolicitudRedencionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Solicitud de Redención', style: TextStyle(color: Colors.white)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '📘 ¿Qué es la redención de pena?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'La redención de pena es un derecho contemplado en el artículo 141 de la Ley 65 de 1993 (Código Penitenciario y Carcelario de Colombia), el cual establece que las personas privadas de la libertad pueden redimir parte de su condena a través del trabajo, el estudio o la enseñanza durante el tiempo de reclusión.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 10),
                const Text(
                  'De acuerdo con esta norma, por cada **dos días de trabajo o estudio**, la persona tiene derecho a que se le redima **un día de pena**. Esta redención no es automática: debe ser solicitada, sustentada y posteriormente aprobada por la autoridad competente, previa verificación del cumplimiento efectivo de las actividades desarrolladas.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Esta solicitud será enviada a la autoridad penitenciaria y judicial correspondiente para su estudio, validación y eventual aprobación, conforme a los requisitos legales. Recuerda que la redención también puede influir positivamente en el acceso a beneficios como permisos de 72 horas, prisión domiciliaria o libertad condicional.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 10),
                const Text(
                  '📌 Fundamento legal:\n• Artículo 141, Ley 65 de 1993\n• Artículo 147, Ley 65 de 1993\n• Jurisprudencia de la Corte Suprema de Justicia (Radicación No. 39257, entre otras)',
                  textAlign: TextAlign.justify,
                ),

                const SizedBox(height: 10),
                const Text(
                  'Esta solicitud será enviada a la autoridad competente para el respectivo cómputo.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final confirmacion = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: blanco,
                        title: const Text('Confirmar envío'),
                        content: const Text('¿Estás seguro de que deseas enviar esta solicitud de redención?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primary),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Enviar', style: TextStyle(color: blanco)),
                          ),
                        ],
                      ),
                    );

                    if (confirmacion == true) {
                      await verificarSaldoYEnviarSolicitud();
                    }
                  },
                  child: const Text('Solicitar redención', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 50)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorRedenciones = (configSnapshot.docs.first.data()['valor_redenciones'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valorRedenciones) {
      // 💰 Tiene saldo suficiente, descuéntalo y envía
      await FirebaseFirestore.instance.collection('Ppl').doc(uid).update({
        'saldo': saldo - valorRedenciones,
      });
      await enviarSolicitudRedencion(valorRedenciones);
    } else {
      // ❌ No tiene saldo suficiente, mostrar diálogo para pagar
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
                      tipoPago: 'redenciones',
                      valor: valorRedenciones.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudRedencion(valorRedenciones);
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
  }


  Future<void> enviarSolicitudRedencion(double valor) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !context.mounted) return;

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
      String docId = firestore.collection('redenciones_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      // 🔍 Obtener nombre y apellido del PPL
      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      await firestore.collection('redenciones_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
      });

      // 👉 Guardar resumen
      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Solicitd redenciones",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "redenciones_solicitados",
        fecha: Timestamp.now(),
      );
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaRedencionPage(
              numeroSeguimiento: numeroSeguimiento,
            ),
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
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
