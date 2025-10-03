import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_desistimiento_apelacion/solicitud_exitosa_desistimiento_apelacion.dart';
import '../solicitud_exitosa_redenciones/solicitud_exitosa_redenciones.dart';

class SolicitudDesistimientoPage extends StatefulWidget {
  const SolicitudDesistimientoPage({Key? key}) : super(key: key);

  @override
  State<SolicitudDesistimientoPage> createState() => _SolicitudDesistimientoPageState();
}

class _SolicitudDesistimientoPageState extends State<SolicitudDesistimientoPage> {
  @override
  Widget build(BuildContext context) {
    const TextStyle textoNormal = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
    const TextStyle textoNegrilla = TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.bold, color: Colors.black);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Solicitud de Desistimiento de Apelación', style: TextStyle(color: Colors.white)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '📘 ¿Qué es el desistimiento de apelación?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                const Text(
                  'El desistimiento de apelación es el acto mediante el cual una persona que ha presentado recurso de apelación '
                      'decide renunciar a dicho recurso, solicitando que se archive o no continúe con su trámite. En el contexto penitenciario y judicial, '
                      'el desistimiento puede acelerar la decisión de fondo y evitar dilaciones procesales cuando la persona admite o acepta la decisión '
                      'del juez de primera instancia.',
                  textAlign: TextAlign.justify,
                  style: textoNormal,
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.justify,
                  text: const TextSpan(
                    style: textoNormal,
                    children: [
                      TextSpan(text: '⚠️ '),
                      TextSpan(text: 'Importante: ', style: textoNegrilla),
                      TextSpan(text: 'El desistimiento tiene efectos procesales que deben analizarse con cuidado. Antes de enviar un desistimiento se recomienda revisar sus efectos.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('📌 Fundamento y referencias (orientativas):', style: textoNegrilla),
                const SizedBox(height: 6),
                const Text(
                  '• Código General del Proceso y normas procesales aplicables sobre desistimiento y desistimiento tácito.\n'
                      '• Artículos y doctrina sobre efectos procesales del desistimiento en materia penal y de recursos.\n'
                      '• Jurisprudencia aplicable según el caso concreto y la materia penal.',
                  textAlign: TextAlign.justify,
                  style: textoNormal,
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: gris),
                const SizedBox(height: 20),

                const Text('Enviar solicitud de desistimiento de apelación', style: TextStyle(color: negro, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 20),

                const Text(
                  'Al enviar esta solicitud, autorizas a la plataforma Tu Proceso Ya a preparar y remitir el escrito de '
                      'desistimiento por los canales oficiales (correo institucional del juzgado, Inpec u oficina jurídica según sea el caso).',

                  textAlign: TextAlign.justify,
                  style: textoNormal,
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
                        content: const Text('¿Estás seguro de que deseas enviar esta solicitud de desistimiento de apelación?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
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
                  child: const Text('Solicitar ahora', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorServicio = (configSnapshot.docs.first.data()['valor_desistimiento_apelacion'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valorServicio) {
      await enviarSolicitudDesistimiento(valorServicio); // ✅ Ya no descontamos aquí
    } else {
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
                      tipoPago: 'desistimientoApelacion',
                      valor: valorServicio.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudDesistimiento(valorServicio); // ✅ Se ejecuta con saldo actualizado
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

  Future<void> enviarSolicitudDesistimiento(double valor) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !context.mounted) return;

    // ✅ Descontar antes de continuar
    await descontarSaldo(valor);

    if(context.mounted){
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
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String docId = firestore.collection('desistimiento_apelacion_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      await firestore.collection('desistimiento_apelacion_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        // puedes agregar más campos relevantes aquí (documentos, destinatarios, notas, etc.)
      });

      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Solicitud desistimiento apelación",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "desistimiento_apelacion_solicitados",
        fecha: Timestamp.now(),
      );

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaDesistimientoPage(
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
            content: Text("Hubo un problema al guardar la solicitud. ${e.toString()}"),
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
