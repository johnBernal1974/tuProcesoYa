import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_asignacion_jep/solicitud_exitosa_asignacion_jep.dart';

class SolicitudAsignacionJepPage extends StatefulWidget {
  const SolicitudAsignacionJepPage({super.key});

  @override
  State<SolicitudAsignacionJepPage> createState() => _SolicitudAsignacionJepPageState();
}

class _SolicitudAsignacionJepPageState extends State<SolicitudAsignacionJepPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud asignación Juzgado de Ejecución de Penas', style: TextStyle(color: blanco)),
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
                const SizedBox(height: 10),
                // Texto informativo
                RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: '🧾 Solicitud de asignación de Juzgado de Ejecución de Penas\n\n',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const TextSpan(
                        text:
                        'Cuando el juzgado de conocimiento aún no ha asignado un Juzgado de Ejecución de Penas (JEP) para vigilar el cumplimiento de la condena, '
                            'se dificulta la radicación de solicitudes como libertad condicional, redenciones o permisos.\n\n'
                            'Con este trámite, solicitaremos formalmente que se asigne el JEP competente a su proceso, con el fin de habilitar la gestión de los beneficios y '
                            'garantizar el seguimiento adecuado de la sentencia.\n\n',
                      ),
                      const TextSpan(
                        text: 'No necesitas suministrar información adicional.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Divider(color: gris),
                const SizedBox(height: 25),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: () async {
                    final confirmado = await _mostrarConfirmacionEnvio(context);
                    if (confirmado) {
                      await _verificarSaldoYEnviar();
                    }
                  },
                  child: const Text('Solicitar asignación de JEP', style: TextStyle(fontSize: 18, color: blanco)),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _mostrarConfirmacionEnvio(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text('Confirmar envío'),
          content: const Text(
              '¿Deseas enviar la solicitud para que el juzgado de conocimiento asigne el Juzgado de Ejecución de Penas (JEP)?'
          ),
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

  Future<void> _verificarSaldoYEnviar() async {
    // Precio desde configuraciones
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorAsignacionJep = (configSnapshot.docs.first.data()['valor_asignacion_jep'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valorAsignacionJep) {
      await _enviarSolicitudAsignacionJEP(valorAsignacionJep); // sin ir a pago
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
                      tipoPago: 'asignacionJep',
                      valor: valorAsignacionJep.toInt(),
                      onTransaccionAprobada: () async {
                        await _enviarSolicitudAsignacionJEP(valorAsignacionJep);
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

  Future<void> _enviarSolicitudAsignacionJEP(double valor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!context.mounted) return;

    // Descontar saldo primero
    await _descontarSaldo(valor);

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
      final firestore = FirebaseFirestore.instance;
      final String docId = firestore.collection('asignacionJEP_solicitados').doc().id;
      final String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      // Nombre del PPL para el resumen
      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      // Guardar solicitud
      await firestore.collection('asignacionJEP_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
        // No hay más campos requeridos para este trámite
      });

      // Guardar resumen
      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Asignación JEP",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "asignacionJEP_solicitados",
        fecha: Timestamp.now(),
      );

      if (!context.mounted) return;
      Navigator.pop(context); // cierra loader

      // Ir a éxito
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SolicitudExitosaAsignacionJepPage(numeroSeguimiento: numeroSeguimiento),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // cierra loader
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

  Future<void> _descontarSaldo(double valor) async {
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
