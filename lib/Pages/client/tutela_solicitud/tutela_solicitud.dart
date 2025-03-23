// 📄 Página de solicitud de tutela para personas privadas de la libertad
// Versión adaptada del derecho de petición con preguntas dinámicas

import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import '../../../helper/opciones_menu_tutela_helper.dart';
import '../../../helper/preguntas_tutela_helper.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_tutela/solicitud_exitosa_tutela.dart';

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
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tutela - Protección de derechos fundamentales',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  const Text(
                    'Selecciona el derecho que consideras vulnerado como persona privada de la libertad:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  _buildDropdowns(),
                  const SizedBox(height: 20),
                  if (selectedCategory != null && selectedSubCategory != null) ...[
                    _buildFormularioPreguntas(),
                    const SizedBox(height: 20),
                    _buildAdjuntarArchivos(),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      onPressed: _validarYEnviarFormulario,
                      child: const Text("Enviar solicitud", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 80),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _validarYEnviarFormulario() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final respuestas = _controllers.map((c) => c.text.trim()).toList();

    if (respuestas.any((r) => r.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Hay respuestas vacías. Por favor completa todos los campos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Subiendo solicitud..."),
          ],
        ),
      ),
    );

    try {
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;
      final docId = firestore.collection('tutelas_solicitadas').doc().id;
      final numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      final preguntas = PreguntasTutelaHelper.obtenerPreguntas(selectedCategory, selectedSubCategory);
      final preguntasRespuestas = List.generate(preguntas.length, (i) => {
        "pregunta": preguntas[i],
        "respuesta": respuestas[i],
      });

      // 📂 Subir archivos
      // 📂 Subir archivos para Web
      List<String> archivosUrls = [];

      for (PlatformFile file in _selectedFiles) {
        try {
          if (file.bytes == null) continue;

          final ref = storage.ref().child('tutelas/$docId/${file.name}');
          final uploadTask = ref.putData(file.bytes!);
          final snapshot = await uploadTask;
          final url = await snapshot.ref.getDownloadURL();

          archivosUrls.add(url);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("❌ Error subiendo archivo: ${file.name}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      // 📝 Guardar en Firestore
      await firestore.collection('tutelas_solicitadas').doc(docId).set({
        "id": docId,
        "idUser": user.uid,
        "numero_seguimiento": numeroSeguimiento,
        "categoria": selectedCategory,
        "subcategoria": selectedSubCategory,
        "preguntas_respuestas": preguntasRespuestas,
        "archivos": archivosUrls,
        "fecha": FieldValue.serverTimestamp(),
        "status": "Solicitado",
      });

      if (mounted) {
        Navigator.pop(context); // ✅ Cierra el modal de carga correctamente

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SolicitudExitosaTutelaPage(numeroSeguimiento: numeroSeguimiento),
          ),
        );

        // 🧹 Limpiar formulario
        setState(() {
          selectedCategory = null;
          selectedSubCategory = null;
          _controllers.clear();
          _selectedFiles.clear();
        });
      }


    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Error al guardar la solicitud."), backgroundColor: Colors.red),
        );
      }
    }
  }


  Widget _buildDropdowns() {
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          dropdownColor: blanco,
          decoration: const InputDecoration(
            labelText: 'Categoría',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 2),
            ),
          ),
          value: selectedCategory,
          style: const TextStyle(fontWeight: FontWeight.bold),
          items: MenuOptionsTutelaHelper.obtenerCategorias().map((categoria) {
            return DropdownMenuItem(value: categoria, child: Text(categoria));
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCategory = value;
              selectedSubCategory = null;
            });
          },
        ),
        const SizedBox(height: 15),
        if (selectedCategory != null)
          DropdownButtonFormField<String>(
            dropdownColor: blanco,
            decoration: const InputDecoration(
              labelText: 'Subcategoría',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 2),
              ),
            ),
            value: selectedSubCategory,
            style: const TextStyle(fontWeight: FontWeight.bold),
            items: MenuOptionsTutelaHelper.obtenerSubcategorias(selectedCategory!).map((sub) {
              return DropdownMenuItem(value: sub, child: Text(sub));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedSubCategory = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildFormularioPreguntas() {
    final preguntas = PreguntasTutelaHelper.obtenerPreguntas(selectedCategory, selectedSubCategory);
    if (_controllers.length != preguntas.length) {
      _controllers = List.generate(preguntas.length, (_) => TextEditingController());
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        const Text(
          "Responde las siguientes preguntas para ayudarnos a entender mejor tu situación:",
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: preguntas.length,
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${index + 1}. ${preguntas[index]}",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _controllers[index],
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "Escribe tu respuesta...",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade700, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdjuntarArchivos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Adjunta documentos que respalden la solicitud de tutela:"),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              setState(() {
                _selectedFiles.addAll(result.files);
              });
            }
          },
          child: const Row(
            children: [
              Icon(Icons.attach_file, color: primary),
              SizedBox(width: 8),
              Text("Adjuntar archivos", style: TextStyle(color: primary, decoration: TextDecoration.underline)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ..._selectedFiles.map((file) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(file.name, style: const TextStyle(fontSize: 13)),
          trailing: IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () {
              setState(() {
                _selectedFiles.remove(file);
              });
            },
          ),
        )),
      ],
    );
  }
}
