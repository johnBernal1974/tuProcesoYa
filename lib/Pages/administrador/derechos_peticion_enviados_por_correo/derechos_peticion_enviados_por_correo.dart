
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import '../../../commons/archivoViewerWeb.dart';
import '../../../commons/main_layaout.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_derecho_peticion.dart';
import '../../../src/colors/colors.dart';
import 'dart:io'; // Necesario para manejar archivos en almacenamiento local

class DerechoSPeticionEnviadosPorCorreoPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String categoria;
  final String subcategoria;
  final String fecha;
  final String idUser;
  final List<dynamic> archivos; // Lista de archivos
  final List<String> respuestas; // Lista de respuestas
  final List<String> preguntas; // Lista de respuestas

  const DerechoSPeticionEnviadosPorCorreoPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.categoria,
    required this.subcategoria,
    required this.fecha,
    required this.idUser,
    required this.archivos,
    required this.respuestas,
    required this.preguntas,// Nuevo parámetro agregado
  });

  @override
  State<DerechoSPeticionEnviadosPorCorreoPage> createState() => _DerechoSPeticionEnviadosPorCorreoPageState();
}


class _DerechoSPeticionEnviadosPorCorreoPageState extends State<DerechoSPeticionEnviadosPorCorreoPage> {
  late PplProvider _pplProvider;
  Ppl? userData;
  bool isLoading = true; // Bandera para controlar la carga
  int diasEjecutado = 0;
  int mesesEjecutado = 0;
  int diasEjecutadoExactos = 0;
  int diasRestante = 0;
  int mesesRestante = 0;
  int diasRestanteExactos = 0;
  double porcentajeEjecutado =0;
  int tiempoCondena =0;
  List<String> archivos = [];
  String consideraciones = "";
  String fundamentosDeDerecho = "";
  String peticionConcreta = "";
  String diligencio = '';
  String reviso = '';
  String envio = '';
  String pantallazoCorreoEnviado = '';
  DateTime? fechaEnvio;
  DateTime? fechaDiligenciamiento;
  DateTime? fechaRevision;

