import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../commons/main_layaout.dart';
import '../../../providers/auth_provider.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesExtincionPenaPage extends StatefulWidget {
  const HistorialSolicitudesExtincionPenaPage({super.key});

  @override
  State<HistorialSolicitudesExtincionPenaPage> createState() =>
      _HistorialSolicitudesExtincionPenaPageState();
}

class _HistorialSolicitudesExtincionPenaPageState extends State<HistorialSolicitudesExtincionPenaPage> {
  late MyAuthProvider _authProvider;
  String? _userId;
  int? _correoExpandidoIndex; // Agrega esto a tu State


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
        .collection('extincion_pena_solicitados')
        .where('idUser', isEqualTo: _userId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial extinción de pena',
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
    return Card(
      color: blanco,
      surfaceTintColor: blanco,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
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
                  "Negado" => Colors.red.shade50,
                  "Concedido" => Colors.green.shade200,
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
                      "Negado" => Icons.cancel,
                      "Concedido" => Icons.verified,
                      _ => Icons.help_outline,
                    },
                    size: 18,
                    color: switch (data['status']) {
                      "Solicitado" => Colors.orange,
                      "Diligenciado" => Colors.amber.shade700,
                      "Revisado" => Colors.teal,
                      "Enviado" => Colors.green,
                      "Negado" => Colors.red,
                      "Concedido" => Colors.green,
                      _ => Colors.grey,
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      switch (data['status']) {
                        "Solicitado" => "Hemos recibido tu solicitud",
                        "Diligenciado" => "Se está analizando tu solicitud",
                        "Revisado" => "Tu solicitud está lista para ser enviada",
                        "Enviado" => "Se ha enviado a la autoridad competente",
                        "Negado" => "La autoridad competente ha negado éste beneficio",
                        "Concedido" => "La autoridad ha concedido éste beneficio",
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
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Informe de Diligencias realizadas",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection("extincion_pena_solicitados")
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
                          // Encabezado
                          Container(
                            color: Colors.grey.shade100,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            child: const Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    "Estado",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    "Fecha",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "Ver",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Colors.grey),
                          // Iterar correos
                          ...correos.map((doc) {
                            final correo = doc.data() as Map<String, dynamic>;

                            // 📍 Determinar estado
                            final esRespuesta = correo['esRespuesta'] == true || correo['EsRespuesta'] == true;
                            final tipo = (correo['tipo'] ?? 'enviado').toString().toLowerCase().trim();
                            final estado = esRespuesta ? 'respuesta' : tipo;

                            // 📍 Formatear fecha
                            final fecha = (correo['timestamp'] as Timestamp?)?.toDate();
                            final fechaTexto = fecha != null
                                ? DateFormat("dd/MM/yyyy - hh:mm a", 'es').format(fecha)
                                : 'Fecha no disponible';

                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _estadoConIcono(estado),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Text(
                                          fechaTexto,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                'detalle_correo_extincion_pena',
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

  Widget _estadoConIcono(String estado) {
    late Icon icono;
    late String texto;
    estado = estado.toLowerCase().trim();

    switch (estado) {
      case 'email.delivered':
        icono = const Icon(Icons.check_circle, color: Colors.green, size: 16);
        texto = 'Entregado';
        break;
      case 'email.sent':
        icono = const Icon(Icons.send, color: Colors.green, size: 16);
        texto = 'Enviado';
        break;
      case 'enviado': // ✅ NUEVO CASO
        icono = const Icon(Icons.send, color: Colors.green, size: 16);
        texto = 'Enviado';
        break;
      case 'email.bounced':
        icono = const Icon(Icons.error, color: Colors.red, size: 16);
        texto = 'Rebotado';
        break;
      case 'respuesta':
        icono = const Icon(Icons.mark_email_read, color: Colors.deepPurple, size: 16);
        texto = 'Respuesta';
        break;
      case 'recibido':
        icono = const Icon(Icons.inbox, color: Colors.orange, size: 16);
        texto = 'Correo recibido';
        break;
      default:
        icono = const Icon(Icons.help_outline, color: Colors.grey, size: 16);
        texto = estado;
    }

    return Row(
      children: [
        icono,
        const SizedBox(width: 6),
        Flexible(child: Text(texto, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  String obtenerNombreArchivo(String url) {
    String decodedUrl = Uri.decodeFull(url);
    List<String> partes = decodedUrl.split('/');
    return partes.last.split('?').first;
  }

}
