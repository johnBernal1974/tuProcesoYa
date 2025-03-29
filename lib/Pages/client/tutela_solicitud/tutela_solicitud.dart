// ✅ Solicitud de tutela con la misma lógica que derecho de petición

import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tuprocesoya/Pages/client/solicitud_exitosa_tutela/solicitud_exitosa_tutela.dart';
import 'package:tuprocesoya/helper/opciones_menu_tutela_helper.dart';
import 'package:tuprocesoya/helper/preguntas_tutela_helper.dart';
import '../../../commons/main_layaout.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../commons/wompi/pagoExitoso_tutela.dart';
import '../../../src/colors/colors.dart';

class TutelaSolicitudPage extends StatefulWidget {
  const TutelaSolicitudPage({super.key});

  @override
  State<TutelaSolicitudPage> createState() => _TutelaSolicitudPageState();
}

class _TutelaSolicitudPageState extends State<TutelaSolicitudPage> {
  String? selectedCategory;
  String? selectedSubCategory;
  List<TextEditingController> _controllers = [];
  List<PlatformFile> _selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitar Tutela',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tutela - Protección de derechos fundamentales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildDropdowns(),
                  const SizedBox(height: 20),
                  if (selectedCategory != null && selectedSubCategory != null) ...[
                    _buildPreguntasFormulario(),
                    const SizedBox(height: 20),
                    _buildAdjuntarArchivos(),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _validarYEnviarFormulario,
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      child: const Text("Enviar solicitud", style: TextStyle(color: blanco)),
                    ),
                    const SizedBox(height: 50),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdowns() {
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    );

    return Column(
      children: [
        DropdownButtonFormField<String>(
          dropdownColor: blanco,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            enabledBorder: border,
            focusedBorder: border,
          ),
          value: selectedCategory,
          items: MenuOptionsTutelaHelper.obtenerCategorias()
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
              .toList(),
          onChanged: (value) => setState(() {
            selectedCategory = value;
            selectedSubCategory = null;
          }),
        ),
        const SizedBox(height: 15),
        if (selectedCategory != null)
          DropdownButtonFormField<String>(
            dropdownColor: blanco,
            decoration: const InputDecoration(
              labelText: 'Subcategoría',
              enabledBorder: border,
              focusedBorder: border,
            ),
            value: selectedSubCategory,
            items: MenuOptionsTutelaHelper.obtenerSubcategorias(selectedCategory!)
                .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                .toList(),
            onChanged: (value) => setState(() => selectedSubCategory = value),
          ),
      ],
    );
  }


  Widget _buildPreguntasFormulario() {
    final preguntas = PreguntasTutelaHelper.obtenerPreguntas(selectedCategory, selectedSubCategory);
    if (_controllers.length != preguntas.length) {
      _controllers = List.generate(preguntas.length, (_) => TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(preguntas.length, (i) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${i + 1}. ${preguntas[i]}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            textCapitalization: TextCapitalization.sentences,
            controller: _controllers[i],
            minLines: 3,
            maxLines: null,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700, width: 2)),
              hintText: 'Escribe tu respuesta...',
            ),
          ),
          const SizedBox(height: 20),
        ],
      )),
    );
  }


  Widget _buildAdjuntarArchivos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Adjunta documentos que respalden tu solicitud:"),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text("Adjuntar"),
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              setState(() => _selectedFiles.addAll(result.files));
            }
          },
        ),
        ..._selectedFiles.map((file) => ListTile(
          title: Text(file.name),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => _selectedFiles.remove(file)),
          ),
        )),
      ],
    );
  }

  Future<void> _validarYEnviarFormulario() async {
    final respuestas = _controllers.map((c) => c.text.trim()).toList();
    if (respuestas.any((r) => r.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todas las respuestas"), backgroundColor: Colors.red),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final config = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final valor = (config.docs.first.data()['valor_tutela'] ?? 0).toDouble();
    if(context.mounted){
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            esPagoTutela: true,
            valorTutela: valor.toInt(),
            onTransaccionAprobada: () async {
              final confirmar = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: blanco,
                  title: const Text("Ya puedes enviar tu solicitud de tutela"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Enviar solicitud"),
                    ),
                  ],
                ),
              );
              if (confirmar == true) {
                await _enviarSolicitudTutela(respuestas);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _enviarSolicitudTutela(List<String> respuestas) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
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

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final docId = firestore.collection('tutelas_solicitadas').doc().id;
    final numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

    List<String> archivosUrls = [];
    for (final file in _selectedFiles) {
      try {
        final ref = storage.ref('tutelas/$docId/${file.name}');
        final upload = kIsWeb ? ref.putData(file.bytes!) : ref.putFile(File(file.path!));
        final snap = await upload;
        final url = await snap.ref.getDownloadURL();
        archivosUrls.add(url);
      } catch (_) {}
    }

    final preguntas = PreguntasTutelaHelper.obtenerPreguntas(selectedCategory, selectedSubCategory);
    final preguntasRespuestas = List.generate(preguntas.length, (i) => {
      'pregunta': preguntas[i],
      'respuesta': respuestas.length > i ? respuestas[i] : '',
    });

    await firestore.collection('tutelas_solicitadas').doc(docId).set({
      'id': docId,
      'idUser': user.uid,
      'numero_seguimiento': numeroSeguimiento,
      'categoria': selectedCategory,
      'subcategoria': selectedSubCategory,
      'preguntas_respuestas': preguntasRespuestas,
      'archivos': archivosUrls,
      'fecha': FieldValue.serverTimestamp(),
      'status': 'Solicitado',
      'asignadoA': '',
    });

    final userDoc = await firestore.collection('Ppl').doc(user.uid).get();
    final saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();
    final config = await firestore.collection('configuraciones').limit(1).get();
    final valor = (config.docs.first.data()['valor_tutela'] ?? 0).toDouble();
    await firestore.collection('Ppl').doc(user.uid).update({'saldo': saldo - valor});

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SolicitudExitosaTutelaPage(numeroSeguimiento: numeroSeguimiento)),
      );
    }
  }
}
