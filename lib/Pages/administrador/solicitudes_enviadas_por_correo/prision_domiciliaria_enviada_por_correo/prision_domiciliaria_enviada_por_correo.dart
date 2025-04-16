
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import 'dart:io'; // Necesario para manejar archivos en almacenamiento local
import 'package:universal_html/html.dart' as html;

import '../../../../commons/admin_provider.dart';
import '../../../../commons/archivoViewerWeb.dart';
import '../../../../commons/main_layaout.dart';
import '../../../../models/ppl.dart';
import '../../../../src/colors/colors.dart';
import '../../../../widgets/email_status_widget.dart';


class SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage extends StatefulWidget {
  final String status;
  final String idDocumento;
  final String numeroSeguimiento;
  final String categoria;
  final String subcategoria;
  final String fecha;
  final String idUser;
  final String direccion;
  final String municipio;
  final String departamento;
  final String nombreResponsable;
  final String cedulaResponsable;
  final String celularResponsable;

  // Archivos adjuntos generales
  final List<String> archivos;

  // Nuevos campos específicos de prisión domiciliaria
  final String? urlArchivoCedulaResponsable;
  final List<String> urlsArchivosHijos;
  final bool sinRespuesta;

  const SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage({
    super.key,
    required this.status,
    required this.idDocumento,
    required this.numeroSeguimiento,
    required this.categoria,
    required this.subcategoria,
    required this.fecha,
    required this.idUser,
    required this.archivos,
    this.urlArchivoCedulaResponsable,
    this.urlsArchivosHijos = const [],
    required this.direccion,
    required this.municipio,
    required this.departamento,
    required this.nombreResponsable,
    required this.cedulaResponsable,
    required this.celularResponsable,
    required this.sinRespuesta,

  });


  @override
  State<SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage> createState() => _SolicitudesPrisionDomiciliariaEnviadasPorCorreoPageState();
}

class _SolicitudesPrisionDomiciliariaEnviadasPorCorreoPageState extends State<SolicitudesPrisionDomiciliariaEnviadasPorCorreoPage> {
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
  String rol = AdminProvider().rol ?? "";