  List<PlatformFile> _selectedFiles = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    archivos = List<String>.from(widget.archivos); // Copia los archivos una vez
    fetchUserData();
  }

  String obtenerTituloCorreo(String? nombreCorreo) {
    switch (nombreCorreo) {
      case 'Director':
        return 'Señor\nDirector';
      case 'Jurídica':
        return 'Señores Oficina Jurídica';
      case 'Principal':
        return 'Señores';
      case 'Sanidad':
        return 'Señores Oficina de Sanidad';
      case 'Correo JEP':
        return 'Señor(a) Juez';
      case 'Correo JDC':
        return 'Señor(a) Juez';
      default:
        return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Derecho Petición Enviado',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? 1500 : double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800; // Si es PC/tablet grande
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildMainContent()),
                            const SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Column( // 👈 Envolver en Column para apilar los widgets verticalmente
                                children: [
                                  vistaPreviaDerechoPeticion(userData, consideraciones, fundamentosDeDerecho, peticionConcreta),
                                  const SizedBox(height: 20), // Espacio opcional
                                  if(pantallazoCorreoEnviado.isEmpty)
                                  adjuntarPantallazoCorreoEnviado(),
                                  const SizedBox(height: 30),
                                  /// 📂 **Mostramos los archivos aquí**
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Text("Pantallazo del correo enviado", style: TextStyle(fontWeight: FontWeight.bold),),
                                      pantallazoCorreoEnviado.isNotEmpty
                                          ? ArchivoViewerWeb(archivos: [pantallazoCorreoEnviado]) // Convertimos el string en una lista con un solo elemento
                                          : const Text(
                                        "Aún no se ha tomado el pantallazo del correo enviado",
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                // Ahora está debajo del otro widget
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildMainContent(),
                            const SizedBox(height: 20),
                            vistaPreviaDerechoPeticion(userData, consideraciones, fundamentosDeDerecho, peticionConcreta),
                            const SizedBox(height: 20),
                            const Text("Hola"),
                          ],
                        ),
                    ],
                  );

                },
              ),
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
        allowMultiple: false, // Permitir selección múltiple
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

  Widget adjuntarPantallazoCorreoEnviado() {
    return Column(
      children: [
        const SizedBox(height: 15),
        GestureDetector(
          onTap: pickFiles,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.attach_file, color: primary, size: 18),
              SizedBox(width: 8),
              Text(
                "Adjuntar pantallazo",
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
        const SizedBox(height: 80),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primary),
          onPressed: () {
            guardarPantallazo(widget.idDocumento);
          },
          child: const Text(
            "Guardar",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Future<void> guardarPantallazo(String docId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print("❌ No hay usuario autenticado.");
      }
      return;
    }

    bool confirmarEnvio = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Confirmación"),
        content: const Text("Deseas guardar el pantallazo"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Guardar"),
          ),
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
              Text("Subiendo información, por favor espera..."),
            ],
          ),
        ),
      );
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      FirebaseStorage storage = FirebaseStorage.instance;

      String? imagenUrl; // Variable para almacenar solo UNA URL

      // Guardar el primer archivo en Firebase Storage
      if (_selectedFiles.isNotEmpty) {
        PlatformFile file = _selectedFiles.first; // Toma solo el primer archivo

        try {
          String filePath = 'derechos_peticion/$docId/pantallazos/${file.name}';
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
            uploadTask =
                storageRef.putData(file.bytes!, SettableMetadata(contentType: contentType));
          } else {
            File fileToUpload = File(file.path!);
            uploadTask =
                storageRef.putFile(fileToUpload, SettableMetadata(contentType: contentType));
          }

          TaskSnapshot snapshot = await uploadTask;
          imagenUrl = await snapshot.ref.getDownloadURL(); // Guarda solo la primera URL

        } catch (e) {
          if (kDebugMode) {
            print("Error al subir el archivo ${file.name}: $e");
          }
        }
      }

      // ⚡ Actualizar el documento en Firestore con un solo string en lugar de un array
      await firestore.collection('derechos_peticion_solicitados').doc(docId).update({
        "correoEnviadoPantallazo": imagenUrl ?? "Error al obtener imagen",
        "fecha_guardado_pantallazo": Timestamp.now(), // ✅ Agrega la fecha actual
      });

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (kDebugMode) {
        print("✅ Pantallazo guardado correctamente.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al guardar el pantallazo: $e");
      }

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



  /// 🖥️📱 Widget de contenido principal (sección izquierda en PC)
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFechaHoy(),
        const SizedBox(height: 10),
        const Text("Derecho de petición (Enviado)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
        Row(
          children: [
            Text(
              "Solicitado por: ${userData?.nombreAcudiente ?? "Sin información"} ${userData?.apellidoAcudiente ?? "Sin información"}",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildDetallesSolicitud(),
        const SizedBox(height: 20),
        _buildSolicitudTexto(),
        const SizedBox(height: 30),
        const Row(
          children: [
            Icon(Icons.attach_file),
            Text("Archivos adjuntos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 30),

        /// 📂 **Mostramos los archivos aquí**
        archivos.isNotEmpty
            ? ArchivoViewerWeb(archivos: archivos)
            : const Text(
          "El usuario no compartió ningún archivo",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
        ),
        const SizedBox(height: 30),
        const Divider(color: gris),
        const SizedBox(height: 50),
        datosDeLaborAdmin()
        //vistaPreviaDerechoPeticion(userData, consideraciones, fundamentosDeDerecho, peticionConcreta),
      ],
    );
  }

  /// 📅 Muestra la fecha de hoy en formato adecuado
  Widget _buildFechaHoy() {
    return Text(
      'Hoy es: ${DateFormat('d \'de\' MMMM \'de\' y', 'es').format(DateTime.now())}',
      style: const TextStyle(fontSize: 12),
    );
  }

  /// 📌 Muestra detalles de la solicitud (seguimiento, categoría, fecha, subcategoría)
  Widget _buildDetallesSolicitud() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Número de seguimiento", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.numeroSeguimiento, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Categoría", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.categoria, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Fecha de solicitud", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              _formatFecha(DateTime.tryParse(widget.fecha)), // Convierte antes de formatear
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Subcategoría", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.subcategoria, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  /// 🔹 Widget de fila con título y valor
  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Expanded(
            flex: 4,
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget datosDeLaborAdmin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow("Diligenció:", diligencio),
        _buildRow("Fecha:", _formatFecha(fechaDiligenciamiento)),
        const SizedBox(height: 20),
        _buildRow("Revisó:", reviso),
        _buildRow("Fecha:", _formatFecha(fechaRevision)),
        const SizedBox(height: 20),
        _buildRow("Envió:", envio),
        _buildRow("Fecha:", _formatFecha(fechaEnvio)),
      ],
    );
  }

  /// 📝 Muestra la descripción de la solicitud en un contenedor estilizado
  Widget _buildSolicitudTexto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: gris),
        const Text(
          "Comentarios hechos por el usuario",
          style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: widget.preguntas.isNotEmpty && widget.respuestas.isNotEmpty
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              widget.preguntas.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.preguntas[index],
                      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      index < widget.respuestas.length ? widget.respuestas[index] : 'No hay respuesta',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    const Divider(), // Separador entre preguntas
                  ],
                ),
              ),
            ),
          )
              : const Text(
            "No hay preguntas ni respuestas registradas.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  /// 📆 Función para manejar errores en la conversión de fechas
  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "";
    return DateFormat(formato, 'es').format(fecha);
  }

  void fetchUserData() async {
    try {
      // 🧑‍💻 Obtener datos del usuario
      Ppl? fetchedData = await _pplProvider.getById(widget.idUser);

      // 🔥 Obtener documento de Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('derechos_peticion_solicitados')
          .doc(widget.idDocumento)
          .get();

      // ✅ Verificar si el documento existe
      if (documentSnapshot.exists) {
        Map<String, dynamic>? data = documentSnapshot.data() as Map<String, dynamic>?;

        // 🔍 Verificar si `data` no es nulo
        if (data != null) {
          if (mounted) {
            setState(() {
              userData = fetchedData;
              isLoading = false;

              // ✅ Asignar valores de Firestore o definir valores por defecto si no existen
              consideraciones = data['consideraciones_revisado'] ?? 'Sin consideraciones';
              fundamentosDeDerecho = data['fundamentos_de_derecho_revisado'] ?? 'Sin fundamentos';
              peticionConcreta = data['peticion_concreta_revisado'] ?? 'Sin petición concreta';

              // 🆕 Cargar nuevos nodos
              diligencio = data['diligencio'] ?? 'No registrado';
              reviso = data['reviso'] ?? 'No registrado';
              envio = data['envió'] ?? 'No registrado';

              pantallazoCorreoEnviado = data['correoEnviadoPantallazo'] ?? '';
              print(" Esta es la imagen del pantallazo************$pantallazoCorreoEnviado");

              fechaEnvio = (data['fechaEnvio'] as Timestamp?)?.toDate();
              fechaDiligenciamiento = (data['fecha_diligenciamiento'] as Timestamp?)?.toDate();
              fechaRevision = (data['fecha_revision'] as Timestamp?)?.toDate();
            });
          } else {
            if (kDebugMode) {
              print("⚠️ El widget ya no está montado, no se actualizó el estado.");
            }
          }
        } else {
          if (kDebugMode) {
            print("⚠️ Los datos en Firestore son nulos.");
          }
        }
      } else {
        if (kDebugMode) {
          print("⚠️ Documento no encontrado en Firestore");
        }

        // Si no existe el documento, igualmente actualizamos `userData` y quitamos el loader
        if (mounted) {
          setState(() {
            userData = fetchedData;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al obtener datos de Firestore: $e");
      }
    }
  }

  Widget vistaPreviaDerechoPeticion(userData, String consideracionesRevisado, String fundamentosDeDerechoRevisado, String peticionConcretaRevisado) {
    var derechoPeticion = DerechoPeticionTemplate(
      dirigido: "",
      entidad: userData?.centroReclusion ?? "",
      referencia: '${widget.categoria} - ${widget.subcategoria}',
      nombrePpl: userData?.nombrePpl?.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl?.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      consideraciones: consideraciones,
      fundamentosDeDerecho: fundamentosDeDerecho,
      peticionConcreta: peticionConcreta,
      emailUsuario: userData?.email?.trim() ?? "",
      td: userData?.td?.trim() ?? "",
      nui: userData?.nui?.trim() ?? "",
    );


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Correo enviado",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Html(
            data: derechoPeticion.generarTextoHtml(),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

}
