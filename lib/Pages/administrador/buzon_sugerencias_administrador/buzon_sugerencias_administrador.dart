import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../commons/main_layaout.dart';

class BuzonSugerenciasAdministradorPage extends StatefulWidget {
  const BuzonSugerenciasAdministradorPage({super.key});

  @override
  State<BuzonSugerenciasAdministradorPage> createState() =>
      _BuzonSugerenciasAdministradorPageState();
}

class _BuzonSugerenciasAdministradorPageState
    extends State<BuzonSugerenciasAdministradorPage> {
  Map<String, bool> leidos = {};
  Map<String, bool> mostrarCajon = {};
  Map<String, TextEditingController> controladoresRespuestas = {};
  Map<String, bool> respuestaEnviada = {};
  // Variables globales
  String? currentUserName;
  String? currentUserLastName;
  Timestamp? currentTime;
  String userId = "";
  String selectedFilter = 'Sin contestar'; // Estado del filtro


  String _formatearFecha(Timestamp timestamp) {
    DateTime fecha = timestamp.toDate();
    return DateFormat('d \'de\' MMMM \'de\' y, hh:mm a', 'es_ES').format(fecha);
  }

  void fetchCurrentTime() {
    currentTime = Timestamp.now();
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentAdminInfo();
    fetchCurrentTime();
    _cargarEstadoRespuestas();
  }


  void _cargarEstadoRespuestas() async {
    FirebaseFirestore.instance.collection('buzon_sugerencias').get().then((querySnapshot) {
      Map<String, bool> tempRespuestaEnviada = {};

      for (var doc in querySnapshot.docs) {
        String id = doc.id;
        bool respondido = doc['contestado'] ?? false; // Leer desde Firestore
        tempRespuestaEnviada[id] = respondido;
      }

      // if (mounted) {
      //   setState(() {
      //     respuestaEnviada = tempRespuestaEnviada;
      //   });
      // }
    });
  }



  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Buzón Sugerencias (Admin)',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 800 ? 800 : double.infinity,
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('buzon_sugerencias')
                .orderBy('fecha_sugerencia', descending: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No hay sugerencias aún.'));
              }

              // 🔹 Obtener conteos
              int totalSugerencias = snapshot.data!.docs.length;
              int contestadas = snapshot.data!.docs.where((doc) => doc['contestado'] == true).length;
              int noContestadas = totalSugerencias - contestadas;

              // 🔹 Filtrar sugerencias según `selectedFilter`
              List<DocumentSnapshot> filteredDocs = snapshot.data!.docs.where((doc) {
                if (selectedFilter == 'Contestadas') return doc['contestado'] == true;
                if (selectedFilter == 'Sin contestar') return doc['contestado'] == false;
                return true; // 'Total' muestra todos
              }).toList();

              return Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10, // Espacio horizontal entre tarjetas
                    runSpacing: 10, // Espacio vertical entre filas
                    children: [
                      _buildInfoCard('Contestadas', contestadas, Colors.black),
                      _buildInfoCard('Sin contestar', noContestadas, Colors.black),
                      _buildInfoCard('Total', totalSugerencias, Colors.black),
                    ],
                  ),

                  const SizedBox(height: 20),
                  if (noContestadas == 0)
                  const Text(
                  'No hay sugerencias sin contestar.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                  else
                  const SizedBox(),
                  // 🔹 Filtrar sugerencias según `selectedFilter`
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        var doc = filteredDocs[index];
                        String userId = doc.id;
                        String fecha = _formatearFecha(doc['fecha_sugerencia']);
                        String nombre = doc['nombre_acudiente'] ?? 'Desconocido';
                        String sugerencia = doc['sugerencia'] ?? 'Sin sugerencia';
                        String celular = doc['celular'] ?? '';

                        String respondidoPor = doc['respondido_por'] ?? '';
                        String respuesta = doc['respuesta'] ?? '';
                        Timestamp? fechaRespuesta = doc['fecha_respuesta'];
                        bool fueRespondida = doc['contestado'] ?? false;

                        return Card(
                          surfaceTintColor: Colors.white,
                          color: Colors.white,
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: fueRespondida ? Colors.green : Colors.red,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.all(5),
                                  title: Row(
                                    children: [
                                      const Icon(Icons.person_pin, size: 16),
                                      const SizedBox(width: 5),
                                      Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(fecha, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      const SizedBox(height: 5),
                                      Text(sugerencia, style: const TextStyle(fontSize: 12, color: Colors.black, height: 1.2)),
                                      if (fueRespondida) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                            const SizedBox(width: 5),
                                            Text('Respondió: $respondidoPor', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        if (fechaRespuesta != null)
                                          Text(
                                            _formatearFecha(fechaRespuesta),
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        const SizedBox(height: 5),
                                        Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 10,
                                          runSpacing: 5,
                                          children: [
                                            const Text(
                                              'Respuesta: ',
                                              style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 5), // 🔹 Forza el salto de línea
                                                Text(
                                                  respuesta,
                                                  style: const TextStyle(fontSize: 12, color: Colors.black, fontStyle: FontStyle.italic, height: 1),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      ]
                                    ],
                                  ),
                                ),
                                if (!fueRespondida)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        'respuesta_sugerencia_page_admin',
                                        arguments: {
                                          'userId': userId,
                                          'nombre': nombre,
                                          'sugerencia': sugerencia,
                                          'celular': celular,
                                        },
                                      );
                                    },
                                    child: const Text('Responder sugerencia'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }



  Future<void> fetchCurrentAdminInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Consultar Firestore para obtener la info del admin
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('admin')
            .doc(user.uid)
            .get();

        if (adminDoc.exists) {
          Map<String, dynamic>? data = adminDoc.data() as Map<String, dynamic>?;

          if (data != null) {
            currentUserName = data['name'] ?? 'Desconocido';
            currentUserLastName = data['apellidos'] ?? 'Desconocido';
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error obteniendo datos del admin: $e");
      }
    }
  }

  // Widget para tarjetas de información
  Widget _buildInfoCard(String title, int count, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = title; // 🔹 Al hacer clic, actualiza el filtro
        });
      },
      child: SizedBox(
        width: 150,
        child: Card(
          color: selectedFilter == title ? Colors.purple : Colors.white, // 🔹 Destacar selección
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selectedFilter == title ? Colors.white : Colors.black, // 🔹 Texto cambia de color si está seleccionado
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: selectedFilter == title ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
