import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import '../../../commons/archivoViewerWeb.dart';
import '../../../commons/main_layaout.dart';
import '../../../providers/auth_provider.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesLibertadCondicionalPage extends StatefulWidget {
  const HistorialSolicitudesLibertadCondicionalPage({super.key});

  @override
  State<HistorialSolicitudesLibertadCondicionalPage> createState() =>
      _HistorialSolicitudesLibertadCondicionalPageState();
}

class _HistorialSolicitudesLibertadCondicionalPageState extends State<HistorialSolicitudesLibertadCondicionalPage> {
  late MyAuthProvider _authProvider;
  String? _userId;
  int? _correoExpandidoIndex;


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
        .collection('libertad_condicional_solicitados')
        .where('idUser', isEqualTo: _userId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial libertad condicional',
      content: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600 ? 2 : 0,
          ),
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

    // Obtener archivos de los hijos
    List<String> urlsHijos = [];
    if (data.containsKey('documentos_hijos') && data['documentos_hijos'] is List) {
      urlsHijos = (data['documentos_hijos'] as List).whereType<String>().toList();
    }

    return Card(
      color: blanco,
      surfaceTintColor: blanco,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: switch (data['status']) {
                  "Solicitado" => Colors.orange.shade50,
                  "Diligenciado" => Colors.amber.shade50,
                  "Revisado" => Colors.teal.shade50,
                  "Enviado" => Colors.green.shade50,
                  _ => Colors.grey.shade100,
                },
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    switch (data['status']) {
                      "Solicitado" => Icons.assignment_outlined,
                      "Diligenciado" => Icons.search,
                      "Revisado" => Icons.check_circle_outline,
                      "Enviado" => Icons.send_outlined,
                      _ => Icons.help_outline,
                    },
                    size: 18,
                    color: switch (data['status']) {
                      "Solicitado" => Colors.orange,
                      "Diligenciado" => Colors.amber.shade700,
                      "Revisado" => Colors.teal,
                      "Enviado" => Colors.green,
                      _ => Colors.grey,
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      switch (data['status']) {
                        "Solicitado" => "Se recibió tu solicitud",
                        "Diligenciado" => "Se está analizando tu solicitud",
                        "Revisado" => "Tu solicitud está lista para ser enviada",
                        "Enviado" => "Se ha enviado a la autoridad competente",
                        _ => "Estado desconocido",
                      },
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            _buildDatoFila2("Número de seguimiento", data['numero_seguimiento'] ?? 'N/A'),
            _buildDatoFila(
              "Fecha de solicitud",
              data['fecha'] != null
                  ? DateFormat("d 'de' MMMM 'de' y", 'es').format((data['fecha'] as Timestamp).toDate())
                  : 'Sin fecha',
            ),
            _buildDatoColumna("Categoría", "Beneficios penitenciarios"),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDatoFila("Subcategoría", "Libertad condicional"),
                const Divider(color: gris),
                Card(
                  surfaceTintColor: Colors.amber.shade700,
                  margin: const EdgeInsets.only(top: 20),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDatoReparacion(data['reparacion']),
                        const SizedBox(height: 15),
                        const Divider(color: gris),
                        const Text(
                          "Archivos que enviaste en la solicitud",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: negro),
                        ),const SizedBox(height: 5),
                        const Text(
                          "📎 Archivos adjuntos:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 5),
                        archivosAdjuntos.isNotEmpty
                            ? ArchivoViewerWeb(archivos: archivos)
                            : const Text("El usuario no compartió ningún archivo"),
                        const SizedBox(height: 12),
                        if (urlsHijos.isNotEmpty) ...[
                          const Divider(color: gris),
                          const Text(
                            "👶 Documentos de identidad de los hijos:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          ArchivoViewerWeb(archivos: urlsHijos),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text("Informe de Diligencias realizadas"),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("libertad_condicional_solicitados")
                      .doc(idDocumento)
                      .collection("log_correos")
                      .orderBy("timestamp", descending: true)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text(
                        "Aún no hay correos enviados a la autoridad competente para esta solicitud.",
                        style: TextStyle(fontSize: 11),
                      );
                    }

                    final correos = snapshot.data!.docs;
                    return Container(
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            color: Colors.grey.shade100,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text("Estado", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text("Ver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.grey),
                          ...correos.map((doc) {
                            final correo = doc.data() as Map<String, dynamic>;
                            final fecha = (correo['timestamp'] as Timestamp?)?.toDate();
                            final fechaTexto = fecha != null
                                ? DateFormat("dd/MM/yyyy - hh:mm a", 'es').format(fecha)
                                : 'Fecha no disponible';
                            final estado = correo['tipo'] ?? 'Enviado';

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(estado, style: const TextStyle(fontSize: 11))),
                                      Expanded(flex: 4, child: Text(fechaTexto, style: const TextStyle(fontSize: 10))),
                                      Expanded(
                                        flex: 3,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                'detalle_correo_libertad_condicional',
                                                arguments: {
                                                  'idDocumento': idDocumento,
                                                  'correoId': doc.id,
                                                },
                                              );
                                            },
                                            child: const Text(
                                              "Ver el correo",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Colors.grey),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDatoReparacion(String? valorRaw) {
    String textoAMostrar;

    switch (valorRaw) {
      case 'reparado':
        textoAMostrar = 'Informaste que fue reparada a la víctima.';
        break;
      case 'asegurado':
        textoAMostrar = 'Informaste que se aseguró el pago de la reparación.';
        break;
      case 'insolvencia':
        textoAMostrar = 'Informaste que no se ha reparado a la víctima debido a insolvencia.';
        break;
      default:
        textoAMostrar = 'Información no registrada.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Información de reparación de la víctima",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            textoAMostrar,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black87),
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

  Widget _buildDatoFila2(String titulo, String valor) {
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildDatoColumna(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }
  Widget _buildDatoColumna2(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  String obtenerNombreArchivo(String url) {
    String decodedUrl = Uri.decodeFull(url);
    List<String> partes = decodedUrl.split('/');
    return partes.last.split('?').first;
  }
}
