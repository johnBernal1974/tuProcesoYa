import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class SolicitudesDerechoPeticionAdminPage extends StatefulWidget {
  const SolicitudesDerechoPeticionAdminPage({super.key});

  @override
  State<SolicitudesDerechoPeticionAdminPage> createState() => _SolicitudesDerechoPeticionAdminPageState();
}

class _SolicitudesDerechoPeticionAdminPageState extends State<SolicitudesDerechoPeticionAdminPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String _filtroEstado = "Solicitado"; // Estado por defecto

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitudes de derecho de petición',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
          child: Column(
            children: [
              _buildEstadoCards(),
              const SizedBox(height: 50),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('derechos_peticion_solicitados')
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No hay solicitudes de derecho de petición.",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    // Filtrar documentos según el estado seleccionado
                    var filteredDocs = snapshot.data!.docs.where((doc) {
                      return doc["status"] == _filtroEstado;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning, color: Colors.red, size: 24), // Ícono de advertencia
                            const SizedBox(width: 8), // Espaciado entre el icono y el texto
                            Text(
                              "No hay documentos ${_filtroEstado}s.",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot document = filteredDocs[index];
                        Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                        return _buildSolicitudCard(data, document.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 Widget para las tarjetas de conteo por estado
  Widget _buildEstadoCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('derechos_peticion_solicitados').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        var docs = snapshot.data!.docs;
        int countSolicitado = docs.where((d) => d['status'] == 'Solicitado').length;
        int countDiligenciado = docs.where((d) => d['status'] == 'Diligenciado').length;
        int countRevisado = docs.where((d) => d['status'] == 'Revisado').length;
        int countEnviado = docs.where((d) => d['status'] == 'Enviado').length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEstadoCard("Solicitado", countSolicitado, Colors.red),
            _buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber),
            _buildEstadoCard("Revisado", countRevisado, Theme.of(context).primaryColor),
            _buildEstadoCard("Enviado", countEnviado, Colors.green),
          ],
        );
      },
    );
  }

  // 🔥 Widget para cada tarjeta de estado
  Widget _buildEstadoCard(String estado, int count, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = estado;
        });
      },
      child: Card(
        elevation: _filtroEstado == estado ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            children: [
              Text(estado, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('$count', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 Widget para cada solicitud
  Widget _buildSolicitudCard(Map<String, dynamic> data, String idDocumento) {
    return GestureDetector(
      onTap: () {
        String rutaDestino = obtenerRutaSegunStatus(data['status']);
        Navigator.pushNamed(
          context,
          rutaDestino,
          arguments: {
            'status': data['status'],
            'idDocumento': idDocumento,
            'numeroSeguimiento': data['numero_seguimiento'],
            'categoria': data['categoria'],
            'subcategoria': data['subcategoria'],
            'fecha': data['fecha'].toDate().toString(),
            'idUser': data['idUser'],
            'archivos': data.containsKey('archivos') ? List<String>.from(data['archivos']) : [],
          },
        );
      },
      child: Card(
        color: blancoCards,
        elevation: 5,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("No. Seguimiento: ${data['numero_seguimiento']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(
                    DateFormat("dd 'de' MMMM 'de' yyyy - hh:mm a", 'es').format(data['fecha'].toDate()),
                    style: const TextStyle(fontSize: 12),
                  )
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Categoría: ${data['categoria']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 16, color: getColorEstado(data['status'])), // Círculo con color del estado
                      const SizedBox(width: 5), // Espaciado
                      Text(data['status'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getColorEstado(String estado) {
    switch (estado) {
      case "Solicitado":
        return Colors.red;
      case "Diligenciado":
        return Colors.amber;
      case "Revisado":
        return Colors.deepPurpleAccent; // Puedes cambiarlo por Theme.of(context).primaryColor si lo prefieres
      case "Enviado":
        return Colors.green;
      default:
        return Colors.grey; // Color por defecto si el estado no coincide
    }
  }

  String obtenerRutaSegunStatus(String status) {
    switch (status) {
      case "Enviado":
        return 'derechos_peticion_enviados_por_correo';
      default:
        return 'atender_derecho_peticion_page';
    }
  }
}
