import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/admin_provider.dart';
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
  String rol = AdminProvider().rol ?? "";
  bool _isLoadingRole = true; // Indicador de carga para el rol

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
    // Otras inicializaciones, por ejemplo:
    // _fetchPendingSuggestions();
  }

  Future<void> _loadAdminRole() async {
    await AdminProvider().loadAdminData();
    setState(() {
      rol = AdminProvider().rol!;
      // Si el rol es "pasante 2", establecer el filtro por defecto a "Diligenciado"
      if (rol == "pasante 2") {
        _filtroEstado = "Diligenciado";
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitudes de derecho de petición',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
          child: Column(
            children: [
              _buildEstadoCards(rol),
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
                      // Para pasante 2, si el filtro es "Solicitado" no se muestra mensaje,
                      // pero si es "Diligenciado" u otro, se muestra normalmente.
                      if (rol == "pasante 2" && _filtroEstado == "Solicitado") {
                        return Container();
                      } else {
                        return Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning, color: Colors.red, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "No hay documentos ${_filtroEstado}s.",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }
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
  Widget _buildEstadoCards(String role) {
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

        List<Widget> cards = [];

        if (role == "pasante 1") {
          // Para pasante 1 se muestran "Solicitado" y "Diligenciado"
          cards.add(_buildEstadoCard("Solicitado", countSolicitado, Colors.red));
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
        } else if (role == "pasante 2") {
          // Para pasante 2 se muestran "Diligenciado", "Revisado" y "Enviado"
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
          cards.add(_buildEstadoCard("Revisado", countRevisado, Theme.of(context).primaryColor));
          cards.add(_buildEstadoCard("Enviado", countEnviado, Colors.green));
        } else {
          // Para los demás roles se muestran todas las cards
          cards.add(_buildEstadoCard("Solicitado", countSolicitado, Colors.red));
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
          cards.add(_buildEstadoCard("Revisado", countRevisado, Theme.of(context).primaryColor));
          cards.add(_buildEstadoCard("Enviado", countEnviado, Colors.green));
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: cards,
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
    // Extraer preguntas y respuestas
    List<Map<String, dynamic>> preguntasRespuestas = data.containsKey('preguntas_respuestas')
        ? List<Map<String, dynamic>>.from(data['preguntas_respuestas'])
        : [];

    List<String> preguntas = preguntasRespuestas.map((e) => e['pregunta'].toString()).toList();
    List<String> respuestas = preguntasRespuestas.map((e) => e['respuesta'].toString()).toList();

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
            'preguntas': preguntas, // ✅ Añadimos preguntas
            'respuestas': respuestas, // ✅ Añadimos respuestas
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
                      Icon(Icons.circle, size: 16, color: getColorEstado(data['status'])),
                      const SizedBox(width: 5),
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
