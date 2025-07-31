import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_copiaSentencia/solicitud_exitosa_copiaSentencia.dart';

class SolicitudCopiaSentenciaPage extends StatefulWidget {
  const SolicitudCopiaSentenciaPage({super.key});

  @override
  State<SolicitudCopiaSentenciaPage> createState() => _SolicitudCopiaSentenciaPageState();
}

class _SolicitudCopiaSentenciaPageState extends State<SolicitudCopiaSentenciaPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud Copia de Sentencia', style: TextStyle(color: blanco)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                const Text(
                  'Solicita copia auténtica de tu sentencia',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 10),
                const Text(
                  'La copia auténtica de la sentencia es un documento oficial emitido por el juzgado competente que contiene de manera íntegra la decisión judicial adoptada. '
                      'Esta copia es fundamental para la revisión del caso, el análisis de términos, la preparación de recursos y la tramitación de solicitudes o beneficios penitenciarios.\n\n'
                      'De acuerdo con los artículos 23 y 74 de la Constitución Política, la Ley 57 de 1985 y la Ley 1437 de 2011, toda persona tiene derecho a obtener copia de los documentos públicos que reposen en las entidades del Estado, incluyendo las sentencias judiciales, sin que se requiera la intervención de abogado.\n\n'
                      'El objetivo de esta solicitud es que la autoridad judicial remita una copia auténtica de la sentencia al solicitante o a las direcciones electrónicas indicadas, para garantizar el acceso a la justicia y el ejercicio pleno de los derechos.\n\n'
                      'Al presionar el siguiente botón, iniciarás el proceso para que tu solicitud de copia de sentencia sea registrada, revisada y tramitada.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () async {
                    final confirmado = await mostrarConfirmacionEnvio(context);
                    if (confirmado) {
                      await verificarSaldoYEnviarSolicitudCopiaSentencia();
                    }
                  },
                  child: const Text('Solicitar Copia de Sentencia', style: TextStyle(fontSize: 18, color: blanco)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> mostrarConfirmacionEnvio(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text('Confirmar envío'),
        content: const Text('¿Estás seguro de solicitar la copia de la sentencia? Esta acción será enviada para su revisión y trámite.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: blanco)),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> verificarSaldoYEnviarSolicitudCopiaSentencia() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valor = (configSnapshot.docs.first.data()['valor_copia_sentencia'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valor) {
      await FirebaseFirestore.instance.collection('Ppl').doc(uid).update({
        'saldo': saldo - valor,
      });

      await enviarSolicitudCopiaSentencia(valor);
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
                      tipoPago: 'copiaSentencia',
                      valor: valor.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudCopiaSentencia(valor);
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

  Future<void> enviarSolicitudCopiaSentencia(double valor) async {
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
      String docId = firestore.collection('copiaSentencia_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      await descontarSaldo(valor);

      await firestore.collection('copiaSentencia_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
      });

      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Copia de Sentencia",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "copiaSentencia_solicitados",
        fecha: Timestamp.now(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SolicitudExitosaCopiaSentenciaPage(numeroSeguimiento: numeroSeguimiento),
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
      }
    }
  }
}
