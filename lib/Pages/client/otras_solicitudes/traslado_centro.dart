import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_trasladoPenitenciaria/solicitud_exitosa_trasladoPenitenciaria.dart';

class SolicitudTrasladoPenitenciariaPage extends StatefulWidget {
  const SolicitudTrasladoPenitenciariaPage({super.key});

  @override
  State<SolicitudTrasladoPenitenciariaPage> createState() => _SolicitudTrasladoPenitenciariaPageState();
}

class _SolicitudTrasladoPenitenciariaPageState extends State<SolicitudTrasladoPenitenciariaPage> {

  final Map<String, bool> _motivosTraslado = {
    'Por acercamiento familiar': false,
    'Por derecho al trabajo o redención de pena': false,
    'Por razones de salud': false,
  };

  bool hayAlMenosUnMotivoSeleccionado() {
    return _motivosTraslado.values.any((seleccionado) => seleccionado);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud Traslado de Centro Penitenciario', style: TextStyle(color: blanco)),
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
                  'Solicitar el traslado a otro centro penitenciario',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Si te encuentras en un centro penitenciario donde no tienes acceso a actividades de resocialización como el trabajo, el estudio o programas productivos, puedes solicitar el traslado a otro establecimiento donde sí existan estas oportunidades.\n\n'
                      'El traslado también puede pedirse cuando:\n'
                      '- Hay riesgo para tu vida o integridad por amenazas o conflictos internos.\n'
                      '- Estás lejos de tu núcleo familiar y deseas acercarte a tu familia para fortalecer los lazos afectivos.\n'
                      '- Requieres atención médica especializada que no se brinda en tu lugar de reclusión.\n\n'
                      'Esta solicitud está respaldada por la Ley 65 de 1993 (Código Penitenciario y Carcelario), que establece que la pena debe cumplirse en condiciones dignas y con enfoque de resocialización. También se fundamenta en el derecho al trabajo (Artículo 25 de la Constitución) y el principio de dignidad humana.\n\n'
                      'El objetivo es que el INPEC evalúe tu caso y, si encuentra que se vulneran tus derechos o se limita tu acceso a la redención de pena, autorice tu traslado a un centro que cumpla con las condiciones necesarias.\n\n'
                      'Al presionar el siguiente botón, iniciarás el proceso para que tu solicitud sea registrada y tramitada. Nuestro equipo te apoyará durante todo el proceso.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
                const SizedBox(height: 30),
                const Text(
                  'Selecciona los motivos por los cuales solicitas el traslado:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 10),
                ..._motivosTraslado.entries.map((entry) {
                  return CheckboxListTile(
                    title: Text(entry.key),
                    value: entry.value,
                    activeColor: primary,
                    onChanged: (bool? value) {
                      setState(() {
                        _motivosTraslado[entry.key] = value ?? false;
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hayAlMenosUnMotivoSeleccionado() ? primary : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: hayAlMenosUnMotivoSeleccionado()
                      ? () async {
                    final confirmado = await mostrarConfirmacionEnvio(context);
                    if (confirmado) {
                      await verificarSaldoYEnviarSolicitudTraslado();
                    }
                  }
                      : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Por favor selecciona al menos un motivo antes de continuar."),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: const Text(
                    'Solicitar Traslado de Centro',
                    style: TextStyle(fontSize: 18, color: blanco),
                  ),
                ),
                const SizedBox(height: 30)
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
        content: const Text('¿Estás seguro de solicitar el traslado? Esta acción será enviada para su revisión y trámite.'),
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

  Future<void> verificarSaldoYEnviarSolicitudTraslado() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valor = (configSnapshot.docs.first.data()['valor_trasladoPenitenciaria'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valor) {
      await FirebaseFirestore.instance.collection('Ppl').doc(uid).update({'saldo': saldo - valor});
      await enviarSolicitudTrasladoPenitenciaria(valor);
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
                      tipoPago: 'trasladoPenitenciaria',
                      valor: valor.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudTrasladoPenitenciaria(valor);
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

  Future<void> enviarSolicitudTrasladoPenitenciaria(double valor) async {
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
      String docId = firestore.collection('trasladoPenitenciaria_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      await descontarSaldo(valor);

      final motivosSeleccionados = _motivosTraslado.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await firestore.collection('trasladoPenitenciaria_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
        'motivos': motivosSeleccionados, // <-- Aquí los motivos seleccionados
      });


      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Traslado de centro penitenciario",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "trasladoPenitenciaria_solicitados",
        fecha: Timestamp.now(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SolicitudExitosaTrasladoPenitenciariaPage(numeroSeguimiento: numeroSeguimiento),
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
    if (!snapshot.exists) return;

    final datos = snapshot.data();
    final double saldoActual = (datos?['saldo'] ?? 0).toDouble();
    final double nuevoSaldo = saldoActual - valor;

    if (nuevoSaldo >= 0) {
      await docRef.update({'saldo': nuevoSaldo});
    }
  }
}
