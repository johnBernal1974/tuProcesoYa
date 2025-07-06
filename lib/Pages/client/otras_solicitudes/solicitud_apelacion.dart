import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../commons/archivo _uplouder.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_acumulacion/solicitud_exitosa_acumulacion.dart';
import '../solicitud_exitosa_apelacion/solicitud_exitosa_apelacion.dart';

class SolicitudApelacionPage extends StatefulWidget {
  const SolicitudApelacionPage({super.key});

  @override
  State<SolicitudApelacionPage> createState() => _SolicitudApelacionPageState();
}

class _SolicitudApelacionPageState extends State<SolicitudApelacionPage> {
  String? archivoDecision;
  String? urlArchivoDecision;
  String? docIdSolicitud;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud de Apelación', style: TextStyle(color: blanco)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                const Text(
                  'Presenta tu apelación de manera fácil y segura',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 10),
                const Text(
                  'La apelación es un recurso legal mediante el cual puedes solicitar que un juez de segunda instancia revise una decisión judicial que consideras injusta. '
                      'Este proceso permite impugnar la sentencia o auto dentro de los términos legales, buscando su modificación o revocatoria.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
                const Divider(color: negroLetras),
                const SizedBox(height: 24),
                const Text(
                  'Sube el documento de la decisión que deseas apelar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: pickArchivoDecision,
                  child: Row(
                    children: [
                      Icon(
                        archivoDecision != null ? Icons.check_circle : Icons.upload_file,
                        color: archivoDecision != null ? Colors.green : Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoDecision ?? 'Subir archivo',
                          style: TextStyle(
                            color: archivoDecision != null ? Colors.black : Colors.deepPurple,
                            decoration: archivoDecision != null ? TextDecoration.none : TextDecoration.underline,
                          ),
                        ),
                      ),
                      if (archivoDecision != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => eliminarArchivoDecision(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                  ),
                  onPressed: () async {
                    if (archivoDecision == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Por favor, sube el documento de la decisión que deseas apelar."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final confirmado = await mostrarConfirmacionEnvio();
                    if (confirmado) {
                      await verificarSaldoYEnviarSolicitud();
                    }
                  },
                  child: const Text(
                    'Enviar solicitud',
                    style: TextStyle(color: blanco),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void eliminarArchivoDecision() {
    setState(() {
      archivoDecision = null;
      urlArchivoDecision = null;
    });
  }

  Future<void> pickArchivoDecision() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        setState(() {
          archivoDecision = file.name;
        });

        docIdSolicitud ??= FirebaseFirestore.instance.collection('apelacion_solicitados').doc().id;
        String path = 'apelaciones/$docIdSolicitud/${file.name}';

        String? downloadUrl = await ArchivoUploader.subirArchivo(
          file: file,
          rutaDestino: path,
        );

        if (downloadUrl != null) {
          setState(() {
            urlArchivoDecision = downloadUrl;
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Archivo subido exitosamente."),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No se pudo subir el archivo, intenta nuevamente."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al seleccionar archivo: $e");
      }
    }
  }

  Future<bool> mostrarConfirmacionEnvio() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Confirmar envío"),
        content: const Text("¿Estás seguro de enviar la solicitud de apelación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmar", style: TextStyle(color: blanco)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valor = (configSnapshot.docs.first.data()['valor_apelacion'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valor) {
      await FirebaseFirestore.instance.collection('Ppl').doc(uid).update({
        'saldo': saldo - valor,
      });

      await enviarSolicitudApelacion(valor);
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
                      tipoPago: 'apelacion',
                      valor: valor.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudApelacion(valor);
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

  Future<void> enviarSolicitudApelacion(double valor) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: blanco,
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
      final String docId = docIdSolicitud ??= firestore.collection('apelacion_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      await firestore.collection('apelacion_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
        'archivo_decision': urlArchivoDecision,
      });

      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Apelación",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "apelacion_solicitados",
        fecha: Timestamp.now(),
      );

      await descontarSaldo(valor);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SolicitudExitosaApelacionPage(numeroSeguimiento: numeroSeguimiento),
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