  List<PlatformFile> _selectedFiles = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    archivos = List<String>.from(widget.archivos); // Copia los archivos una vez
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Prisión Domiciliaria Enviada',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000
                ? 1500
                : double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                            builder: (context, constraints) {
                              bool isMobile = constraints.maxWidth < 800; // Detectar si es móvil

                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: isMobile
                                        ? Column( // En móviles, disposición en columna
                                      children: [
                                        if (widget.sinRespuesta)
                                        _buildWarningMessage(),
                                        const SizedBox(height: 10),
                                        if (widget.sinRespuesta && rol != "pasante 1") _buildTutelaButton(context),
                                        const SizedBox(height: 15)
                                      ],
                                    )

                                        : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (widget.sinRespuesta)
                                          Flexible(child: _buildWarningMessage()),

                                        const SizedBox(width: 50),

                                        if (widget.sinRespuesta && rol != "pasante 1")
                                          SizedBox(width: 200, child: _buildTutelaButton(context)),
                                        const Divider(color: Colors.red, height: 1),
                                      ],
                                    ),

                                  ),

                                ],
                              );
                            },
                          ),
                      const SizedBox(height: 30),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: _buildMainContent()),
                            const SizedBox(width: 50),
                            Expanded(
                              flex: 3,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 30),
                                    const Text(
                                      "📡 Estado del envío",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      height: 300, // o el valor que consideres adecuado
                                      child:
                                      ListaCorreosWidget(
                                        solicitudId: widget.idDocumento,
                                        nombreColeccion: "prision_domiciliaria_solicitados",
                                        onTapCorreo: _mostrarDetalleCorreo,
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildMainContent(),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 30),
                                  const Text(
                                    "📡 Estado del envío",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    height: 300, // o el valor que consideres adecuado
                                    child:
                                    ListaCorreosWidget(
                                      solicitudId: widget.idDocumento,
                                      nombreColeccion: "prision_domiciliaria_solicitados",
                                      onTapCorreo: _mostrarDetalleCorreo,
                                    )
                                  ),

                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
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

  Widget _buildTutelaButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: const BorderSide(width: 1, color: Colors.red),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: () async {
        bool confirmarTutela = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              "Confirmación",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text("¿Está seguro de que desea enviar esta solicitud a Tutela?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar", style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text("Sí, enviar", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirmarTutela) {
          print("📢 La solicitud ha sido enviada a Tutela.");
        }
      },
      child: const Text("Iniciar Tutela"),
    );
  }

  // Widget para el mensaje de advertencia
  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Sin obtener respuesta de la autoridad competente.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
      mainAxisAlignment: MainAxisAlignment.start,
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
      await firestore.collection('prision_domiciliaria_solicitudas').doc(docId).update({
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final fontSize = isMobile ? 20.0 : 28.0;

            return Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  "Prisión domiciliaria - Enviada",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ],
            );

          },
        ),
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
        const SizedBox(height: 15),
       _buildInformacionUsuarioWidget(
          direccion: widget.direccion,
          departamento: widget.departamento,
          municipio: widget.municipio,
          nombreResponsable: widget.nombreResponsable,
          cedulaResponsable: widget.cedulaResponsable,
          celularResponsable: widget.celularResponsable,
        ),
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
        if (widget.urlArchivoCedulaResponsable != null && widget.urlArchivoCedulaResponsable!.isNotEmpty) ...[
          const Text("🪪 Cédula del responsable", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ArchivoViewerWeb(archivos: [widget.urlArchivoCedulaResponsable!]),
          const SizedBox(height: 20),
        ],

        if (widget.urlsArchivosHijos.isNotEmpty) ...[
          const Text("👶 Documentos de identidad de los hijos", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ArchivoViewerWeb(archivos: widget.urlsArchivosHijos),
          const SizedBox(height: 20),
        ],

        const Divider(color: gris),
        const SizedBox(height: 50),
        datosDeLaborAdmin()
        //vistaPreviaDerechoPeticion(userData, consideraciones, fundamentosDeDerecho, peticionConcreta),
      ],
    );
  }

  Widget _buildInformacionUsuarioWidget({
    required String direccion,
    required String departamento,
    required String municipio,
    required String nombreResponsable,
    required String cedulaResponsable,
    required String celularResponsable,
  }) {
    TextStyle labelStyle = const TextStyle(fontSize: 13);
    TextStyle valueStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);

    return Card(
      surfaceTintColor: blanco,
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Información suministrada por el Usuario",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text("Lugar donde cumplirá la prisión domiciliaria"),
            // Dirección
            Row(
              children: [
                Text("Dirección: ", style: labelStyle),
                Expanded(
                  child: Text(
                    '$direccion, $municipio, $departamento',
                    style: valueStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Responsable
            const Divider(height: 20, color: gris),
            const Text(
              "Persona que se hace responsable en el Domicilio",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Text("Nombres y apellidos: ", style: labelStyle),
                Expanded(child: Text(nombreResponsable, style: valueStyle)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text("Numero de identificación: ", style: labelStyle),
                Expanded(child: Text(cedulaResponsable, style: valueStyle)),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                Text("Teléfono Celular: ", style: labelStyle),
                Expanded(child: Text(celularResponsable, style: valueStyle)),
              ],
            ),
          ],
        ),
      ),
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
    double fontSize = MediaQuery.of(context).size.width < 600 ? 10 : 12; // Tamaño más pequeño en móviles
    bool isMobile = MediaQuery.of(context).size.width < 600; // Verifica si es móvil

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Asegurar alineación izquierda en móviles
        children: [
          isMobile
              ? Column( // En móviles, mostrar en columnas
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetalleItem("Número de seguimiento", widget.numeroSeguimiento, fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Categoría", widget.categoria, fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
              const SizedBox(height: 5),
              _buildDetalleItem("Subcategoría", widget.subcategoria, fontSize),
            ],
          )
              : Row( // En PC, mantener filas
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Número de seguimiento", widget.numeroSeguimiento, fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Categoría", widget.categoria, fontSize),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetalleItem("Fecha de solicitud", _formatFecha(DateTime.tryParse(widget.fecha)), fontSize),
                  const SizedBox(height: 5),
                  _buildDetalleItem("Subcategoría", widget.subcategoria, fontSize),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método auxiliar para evitar repetir código
  Widget _buildDetalleItem(String title, String value, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: fontSize, color: Colors.black87)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize + 2)),
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
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            flex: 4,
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget datosDeLaborAdmin() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📝 Datos de la gestión administrativa",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),

          _buildRow("Diligenció:", diligencio),
          _buildRow("Fecha de diligenciamiento:", _formatFecha(fechaDiligenciamiento)),
          const Divider(color: Colors.grey),

          _buildRow("Revisó:", reviso),
          _buildRow("Fecha de revisión:", _formatFecha(fechaRevision)),
          const Divider(color: Colors.grey),

          _buildRow("Envió:", envio),
          _buildRow("Fecha de envío:", _formatFecha(fechaEnvio)),
        ],
      ),
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
          .collection('prision_domiciliaria_solicitados')
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

  /// 📄 Abrir HTML en nueva pestaña para que el usuario pueda imprimir/guardar como PDF
  void abrirHtmlParaImprimir(String url) {
    html.window.open(url, '_blank');
  }
  void _mostrarDetalleCorreo(String correoId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Container(
              color: blanco,
              width: isMobile ? double.infinity : 1000,
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('prision_domiciliaria_solicitados')
                    .doc(widget.idDocumento)
                    .collection('log_correos')
                    .doc(correoId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("No se encontró información del correo.");
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final to = (data['to'] as List).join(', ');
                  final cc = (data['cc'] as List?)?.join(', ') ?? '';
                  final subject = data['subject'] ?? '';
                  final htmlContent = data['html'] ?? '';
                  final archivos = data['archivos'] as List?;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final fechaEnvio = timestamp != null
                      ? DateFormat("dd MMM yyyy - hh:mm a", 'es').format(timestamp)
                      : 'Fecha no disponible';

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text("Para: ", style: TextStyle(fontSize: 13)),
                            Text(to, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        if (cc.isNotEmpty)
                          Text("CC: $cc", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        Text("Asunto: $subject", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("📅 Fecha de envío: $fechaEnvio", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                        const Divider(),
                        Html(data: htmlContent),
                        if (archivos != null && archivos.isNotEmpty) ...[
                          const Divider(),
                          const Text("Archivos adjuntos:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...archivos.map((a) => Text("- ${a['nombre']}"))
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text("Cerrar"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

}
