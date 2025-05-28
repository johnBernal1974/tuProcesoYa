import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/Pages/client/solicitud_exitosa_acumulacion/solicitud_exitosa_acumulacion.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_extincion_pena/solicitud_exitosa_extincion_pena.dart';

class SolicitudAcumulacionPenasPage extends StatefulWidget {
  const SolicitudAcumulacionPenasPage({super.key});

  @override
  State<SolicitudAcumulacionPenasPage> createState() => _SolicitudAcumulacionPenasPageState();
}

class _SolicitudAcumulacionPenasPageState extends State<SolicitudAcumulacionPenasPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud Acumulación de Penas', style: TextStyle(color: blanco)),
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
                  'Unifica tus condenas para una pena justa',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 10),
                const Text(
                  'La acumulación de penas es un derecho reconocido por la legislación penal colombiana que permite unificar varias condenas en una sola, facilitando así el acceso a beneficios penitenciarios y garantizando un tratamiento justo en la ejecución de la pena.\n\n'
                      'Con base en el artículo 351 del Código de Procedimiento Penal (Ley 906 de 2004), una persona condenada mediante varias sentencias ejecutoriadas por hechos distintos puede solicitar que se acumulen dichas penas. '
                      'Este procedimiento lo resuelve el juez de ejecución de penas, quien deberá tomar como base la pena más grave y adicionar las demás de forma proporcional, sin exceder los topes legales establecidos en el Código Penal.\n\n'
                      'Según el artículo 31 del Código Penal (Ley 599 de 2000), el tiempo máximo de privación de la libertad en Colombia no podrá exceder los 60 años, incluso en caso de múltiples condenas. '
                      'Esta limitación garantiza que la sanción sea razonable y proporcional, conforme a los principios constitucionales de dignidad humana y resocialización.\n\n'
                      'El objetivo de esta solicitud es que el despacho judicial determine la pena única total, con el fin de establecer con claridad el tiempo real de cumplimiento, facilitar la planeación del tratamiento penitenciario y permitir el acceso a beneficios como libertad condicional o redenciones.\n\n'
                      'Al presionar el siguiente botón, iniciarás el proceso para que tu solicitud de acumulación de penas sea registrada, revisada y tramitada.',
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
                      await verificarSaldoYEnviarSolicitudAcumulacion();
                    }
                  },
                  child: const Text('Solicitar Acumulación de Penas', style: TextStyle(fontSize: 18, color: blanco)),
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
        content: const Text('¿Estás seguro de solicitar la acumulación de penas? Esta acción será enviada para su revisión y trámite.'),
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

  Future<void> verificarSaldoYEnviarSolicitudAcumulacion() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valor = (configSnapshot.docs.first.data()['valor_acumulacion'] ?? 0).toDouble();

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
                    tipoPago: 'acumulacion',
                    valor: valor.toInt(),
                    onTransaccionAprobada: () async {
                      await enviarSolicitudAcumulacion(valor);
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

  Future<void> enviarSolicitudAcumulacion(double valor) async {
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
      String docId = firestore.collection('acumulacion_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      await firestore.collection('acumulacion_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
      });

      await descontarSaldo(valor);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SolicitudExitosaAcumulacionPage(numeroSeguimiento: numeroSeguimiento),
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
