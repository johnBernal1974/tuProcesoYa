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
    const TextStyle textoNormal = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
    const TextStyle textoNegrilla = TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.bold, color: Colors.black);
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
                  'La redención de pena es un mecanismo legal que permite a las personas privadas de la libertad (PPL) reducir su condena a través del trabajo, el estudio o la enseñanza durante su tiempo de reclusión.',
                  textAlign: TextAlign.justify,
                  style: textoNormal,
                ),
                const SizedBox(height: 10),

                RichText(
                  textAlign: TextAlign.justify,
                  text: const TextSpan(
                    style: textoNormal,
                    children: [
                      TextSpan(text: 'Gracias al '),
                      TextSpan(text: 'Artículo 19 de la Ley 2466 de 2025', style: textoNegrilla),
                      TextSpan(text: ', que hace parte de la reciente Reforma Laboral en Colombia, este beneficio fue ampliado: por cada '),
                      TextSpan(text: 'tres (3) días de trabajo o estudio', style: textoNegrilla),
                      TextSpan(text: ', se podrá redimir '),
                      TextSpan(text: 'dos (2) días de pena', style: textoNegrilla),
                      TextSpan(text: '. Este nuevo esquema fortalece el reconocimiento del esfuerzo realizado por las personas en proceso de resocialización.'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                RichText(
                  textAlign: TextAlign.justify,
                  text: const TextSpan(
                    style: textoNormal,
                    children: [
                      TextSpan(text: 'Además, esta norma reconoce legalmente estas actividades como '),
                      TextSpan(text: 'experiencia laboral válida', style: textoNegrilla),
                      TextSpan(text: ', siempre que sean certificadas por el INPEC o las autoridades penitenciarias competentes. Esto abre nuevas puertas para la reintegración social y laboral una vez cumplida la condena.'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                RichText(
                  textAlign: TextAlign.justify,
                  text: const TextSpan(
                    style: textoNormal,
                    children: [
                      TextSpan(text: '⚠️ '),
                      TextSpan(text: 'Importante: ', style: textoNegrilla),
                      TextSpan(text: 'La redención '),
                      TextSpan(text: 'no es automática', style: textoNegrilla),
                      TextSpan(text: '. Debe ser solicitada, sustentada con evidencias del trabajo o estudio realizado, y será evaluada por la autoridad correspondiente antes de ser aprobada.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('📌 Fundamento legal actualizado:', style: textoNegrilla),
                const SizedBox(height: 6),
                const Text(
                  '• Artículo 19, Ley 2466 de 2025 (Reforma Laboral)\n'
                      '• Artículo 141, Ley 65 de 1993 (Código Penitenciario y Carcelario)\n'
                      '• Artículo 147, Ley 65 de 1993\n'
                      '• Jurisprudencia de la Corte Suprema de Justicia (Rad. No. 39257)',
                  textAlign: TextAlign.justify,
                  style: textoNormal,
                ),
                const SizedBox(height: 20),

                const Divider(height: 1, color: gris),
                const SizedBox(height: 20),

                const Text('Importancia de la redención de penas', style: TextStyle(color: negro, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 20),

                const Text(
                  'La redención de la pena mediante el trabajo, el estudio o la enseñanza constituye un eje fundamental del proceso de resocialización de las personas privadas de la libertad, '
                      'tal como lo establece el régimen penitenciario colombiano. Su acreditación y reconocimiento no solo representan una reducción efectiva del tiempo de '
                      'condena, sino que también inciden directamente en la elegibilidad para acceder a beneficios administrativos y judiciales tales como el permiso de 72 horas, la '
                      'prisión domiciliaria y la libertad condicional.\n\n'
                      'La ausencia o insuficiencia de actividades redimibles certificadas puede convertirse en un obstáculo para la obtención o aprobación de dichos beneficios, dado que las autoridades competentes evalúan el grado de participación en programas de resocialización como criterio determinante de progreso, disciplina y voluntad de reintegración social.',
                  textAlign: TextAlign.justify,
                  style: textoNormal,
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: gris),
                const SizedBox(height: 20),

                const Text('Solicitar redención de penas', style: TextStyle(color: negro, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 20),

                const Text(
                  'Esta solicitud será enviada a la autoridad penitenciaria y judicial correspondiente para su estudio, validación y eventual aprobación, conforme a los requisitos legales vigentes.',
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
                        content: const Text('¿Estás seguro de que deseas enviar esta solicitud de redención?'),
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
    final double valorRedenciones = (configSnapshot.docs.first.data()['valor_redenciones'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valorRedenciones) {
      await enviarSolicitudRedencion(valorRedenciones); // ✅ Ya no descontamos aquí
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
                      tipoPago: 'redenciones',
                      valor: valorRedenciones.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudRedencion(valorRedenciones); // ✅ Se ejecuta con saldo actualizado
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
      String docId = firestore.collection('redenciones_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

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
