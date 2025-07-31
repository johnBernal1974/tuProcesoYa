import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../commons/main_layaout.dart';
import '../../../providers/auth_provider.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesCopiaSentenciaPage extends StatefulWidget {
  const HistorialSolicitudesCopiaSentenciaPage({super.key});

  @override
  State<HistorialSolicitudesCopiaSentenciaPage> createState() =>
      _HistorialSolicitudesCopiaSentenciaPageState();
}

class _HistorialSolicitudesCopiaSentenciaPageState
    extends State<HistorialSolicitudesCopiaSentenciaPage> {
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
    if (_userId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('copiaSentencia_solicitados')
        .where('idUser', isEqualTo: _userId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial copia sentencia',
      content: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 600 ? 2 : 0),
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
                    return _buildSolicitudCard(solicitud.id, data);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitudCard(String idDocumento, Map<String, dynamic> data) {
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
            _estadoSolicitud(data['status']),
            _buildDatoFila("Número de seguimiento", data['numero_seguimiento'] ?? 'N/A'),
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
                const Divider(color: gris),
                const SizedBox(height: 8),
                _diligencias(idDocumento),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoSolicitud(String? estado) {
    final colorFondo = {
      "Solicitado": Colors.orange.shade50,
      "Diligenciado": Colors.amber.shade50,
      "Revisado": Colors.teal.shade50,
      "Enviado": Colors.green.shade50,
      "Negado": Colors.red.shade50,
      "Concedido": Colors.green.shade200,
    }[estado] ?? Colors.grey.shade100;

    final icono = {
      "Solicitado": Icons.assignment_outlined,
      "Diligenciado": Icons.search,
      "Revisado": Icons.check_circle_outline,
      "Enviado": Icons.send_outlined,
      "Negado": Icons.cancel,
      "Concedido": Icons.verified,
    }[estado] ?? Icons.help_outline;

    final colorIcono = {
      "Solicitado": Colors.orange,
      "Diligenciado": Colors.amber.shade700,
      "Revisado": Colors.teal,
      "Enviado": Colors.green,
      "Negado": Colors.red,
      "Concedido": Colors.green,
    }[estado] ?? Colors.grey;

    final mensaje = {
      "Solicitado": "Hemos recibido tu solicitud",
      "Diligenciado": "Se está analizando tu solicitud",
      "Revisado": "Tu solicitud está lista para ser enviada",
      "Enviado": "Se ha enviado a la autoridad competente",
      "Negado": "La autoridad competente ha negado este recurso",
      "Concedido": "La autoridad ha concedido este recurso",
    }[estado] ?? "Estado desconocido";

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: colorIcono),
          const SizedBox(width: 10),
          Expanded(
            child: Text(mensaje,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _diligencias(String idDocumento) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("copiaSentencia_solicitados")
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
              ...correos.map((doc) {
                final correo = doc.data() as Map<String, dynamic>;
                final esRespuesta = correo['esRespuesta'] == true || correo['EsRespuesta'] == true;
                final tipo = (correo['tipo'] ?? 'enviado').toString().toLowerCase().trim();
                final estado = esRespuesta ? 'respuesta' : tipo;

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
                                    'detalle_correo_copiaSentencia',
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
      case 'enviado':
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

  Widget _buildDatoFila(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
