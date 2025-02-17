
import 'dart:math';
import 'dart:io'; // Necesario para manejar archivos en almacenamiento local

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tuprocesoya/Pages/client/solicitud_exitosa_derecho_peticion_page/solicitud_exitosa_derecho_peticion_page.dart';
import 'package:tuprocesoya/commons/opciones_menu_derecho_peticion_helper.dart';
import 'package:tuprocesoya/commons/preguntasDerechoPeticionHelper.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class DerechoDePeticionSolicitudPage extends StatefulWidget {
  const DerechoDePeticionSolicitudPage({super.key});

  @override
  State<DerechoDePeticionSolicitudPage> createState() => _DerechoDePeticionSolicitudPageState();
}

class _DerechoDePeticionSolicitudPageState extends State<DerechoDePeticionSolicitudPage> {
  final _textController = TextEditingController();
  String _hintCategory = 'Seleccione una categoría';
  String _hintSubCategory = 'Seleccione una subcategoría';
  List<String> categorias = MenuOptionsDerechoPeticionHelper.obtenerCategorias();
  String? selectedCategory;
  String? selectedSubCategory;
  List<PlatformFile> _selectedFiles = [];
  List<String> archivosUrls = [];
  List<String> preguntas = [];
  List<TextEditingController> _controllers = [];




  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitud de servicio',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Derecho de Petición', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                const Text(
                  'Selecciona el tema sobre el cual quieres realizar el derecho de petición',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1),
                ),
                const SizedBox(height: 25),
                _buildDropdownMenus(), // Sección de Dropdowns

                const SizedBox(height: 10),
                const Divider(height: 1, color: grisMedio),
                const SizedBox(height: 10),

                // Solo se muestra si ambas opciones están seleccionadas
                if (selectedCategory != null && selectedSubCategory != null) _buildInstructionsAndInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pickFiles() async {
    try {
      // Permitir selección múltiple de archivos
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true, // Permitir selección múltiple
      );

      if (result != null) {
        print("Número de archivos seleccionados: ${result.files.length}");

        setState(() {
          // Agregar los archivos seleccionados a la lista existente
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      print("Error al seleccionar archivos: $e");
    }
  }

  Widget adjuntarDocumento() {
    return Column(
      children: [
        const SizedBox(height: 15),
        const Text("Si cuentas con documentos que puedan respaldar tu solicitud por favor adjuntalos"),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: pickFiles,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.attach_file, color: primary, size: 18),
              SizedBox(width: 8),
              Text(
                "Adjuntar documentos",
                style: TextStyle(
                  color: primary,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            alignment: Alignment.topLeft,
            child: const Text(
              "Archivos seleccionados:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: blanco,
                          title: const Text("Eliminar archivo"),
                          content: Text(
                            "¿Estás seguro de que deseas eliminar ${_selectedFiles[index].name}?",
                          ),
                          actions: [
                            TextButton(
                              child: const Text("Cancelar"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Eliminar"),
                              onPressed: () {
                                setState(() {
                                  _selectedFiles.removeAt(index);
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                title: Text(
                  _selectedFiles[index].name,
                  style: const TextStyle(fontSize: 12, height: 1.2),
                  textAlign: TextAlign.left,
                ),
              );
            },
          )
        ],
      ],
    );
  }

  Widget _buildDropdownMenus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menú principal
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            dropdownColor: Colors.amber.shade50,
            decoration: _inputDecoration(_hintCategory),
            value: selectedCategory,
            items: MenuOptionsDerechoPeticionHelper.obtenerCategorias().map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedCategory = value;
                _hintCategory = 'Categoría seleccionada';
                selectedSubCategory = null; // Resetea subcategoría
              });
            },
          ),
        ),

        const SizedBox(height: 15),

        // Menú secundario (Solo se muestra si hay una categoría seleccionada)
        if (selectedCategory != null)
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              decoration: _inputDecoration(_hintSubCategory),
              dropdownColor: Colors.amber.shade50,
              isExpanded: true,
              value: selectedSubCategory,
              items: MenuOptionsDerechoPeticionHelper.obtenerSubcategorias(selectedCategory!).map((String subCategory) {
                return DropdownMenuItem<String>(
                  value: subCategory,
                  child: Text(subCategory),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubCategory = value;
                  _hintSubCategory = 'Subcategoría seleccionada';
                });
              },
            ),
          ),

        const SizedBox(height: 10),

        // Mostrar selección final
        if (selectedCategory != null && selectedSubCategory != null)
          Text(
            "Seleccionaste:\n$selectedCategory → $selectedSubCategory",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  /// Método que construye las instrucciones, inputs y botón según la categoría y subcategoría seleccionada.
  Widget _buildInstructionsAndInput() {
    List<String> preguntas = PreguntasDerechoPeticionHelper.obtenerPreguntasPorCategoriaYSubcategoria(
        selectedCategory,
        selectedSubCategory);

    // Verificar si los controladores ya están creados y tienen el mismo tamaño
    if (_controllers.length != preguntas.length) {
      _controllers = List.generate(preguntas.length, (index) => TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        const Text(
          'INSTRUCCIONES',
          style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 25),

        const Text(
          "Para facilitar la comprensión y garantizar la precisión, por favor proporciona "
              "respuestas claras, concisas, detalladas y veraces a cada una de las siguientes preguntas:",
          style: TextStyle(fontSize: 14),
        ),

        const SizedBox(height: 15),

        // Sección de preguntas y respuestas
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: preguntas.length,
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pregunta ${index + 1}: ${preguntas[index]}", // Muestra la pregunta
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _controllers[index],
                  maxLines: 10,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                    hintText: 'Escribe tu respuesta aquí...',
                  ),
                ),
                const SizedBox(height: 15),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        adjuntarDocumento(),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () {
            mostrarInformacion();
            _guardarSolicitudConValoresActualizados();
          },
          child: const Text(
            "Enviar solicitud",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  /// Método para reutilizar el estilo de los inputs.
  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  void mostrarInformacion() {
    print("Categoría seleccionada: ${selectedCategory}");
    print("Subcategoría seleccionada: ${selectedSubCategory}");
    print("Texto ingresado: $_textController");
    print("Archivos seleccionados: ${_selectedFiles.join(', ')}");
  }

  void _guardarSolicitudConValoresActualizados() {
    // Actualizar manualmente los valores de los controladores
    List<String> respuestas = _controllers.map((c) => c.text.trim()).toList();

    // Verificar si hay respuestas vacías
    if (respuestas.any((respuesta) => respuesta.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Hay respuestas vacías. Por favor, completa todos los campos."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    guardarSolicitud(respuestas);
  }

  Future<void> guardarSolicitud(List<String> respuestas) async {
    if (selectedCategory == null || selectedSubCategory == null) {
      print("❌ Categoría o subcategoría no seleccionadas.");
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No hay usuario autenticado.");
      return;
    }

    bool confirmarEnvio = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Confirmar envío"),
        content: const Text("Antes de enviar tu solicitud, asegúrate de haber "
            "proporcionado toda la información necesaria y veraz. La precisión "
            "y detalle en la información son clave para una diligencia eficiente. "
            "Si necesitas revisar o agregar algo, por favor hazlo antes de enviar."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Revisar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Enviar solicitud"),
          ),
        ],
      ),
    );

    if (!confirmarEnvio) return;

    String idUser = user.uid;
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
              Text("Subiendo información, por favor espera..."),
            ],
          ),
        ),
      );
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      FirebaseStorage storage = FirebaseStorage.instance;

      String docId = firestore.collection('derechos_peticion_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();
      List<String> archivosUrls = [];

      // Guardar archivos en Firebase Storage
      for (PlatformFile file in _selectedFiles) {
        try {
          String filePath = 'derechos_peticion/$docId/${file.name}';
          Reference storageRef = storage.ref(filePath);

          UploadTask uploadTask;
          String ext = file.name.split('.').last.toLowerCase();
          String contentType = (ext == "jpg" || ext == "jpeg")
              ? "image/jpeg"
              : (ext == "png")
              ? "image/png"
              : (ext == "pdf")
              ? "application/pdf"
              : "application/octet-stream";

          if (kIsWeb) {
            uploadTask = storageRef.putData(file.bytes!, SettableMetadata(contentType: contentType));
          } else {
            File fileToUpload = File(file.path!);
            uploadTask = storageRef.putFile(fileToUpload, SettableMetadata(contentType: contentType));
          }

          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          archivosUrls.add(downloadUrl);
        } catch (e) {
          print("Error al subir el archivo ${file.name}: $e");
        }
      }

      // Obtener preguntas basadas en la categoría y subcategoría
      List<String> preguntas = PreguntasDerechoPeticionHelper.obtenerPreguntasPorCategoriaYSubcategoria(
        selectedCategory,
        selectedSubCategory,
      );

      // Emparejar preguntas y respuestas en una lista de mapas
      List<Map<String, String>> preguntasRespuestas = [];
      for (int i = 0; i < preguntas.length; i++) {
        preguntasRespuestas.add({
          "pregunta": preguntas[i],
          "respuesta": respuestas.length > i ? respuestas[i] : "",
        });
      }

      // Guardar datos en Firestore
      await firestore.collection('derechos_peticion_solicitados').doc(docId).set({
        "id": docId,
        "idUser": idUser,
        "numero_seguimiento": numeroSeguimiento,
        "categoria": selectedCategory,
        "subcategoria": selectedSubCategory,
        "preguntas_respuestas": preguntasRespuestas,
        "archivos": archivosUrls,
        "fecha": FieldValue.serverTimestamp(),
        "status": "solicitado"
      });

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaDerechoPeticionPage(numeroSeguimiento: numeroSeguimiento),
          ),
        );
      }

      print("✅ Solicitud guardada con éxito.");
    } catch (e) {
      print("❌ Error al guardar la solicitud: $e");

      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Hubo un problema al guardar la solicitud. Por favor, intenta nuevamente."),
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


}
