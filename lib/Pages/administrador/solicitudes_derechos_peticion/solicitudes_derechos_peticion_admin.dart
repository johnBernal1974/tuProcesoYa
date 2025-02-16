import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';

class SolicitudesDerechoPeticionAdminPage extends StatefulWidget {
  const SolicitudesDerechoPeticionAdminPage({super.key});

  @override
  State<SolicitudesDerechoPeticionAdminPage> createState() => _SolicitudesDerechoPeticionAdminPageState();
}

class _SolicitudesDerechoPeticionAdminPageState extends State<SolicitudesDerechoPeticionAdminPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitudes de derecho de petición',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 600 : double.infinity,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('derechos_peticion_solicitados').snapshots(),
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
                  return Column(
                    children: [
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              title: Text("No: ${document['numero_seguimiento']}", style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 12
                              ),),
                              subtitle: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(text: 'Categoría: ', style: TextStyle(fontSize: 12)),
                                    TextSpan(text: document['categoria'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    const TextSpan(text: '\n\nFecha de solicitud: ', style: TextStyle(fontSize: 12)),
                                    TextSpan(text: DateFormat('yyyy-MM-dd HH:mm').format(document['fecha'].toDate()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.double_arrow),
                                onPressed: () {
                                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;

                                  // Extraer preguntas y respuestas del campo "preguntas_respuestas"
                                  List<Map<String, dynamic>> preguntasRespuestas = data.containsKey('preguntas_respuestas')
                                      ? List<Map<String, dynamic>>.from(data['preguntas_respuestas'])
                                      : [];

                                  List<String> preguntas = preguntasRespuestas.map((e) => e['pregunta'].toString()).toList();
                                  List<String> respuestas = preguntasRespuestas.map((e) => e['respuesta'].toString()).toList();

                                  Navigator.pushNamed(
                                    context,
                                    'atender_derecho_peticion_page',
                                    arguments: {
                                      'numeroSeguimiento': data['numero_seguimiento'],
                                      'categoria': data['categoria'],
                                      'subcategoria': data['subcategoria'],
                                      'fecha': data['fecha'].toDate().toString(),
                                      'idUser': data['idUser'],
                                      'archivos': data.containsKey('archivos') ? List<String>.from(data['archivos']) : [],
                                      'preguntas': preguntas, // ✅ Lista de preguntas extraída correctamente
                                      'respuestas': respuestas, // ✅ Lista de respuestas extraída correctamente
                                    },
                                  );
                                },

                              ),
                            ),
                            const SizedBox(height: 10)
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
}