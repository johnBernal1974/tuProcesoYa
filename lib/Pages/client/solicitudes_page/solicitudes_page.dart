import 'package:flutter/material.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';
import '../derecho_de_peticion/derecho_de_peticion.dart';
import '../tutela/tutela.dart';

class SolicitudesdeServicioPage extends StatefulWidget {
  const SolicitudesdeServicioPage({super.key});

  @override
  State<SolicitudesdeServicioPage> createState() => _SolicitudesdeServicioPageState();
}

class _SolicitudesdeServicioPageState extends State<SolicitudesdeServicioPage> {
  final List<String> _opciones = [
    'Derecho de petición',
    'Tutela',
    'Hablar con Tu proceso ya',
  ];

  final Map<String, WidgetBuilder> _servicios = {
    'Derecho de petición': (context) => const DerechoDePeticionPage(),
    'Tutela': (context) => const TutelaPage(),  // Descomentar y agregar la página cuando esté lista
    //'Hablar con Tu proceso ya': (context) => const ChatTuProcesoYaPage(),  // Descomentar cuando esté implementada
  };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return MainLayout(
      pageTitle: 'Solicitudes',
      content: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth >= 1000 ? 1000 : double.infinity,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '"Nuestro objetivo es facilitar el acceso a la justicia para el personal privado '
                      'de la libertad, brindando servicios especializados que agilizan y optimizan '
                      'la gestión de sus derechos. A través de nuestra plataforma, puedes acceder '
                      'a herramientas diseñadas para garantizar una atención eficiente y efectiva '
                      'en cada trámite legal requerido."',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 25),
                const Text(
                  "¿Qué servicio que deseas utilizar?",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: negro,
                    fontSize: 20,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 25),

                // Generación de los elementos desde la lista estática
                Column(
                  children: _opciones.map((opcion) {
                    return InkWell(
                      onTap: () {
                        final pagina = _servicios[opcion];
                        if (pagina != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: pagina),
                          );
                        } else {
                          print('No se encontró la página para $opcion');
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
                              opcion,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
