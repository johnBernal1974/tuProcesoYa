import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../atender_derecho_peticion_admin/atender_derecho_peticion_admin.dart';

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
          // Si el ancho de la pantalla es mayor o igual a 800, usa 800, de lo contrario ocupa todo el ancho disponible
          width: MediaQuery.of(context).size.width >= 1000 ? 600 : double.infinity,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('derechos_peticion_solicitados').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AtenderDerechoPeticionPage(
                                        numeroSeguimiento: document['numero_seguimiento'],
                                        categoria: document['categoria'],
                                        subcategoria: document['subcategoria'],
                                        texto: document['texto'],
                                        fecha: document['fecha'].toDate().toString(),
                                        idUser: document['idUser'],
                                        archivos: document['archivos'].map((e) => e as String).toList(), // Casting a lista de strings
                                      )),
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
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}