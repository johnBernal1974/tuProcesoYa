import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../commons/main_layaout.dart';
import '../../src/colors/colors.dart';
import '../derecho_de_peticion/derecho_de_peticion.dart';

class SolicitudesdeServicioPage extends StatefulWidget {
  const SolicitudesdeServicioPage({super.key});

  @override
  State<SolicitudesdeServicioPage> createState() => _SolicitudesdeServicioPageState();
}

class _SolicitudesdeServicioPageState extends State<SolicitudesdeServicioPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return MainLayout(
      pageTitle: 'Solicitudes',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/logo_tu_proceso_ya_transparente.png', height: 40),
          const SizedBox(height: 15),
          const Text("Selecciona el servicio que deseas se adelante mediante la plataforma.",
            style: TextStyle(
                fontWeight: FontWeight.w500,
                color: negro,
                fontSize: 14,
                height: 1
            ),
          ),
          const SizedBox(height: 25),

          FutureBuilder(
            future: FirebaseFirestore.instance.collection('Servicios').get(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    return InkWell(
                      onTap: () {
                        final pagina = _servicios[doc['nombreServicio']];
                        if (pagina != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: pagina),
                          );
                        } else {
                          // Manejar el caso cuando no se encuentra la página
                          print('No se encontró la página para ${doc['nombreServicio']}');
                        }
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Theme.of(context).primaryColor, width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 1,
                        child: Container(
                          width: screenWidth * 0.9, // ancho fijo
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              doc['nombreServicio'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }
  // Debes agregar este mapa en la clase _SolicitudesdeServicioPageState
  final Map<String, WidgetBuilder> _servicios = {
    'Derecho de petición': (context) => const DerechoDePeticionPage(),
    //'Otro Servicio': (context) => const OtraPagina(),
    // Agregar más servicios aquí
  };
}