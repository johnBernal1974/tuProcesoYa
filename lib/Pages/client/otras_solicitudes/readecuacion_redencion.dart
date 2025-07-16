import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_readecuacion/solicitud_exitosa_readecuacion.dart';

class SolicitudReadecuacionRedencionPage extends StatefulWidget {
  const SolicitudReadecuacionRedencionPage({Key? key}) : super(key: key);

  @override
  State<SolicitudReadecuacionRedencionPage> createState() => _SolicitudReadecuacionRedencionPageState();
}

class _SolicitudReadecuacionRedencionPageState extends State<SolicitudReadecuacionRedencionPage> {
  @override
  Widget build(BuildContext context) {
    const TextStyle textoNormal = TextStyle(fontSize: 14, height: 1.5, color: Colors.black);
    const TextStyle textoNegrilla = TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.bold, color: Colors.black);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Solicitud Readecuación Redención', style: TextStyle(color: Colors.white)),
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
                    '📘 Redención de pena y aplicación del Artículo 19 de la Reforma Laboral',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'La redención de pena es un mecanismo legal mediante el cual las personas privadas de la libertad pueden reducir su condena a través de trabajo certificado. Este proceso forma parte integral del camino hacia la resocialización y reintegración social.',
                    textAlign: TextAlign.justify,
                    style: textoNormal,
                  ),
                  const SizedBox(height: 10),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: const TextSpan(
                      style: textoNormal,
                      children: [
                        TextSpan(text: 'Con la entrada en vigor del '),
                        TextSpan(text: 'Artículo 19 de la Ley 2466 de 2025', style: textoNegrilla),
                        TextSpan(text: ', como parte de la Reforma Laboral en Colombia, se introdujo un nuevo esquema más favorable para las redenciones: por cada '),
                        TextSpan(text: 'tres (3) días de trabajo', style: textoNegrilla),
                        TextSpan(text: ', se redimen '),
                        TextSpan(text: 'dos (2) días de pena', style: textoNegrilla),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  RichText(
                    textAlign: TextAlign.justify,
                    text: const TextSpan(
                      style: textoNormal,
                      children: [
                        TextSpan(text: 'Además, esta norma reconoce estas actividades como '),
                        TextSpan(text: 'experiencia laboral válida', style: textoNegrilla),
                        TextSpan(text: ', siempre que sean certificadas por el INPEC o las autoridades penitenciarias. Esto potencia las oportunidades de reintegración laboral al recuperar la libertad.'),
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
                        TextSpan(text: 'Este nuevo esquema de redención '),
                        TextSpan(text: 'no se aplica automáticamente', style: textoNegrilla),
                        TextSpan(text: '. Para que sea reconocido y aplicado por las autoridades judiciales, es necesario solicitarlo formalmente al juzgado que esté conociendo el caso, argumentando el principio de '),
                        TextSpan(text: 'favorabilidad penal', style: textoNegrilla),
                        TextSpan(text: ', contemplado en el artículo 29 de la Constitución Política.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('📌 Fundamento legal actualizado:', style: textoNegrilla),
                  const SizedBox(height: 6),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• Artículo 19, Ley 2466 de 2025 (Reforma Laboral)',
                        textAlign: TextAlign.justify,
                        style: textoNormal,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• Artículo 141, Ley 65 de 1993 (Código Penitenciario y Carcelario)',
                        textAlign: TextAlign.justify,
                        style: textoNormal,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• Artículo 147, Ley 65 de 1993',
                        textAlign: TextAlign.justify,
                        style: textoNormal,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• Artículo 29, Constitución Política de Colombia (principio de favorabilidad)',
                        textAlign: TextAlign.justify,
                        style: textoNormal,
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• Jurisprudencia de la Corte Suprema de Justicia (Rad. No. 39257)',
                        textAlign: TextAlign.justify,
                        style: textoNormal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(height: 1, color: gris),
                  const SizedBox(height: 20),

                  const Text(
                    'Solicitar aplicación del Artículo 19 por favorabilidad',
                    style: TextStyle(color: negro, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Se invita a la persona privada de la libertad a solicitar formalmente ante el juzgado la aplicación del nuevo esquema de redención previsto en la Ley 2466 de 2025.',
                    textAlign: TextAlign.justify,
                    style: textoNormal,
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    '📊 Ejemplo práctico de redención de pena:',
                    style: textoNegrilla,
                  ),
                  const SizedBox(height: 6),
                  Table(
                    border: TableBorder.all(color: Colors.grey),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade300),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Días de trabajo', style: textoNegrilla, textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Redención anterior (Ley 65/93)', style: textoNegrilla, textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Redención actual (Ley 2466/25)', style: textoNegrilla, textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                      const TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('30 días'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('15 días redimidos'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('20 días redimidos'),
                        ),
                      ]),
                      const TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('60 días'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('30 días redimidos'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('40 días redimidos'),
                        ),
                      ]),
                      const TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('90 días'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('45 días redimidos'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('60 días redimidos'),
                        ),
                      ]),
                      const TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('180 días'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('90 días redimidos'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('120 días redimidos'),
                        ),
                      ]),
                      const TableRow(children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('360 días'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('180 días redimidos'),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('240 días redimidos'),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '🧑‍⚖️ ¿Qué debe hacer el juez?',
                    style: TextStyle(color: negro, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'El juez de ejecución de penas y medidas de seguridad, al momento de estudiar una solicitud de redención de pena, debe aplicar el principio de favorabilidad penal. '
                        'Esto significa que, si una persona privada de la libertad acumuló días de trabajo bajo el antiguo esquema (Ley 65 de 1993), el juez debe evaluar si aplicar el nuevo beneficio establecido en el Artículo 19 de la Ley 2466 de 2025 resulta más favorable.',
                    textAlign: TextAlign.justify,
                    style: textoNormal,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'En estos casos, el juez puede recalcular la redención con base en el nuevo sistema (3x2), lo cual puede aumentar significativamente los días redimidos. Esta revisión no ocurre de forma automática, '
                        'por lo que es fundamental que la persona privada de la libertad o su acudiente soliciten expresamente la aplicación del nuevo esquema legal de redención.',
                    textAlign: TextAlign.justify,
                    style: textoNormal,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '⚖️ El principio de favorabilidad está consagrado en el artículo 29 de la Constitución Política y en el artículo 6º del Código Penal, y exige que siempre se aplique la norma más benigna al condenado. '
                        'Por tanto, el juez tiene la obligación de preferir la nueva ley si esta genera un mayor beneficio para el solicitante.',
                    textAlign: TextAlign.justify,
                    style: textoNormal,
                  ),
                  const SizedBox(height: 20),

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
                          content: const Text('¿Estás seguro de que deseas solicitar la aplicación del Artículo 19 de la ley 2466 de 2025, por favorabilidad para la redención de penas?'),
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
                        await verificarSaldoYEnviarSolicitud(); // Llama a tu función de envío
                      }
                    },
                    child: const Text('Solicitar ahora', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        )

    );
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorReadecuacion = (configSnapshot.docs.first.data()['valor_readecuacion'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valorReadecuacion) {
      await enviarSolicitudReadecuacion(valorReadecuacion); // ✅ Ya no descontamos aquí
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
                      tipoPago: 'readecuacion',
                      valor: valorReadecuacion.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudReadecuacion(valorReadecuacion); // ✅ Se ejecuta con saldo actualizado
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

  Future<void> enviarSolicitudReadecuacion(double valor) async {
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
      String docId = firestore.collection('readecuacion_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      await firestore.collection('readecuacion_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
      });

      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Solicitd readecuacion",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "readecuacion_solicitados",
        fecha: Timestamp.now(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaReadecuacionRedencionPage(
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
