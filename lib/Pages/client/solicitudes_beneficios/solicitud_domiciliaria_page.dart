
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../commons/drop_depatamentos_municipios.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_domiciliaria/solicitud_exitosa_domiciliaria.dart';

class SolicitudDomiciliariaPage extends StatefulWidget {
  const SolicitudDomiciliariaPage({super.key});

  @override
  State<SolicitudDomiciliariaPage> createState() => _SolicitudDomiciliariaPageState();
}

class _SolicitudDomiciliariaPageState extends State<SolicitudDomiciliariaPage> {
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nombreResponsableController = TextEditingController();
  final TextEditingController _cedulaResponsableController = TextEditingController();
  final TextEditingController _celularResponsableController = TextEditingController();

  String? archivoRecibo;
  String? archivoDeclaracion;
  String? urlArchivoRecibo;
  String? urlArchivoDeclaracion;
  String? departamentoSeleccionado;
  String? municipioSeleccionado;

  List<PlatformFile> _selectedFiles = [];
  List<String> archivosUrls = [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
          title: const Text('Nueva Solicitud', style: TextStyle(color: blanco)),
      backgroundColor: primary),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              children: [
                const Text(
                  'Solicitud de Prisión Domiciliaria',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'La prisión domiciliaria es un beneficio que permite al PPL cumplir su condena en un lugar de residencia previamente aprobado, cuando se cumplen ciertos requisitos legales y humanitarios.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Es necesario suministrar información veraz y completa, así como subir los documentos requeridos para la evaluación de la solicitud.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text('1. Dirección exacta del domicilio donde estará el PPL:', style: TextStyle(
                  fontWeight: FontWeight.bold
                ),),
                const SizedBox(height: 8),
                TextField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección completa',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // ✅ Widget de selección de Departamento y Municipio
                DepartamentosMunicipiosWidget(
                  departamentoSeleccionado: departamentoSeleccionado,
                  municipioSeleccionado: municipioSeleccionado,
                  onSelectionChanged: (String departamento, String municipio) {
                    setState(() {
                      departamentoSeleccionado = departamento;
                      municipioSeleccionado = municipio;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text(
                  '2. Sube un recibo de servicios públicos del domicilio ingresado:', style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('recibo'),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        archivoRecibo ?? 'Subir archivo',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text(
                  '3. Sube la declaración extra juicio para la solicitud de prisión domiciliaria:', style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('declaracion'),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        archivoDeclaracion ?? 'Subir archivo',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text('4. Datos de la persona responsable del PPL en el domicilio:' , style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 10),
                TextField(
                  controller: _nombreResponsableController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo del responsable',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                TextField(
                  controller: _cedulaResponsableController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de Cédula',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                TextField(
                  controller: _celularResponsableController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de Celular',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary
                  ),
                  onPressed: validarYEnviar,
                  child: const Text('Enviar solicitud', style: TextStyle(
                    color: blanco
                  )),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> pickSingleFile(String tipo) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        setState(() {
          if (tipo == 'recibo') {
            archivoRecibo = file.name;
          } else if (tipo == 'declaracion') {
            archivoDeclaracion = file.name;
          }
        });

        String docId = FirebaseFirestore.instance.collection('solicitudes_prision_domiciliaria').doc().id;
        String path = 'solicitudes_prision_domiciliaria/$docId/${file.name}';

        Reference storageRef = FirebaseStorage.instance.ref(path);
        UploadTask uploadTask = kIsWeb ? storageRef.putData(file.bytes!) : storageRef.putFile(File(file.path!));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          if (tipo == 'recibo') {
            urlArchivoRecibo = downloadUrl;
          } else if (tipo == 'declaracion') {
            urlArchivoDeclaracion = downloadUrl;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al seleccionar archivo: $e");
      }
    }
  }

  void validarYEnviar() async {
    if (_direccionController.text.trim().isEmpty ||
        departamentoSeleccionado == null ||
        municipioSeleccionado == null ||
        archivoRecibo == null ||
        archivoDeclaracion == null ||
        _nombreResponsableController.text.trim().isEmpty ||
        _cedulaResponsableController.text.trim().isEmpty ||
        _celularResponsableController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos y sube los documentos requeridos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await verificarSaldoYEnviarSolicitud();
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorDomiciliaria = (configSnapshot.docs.first.data()['valor_domiciliaria'] ?? 0).toDouble();

    if (saldo < valorDomiciliaria) {
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
                      tipoPago: 'domiciliaria',
                      valor: valorDomiciliaria.toInt(),
                      onTransaccionAprobada: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final userRef = FirebaseFirestore.instance.collection('Ppl').doc(user.uid);
                        final userDoc = await userRef.get();
                        final double saldoActual = (userDoc.data()?['saldo'] ?? 0).toDouble();

                        final nuevoSaldo = saldoActual - valorDomiciliaria;
                        await userRef.update({'saldo': nuevoSaldo});

                        await enviarSolicitudPrisionDomiciliaria();
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
      return;
    }

    await enviarSolicitudPrisionDomiciliaria();
  }

  Future<void> enviarSolicitudPrisionDomiciliaria() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorDomiciliaria = (configSnapshot.docs.first.data()['valor_domiciliaria'] ?? 0).toDouble();

    if (!context.mounted) return;

    bool confirmarEnvio = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Confirmar envío"),
        content: const Text("¿Deseas enviar esta solicitud de prisión domiciliaria?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Enviar")),
        ],
      ),
    );

    if (!confirmarEnvio) return;

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
              Text("Subiendo información..."),
            ],
          ),
        ),
      );
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String docId = firestore.collection('solicitudes_prision_domiciliaria').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      List<String> urls = [];

      for (PlatformFile file in _selectedFiles) {
        try {
          String filePath = 'solicitudes_prision_domiciliaria/$docId/${file.name}';
          Reference storageRef = FirebaseStorage.instance.ref(filePath);
          UploadTask uploadTask = kIsWeb ? storageRef.putData(file.bytes!) : storageRef.putFile(File(file.path!));
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          archivosUrls.add(downloadUrl);
        } catch (_) {}
      }

      await firestore.collection('solicitudes_prision_domiciliaria').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'direccion': _direccionController.text.trim(),
        'departamento': departamentoSeleccionado,
        'municipio': municipioSeleccionado,
        'archivo_recibo': urlArchivoRecibo,
        'archivo_declaracion': urlArchivoDeclaracion,
        'nombre_responsable': _nombreResponsableController.text.trim(),
        'cedula_responsable': _cedulaResponsableController.text.trim(),
        'celular_responsable': _celularResponsableController.text.trim(),
        'archivos_adicionales': archivosUrls,
        'fecha': FieldValue.serverTimestamp(),
        'estado': 'Solicitado',
      });

      await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).update({
        'saldo': saldo - valorDomiciliaria,
      });

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaDomiciliariaPage(numeroSeguimiento: numeroSeguimiento),
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

}
