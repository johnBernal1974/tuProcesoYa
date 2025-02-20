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
  int _maxLines = 1; // Empieza con 1 línea




  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitudes de derecho de petición',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.
            collection('derechos_peticion_solicitados')
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

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];

                  // Extraer datos del documento
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                  // Extraer preguntas y respuestas
                  List<Map<String, dynamic>> preguntasRespuestas = data.containsKey('preguntas_respuestas')
                      ? List<Map<String, dynamic>>.from(data['preguntas_respuestas'])
                      : [];

                  List<String> preguntas = preguntasRespuestas.map((e) => e['pregunta'].toString()).toList();
                  List<String> respuestas = preguntasRespuestas.map((e) => e['respuesta'].toString()).toList();

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // 🔥 Validamos a qué página redirigir según el status
                          String rutaDestino = obtenerRutaSegunStatus(data['status']);

                          Navigator.pushNamed(
                            context,
                            rutaDestino,
                            arguments: {
                              'status': data['status'],
                              'idDocumento': document.id,
                              'numeroSeguimiento': data['numero_seguimiento'],
                              'categoria': data['categoria'],
                              'subcategoria': data['subcategoria'],
                              'fecha': data['fecha'].toDate().toString(),
                              'idUser': data['idUser'],
                              'archivos': data.containsKey('archivos') ? List<String>.from(data['archivos']) : [],
                              'preguntas': preguntas,
                              'respuestas': respuestas,
                            },
                          );
                        },
                        child: SizedBox(
                          width: 1000,
                          child: Card(
                            color: blancoCards,
                            surfaceTintColor: blancoCards,
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("No. Seguimiento", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text("${data['numero_seguimiento']}", style: const TextStyle(
                                              fontWeight: FontWeight.w900, fontSize: 12
                                          )),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text("Fecha de solicitud", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text(DateFormat('yyyy-MM-dd HH:mm').format(data['fecha'].toDate()), style: const TextStyle(
                                              fontWeight: FontWeight.w900, fontSize: 12
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Categoría", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text("${data['categoria']}", style: const TextStyle(
                                              fontWeight: FontWeight.w900, fontSize: 12
                                          )),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text("", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 20,
                                                color: getColorEstado(data['status']), // Color del ícono
                                              ),
                                              const SizedBox(width: 5),
                                              Text("${data['status']}", style: const TextStyle(
                                                  fontWeight: FontWeight.w900, fontSize: 12
                                              )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  String obtenerRutaSegunStatus(String status) {
    switch (status) {
      case "Enviado":
        return 'derechos_peticion_enviados_por_correo';
      default:
        return 'atender_derecho_peticion_page'; // Ruta por defecto en caso de error
    }
  }

  // Función que devuelve el color según el estado
  Color getColorEstado(String estado) {
    switch (estado) {
      case "Solicitado":
        return Colors.red;
      case "Diligenciado":
        return Colors.amber;
      case "Revisado":
        return Theme.of(context).primaryColor;
      case "Enviado":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}