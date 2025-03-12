import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../commons/main_layaout.dart';
import '../../../main.dart';
import '../../../providers/auth_provider.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesDerechosPeticionPage extends StatefulWidget {
  const HistorialSolicitudesDerechosPeticionPage({super.key});

  @override
  State<HistorialSolicitudesDerechosPeticionPage> createState() => _HistorialSolicitudesDerechosPeticionPageState();
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
      print("🔹 Usuario actual: $_userId");
    }
  }

  Stream<QuerySnapshot> _fetchSolicitudes() {
    if (_userId == null) {
      print("❌ _userId es null, devolviendo un Stream vacío.");
      return const Stream.empty();
    }

    print("🔹 Buscando solicitudes para usuario: $_userId");

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
      content: StreamBuilder<QuerySnapshot>(
        stream: _fetchSolicitudes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("❌ Error en StreamBuilder: ${snapshot.error}");
            return const Center(child: Text("Error al cargar los datos"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print("🔸 No hay solicitudes en Firestore.");
            return const Center(child: Text("No hay solicitudes registradas."));
          }

          final solicitudes = snapshot.data!.docs;
          print("📌 Cantidad de solicitudes: ${solicitudes.length}");

          return ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = solicitudes[index];
              final data = solicitud.data() as Map<String, dynamic>;

              // 🔹 Depuración detallada
              debugPrint("📄 Documento Firestore completo: ${data.toString()}");
              debugPrint("📂 Valor crudo de 'archivos' desde Firestore: ${data['archivos']}");

              // 🔹 Convertir a lista de Strings
              List<String> archivos = [];

              if (data.containsKey('archivos') && data['archivos'] != null) {
                if (data['archivos'] is List) {
                  archivos = (data['archivos'] as List).whereType<String>().toList();
                } else {
                  debugPrint("⚠️ El campo 'archivos' no es una lista.");
                }
              } else {
                debugPrint("⚠️ El campo 'archivos' no existe en el documento o es null.");
              }

              debugPrint("📂 Archivos procesados después de conversión: $archivos");

              // ✅ Pasamos ahora los archivos a _buildSolicitudCard
              return _buildSolicitudCard(data, archivos);
            },
          );
        },
      ),
    );
  }


  Widget _buildSolicitudCard(Map<String, dynamic> data, List<String> archivos) {
    return Card(
      color: blanco,
      surfaceTintColor: blanco,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                _buildArchivosAdjuntos(archivos), // ✅ Ahora se pasa la lista de archivos correctamente
              ],
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildDatoFila(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Espaciado entre filas
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Alineación en los extremos
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
        final int index = entry.key + 1; // Para numerar desde 1
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
              const Divider(), // Línea divisoria entre preguntas
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _buildArchivosAdjuntos(List<String> archivos) {
    debugPrint("📂 Archivos recibidos: $archivos"); // 🐛 Debugging

    if (archivos.isEmpty) {
      return const Text(
        "No adjuntaste ningún archivo en esta solicitud.",
        style: TextStyle(fontSize: 12, color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Archivos adjuntos:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: archivos.map((url) {
            bool esPDF = url.toLowerCase().endsWith('.pdf');

            return GestureDetector(
              onTap: () {
                if (esPDF) {
                  _abrirEnNavegador(url);
                } else {
                  _mostrarImagenAmpliada(url);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: esPDF
                    ? Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                )
                    : Image.network(
                  url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 🔹 Método para abrir PDFs en una nueva pestaña
  void _abrirEnNavegador(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ No se pudo abrir el PDF: $url");
    }
  }

  /// 🔹 Método para mostrar imagen en pantalla completa
  void _mostrarImagenAmpliada(String url) {
    showDialog(
      context: navKey.currentContext!, // ✅ Ahora `navKey` está definido
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: Image.network(url),
          ),
        ),
      ),
    );
  }

}
