
import 'dart:math';
import 'dart:io'; // Necesario para manejar archivos en almacenamiento local

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:tuprocesoya/Pages/client/solicitud_exitosa_tutela/solicitud_exitosa_tutela.dart';
import '../../../commons/main_layaout.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../helper/opciones_menu_tutela_helper.dart';
import '../../../helper/preguntas_tutela_helper.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';

class TutelaSolicitudPage extends StatefulWidget {
  const TutelaSolicitudPage({super.key});

  @override
  State<TutelaSolicitudPage> createState() => _TutelaSolicitudPageState();
}

class _TutelaSolicitudPageState extends State<TutelaSolicitudPage> {
  String _hintCategory = 'Seleccione una categoría';
  String _hintSubCategory = 'Seleccione una subcategoría';
  List<String> categorias = MenuOptionsTutelaHelper.obtenerCategorias();
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
                const Text('Tutela', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                const Text(
                  'Selecciona el tema sobre el cual quieres realizar la tutela',
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
        setState(() {
          // Agregar los archivos seleccionados a la lista existente
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al seleccionar archivos: $e");
      }
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
            items: MenuOptionsTutelaHelper.obtenerCategorias().map((String category) {
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
              items: MenuOptionsTutelaHelper.obtenerSubcategorias(selectedCategory!).map((String subCategory) {
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
    List<String> preguntas = PreguntasTutelaHelper.obtenerPreguntas(
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
                  textCapitalization: TextCapitalization.sentences,
                  controller: _controllers[index],
                  minLines: 2, // 👈 Se añade esto
                  maxLines: null, // 👈 Esto permite que crezca dinámicamente
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
          style: ElevatedButton.styleFrom(backgroundColor: primary),
          onPressed: () {
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

    verificarSaldoYEnviarSolicitud(respuestas);
  }

  Future<void> verificarSaldoYEnviarSolicitud(List<String> respuestas) async {
    final configSnapshot = await FirebaseFirestore.instance
        .collection('configuraciones')
        .limit(1)
        .get();

    final double valorTutela =
    (configSnapshot.docs.first.data()['valor_tutela'] ?? 0).toDouble();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (!context.mounted) return;

    if (saldo >= valorTutela) {
      // ✅ Tiene saldo suficiente: descontar y enviar directamente
      await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).update({
        'saldo': saldo - valorTutela,
      });
      await enviarSolicitudTutela(respuestas, valorTutela);
    } else {
      // ❌ No tiene saldo: mostrar diálogo y enviar al checkout
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: blanco,
          title: const Text("Pago requerido"),
          content: const Text("No tienes saldo suficiente. ¿Deseas realizar el pago para enviar tu solicitud?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // cerrar el diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(
                      tipoPago: 'tutela',
                      valor: valorTutela.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudTutela(respuestas, valorTutela);
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

  Future<void> enviarSolicitudTutela(List<String> respuestas, double valorTutela) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!context.mounted) return;

    bool confirmarEnvio = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Ya puedes enviar tu solicitud de tutela"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Enviar solicitud")),
        ],
      ),
    );

    if (!confirmarEnvio) return;

    if (context.mounted) {
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
      FirebaseStorage storage = FirebaseStorage.instance;

      String docId = firestore.collection('tutelas_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();
      List<String> archivosUrls = [];

      // 🔍 Obtener nombre y apellido del PPL
      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      for (PlatformFile file in _selectedFiles) {
        try {
          String filePath = 'tutelas/$docId/archivos/${file.name}';
          Reference storageRef = storage.ref(filePath);
          UploadTask uploadTask = kIsWeb
              ? storageRef.putData(file.bytes!)
              : storageRef.putFile(File(file.path!));
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          archivosUrls.add(downloadUrl);
        } catch (_) {}
      }

      List<String> preguntas = PreguntasTutelaHelper.obtenerPreguntas(
        selectedCategory,
        selectedSubCategory,
      );

      List<Map<String, String>> preguntasRespuestas = [];
      for (int i = 0; i < preguntas.length; i++) {
        preguntasRespuestas.add({
          "pregunta": preguntas[i],
          "respuesta": respuestas.length > i ? respuestas[i] : "",
        });
      }

      await firestore.collection('tutelas_solicitados').doc(docId).set({
        "id": docId,
        "idUser": user.uid,
        "numero_seguimiento": numeroSeguimiento,
        "categoria": selectedCategory,
        "subcategoria": selectedSubCategory,
        "preguntas_respuestas": preguntasRespuestas,
        "archivos": archivosUrls,
        "fecha": FieldValue.serverTimestamp(),
        "status": "Solicitado",
        "asignadoA": "",
      });
      // 👉 Guardar resumen
      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Tutela",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "tutelas_solicitados",
        fecha: Timestamp.now(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SolicitudExitosaTutelaPage(numeroSeguimiento: numeroSeguimiento),
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

      // 🔒 Solo descontar si hay saldo suficiente
      if (nuevoSaldo >= 0) {
        await docRef.update({'saldo': nuevoSaldo});
      } else {
        debugPrint('⚠️ Saldo insuficiente, no se pudo descontar');
      }
    }
  }
}
