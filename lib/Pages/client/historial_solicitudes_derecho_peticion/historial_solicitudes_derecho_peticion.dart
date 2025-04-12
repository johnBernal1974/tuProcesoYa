import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import '../../../commons/archivoViewerWeb.dart';
import '../../../commons/main_layaout.dart';
import '../../../providers/auth_provider.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesDerechosPeticionPage extends StatefulWidget {
  const HistorialSolicitudesDerechosPeticionPage({super.key});

  @override
  State<HistorialSolicitudesDerechosPeticionPage> createState() =>
      _HistorialSolicitudesDerechosPeticionPageState();
}

class _HistorialSolicitudesDerechosPeticionPageState extends State<HistorialSolicitudesDerechosPeticionPage> {
  late MyAuthProvider _authProvider;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _authProvider = MyAuthProvider();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _authProvider.getUser();
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  Stream<QuerySnapshot> _fetchSolicitudes() {
    if (_userId == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('derechos_peticion_solicitados')
        .where('idUser', isEqualTo: _userId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial derechos de petición',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 600 : double.infinity,
          child: StreamBuilder<QuerySnapshot>(
            stream: _fetchSolicitudes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error al cargar los datos"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No hay solicitudes registradas."));
              }

              final solicitudes = snapshot.data!.docs;

              return ListView.builder(
                itemCount: solicitudes.length,
                itemBuilder: (context, index) {
                  final solicitud = solicitudes[index];
                  final data = solicitud.data() as Map<String, dynamic>;

                  // Convertir la lista de archivos desde Firestore
                  List<String> archivos = [];
                  if (data.containsKey('archivos') && data['archivos'] != null) {
                    if (data['archivos'] is List) {
                      archivos = (data['archivos'] as List).whereType<String>().toList();
                    }
                  }

                  return _buildSolicitudCard(solicitud.id, data, archivos);

                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitudCard(String idDocumento, Map<String, dynamic> data, List<String> archivos) {
    List<Map<String, String>> archivosAdjuntos = archivos.map((archivo) {
      return {
        "nombre": obtenerNombreArchivo(archivo),
        "contenido": archivo,
      };
    }).toList();

    return Card(
      color: blanco,
      surfaceTintColor: blanco,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDatoFila("Número de seguimiento", data['numero_seguimiento'] ?? 'N/A'),
            _buildDatoFila(
              "Fecha de solicitud",
              data['fecha'] != null
                  ? DateFormat("d 'de' MMMM 'de' y", 'es').format((data['fecha'] as Timestamp).toDate())
                  : 'Sin fecha',
            ),
            _buildDatoFila("Categoría", data['categoria'] ?? 'Desconocida'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDatoFila("Subcategoría", data['subcategoria'] ?? "Desconocida"),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: _buildDatoFila("Estado", data['status'] ?? "Desconocido"),
                ),
                const Divider(),
                const Text("📜 Preguntas y respuestas:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                _buildPreguntasRespuestas(data['preguntas_respuestas']),
                const Divider(),
                const Text("📎 Archivos adjuntos:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                archivosAdjuntos.isNotEmpty
                    ? ArchivoViewerWeb(archivos: archivos)
                    : const Text("El usuario no compartió ningún archivo"),
                TextButton(
                  onPressed: () async {
                    final snapshot = await FirebaseFirestore.instance
                        .collection("derechos_peticion_solicitados")
                        .doc(idDocumento)
                        .collection("log_correos")
                        .orderBy("timestamp", descending: true)
                        .limit(1)
                        .get();

                    if (snapshot.docs.isNotEmpty) {
                      final correoId = snapshot.docs.first.id;
                      _mostrarDetalleCorreo(idDocumento, correoId);
                    } else {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) => const AlertDialog(
                          title: Text("Correo no disponible"),
                          content: Text("No se encontró ningún correo enviado para esta solicitud."),
                        ),
                      );
                    }
                  },
                  child: const Text("Ver correo enviado"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatoFila(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntasRespuestas(List<dynamic>? preguntasRespuestas) {
    if (preguntasRespuestas == null || preguntasRespuestas.isEmpty) {
      return const Text("No hay preguntas registradas.");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: preguntasRespuestas.asMap().entries.map((entry) {
        final int index = entry.key + 1;
        final Map<String, dynamic> preguntaRespuesta = entry.value;
        final String pregunta = preguntaRespuesta['pregunta'] ?? "Pregunta desconocida";
        final String respuesta = preguntaRespuesta['respuesta'] ?? "Sin respuesta";

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Pregunta $index: $pregunta",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Text("Respuesta: $respuesta",
                  style: const TextStyle(color: Colors.black87, fontSize: 11)),
              const Divider(),
            ],
          ),
        );
      }).toList(),
    );
  }

  String obtenerNombreArchivo(String url) {
    String decodedUrl = Uri.decodeFull(url);
    List<String> partes = decodedUrl.split('/');
    return partes.last.split('?').first;
  }

  void _mostrarDetalleCorreo(String idDocumento, String correoId) {
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
                    .collection('derechos_peticion_solicitados')
                    .doc(idDocumento)
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
