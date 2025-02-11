import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class DerechoDePeticionPage extends StatefulWidget {
  const DerechoDePeticionPage({super.key});

  @override
  State<DerechoDePeticionPage> createState() => _DerechoDePeticionPageState();
}

class _DerechoDePeticionPageState extends State<DerechoDePeticionPage> {
  bool _showQueEs = false;
  bool _showParaQueSirve = false;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitud de servicio',
      content: SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Derecho de Petición', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: !_showQueEs
                      ? BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  )
                      : null,
                  child: ListTile(
                    title: const Text('¿Qué es?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    trailing: Icon(_showQueEs ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    onTap: () {
                      setState(() {
                        _showQueEs = !_showQueEs;
                      });
                    },
                  ),
                ),
                if (_showQueEs)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'El derecho de petición es un derecho fundamental (art. 23 CP) de todas las personas consistente en la '
                          'posibilidad de elevar solicitudes y/o peticiones respetuosas a las autoridades -sin que estas puedan negarse '
                          'a recibirlas o tramitarlas-; la respuesta debe ser oportuna dentro de los términos que la ley establece, una '
                          'respuesta completa y de fondo, según lo planteado en la solicitud, de tal manera que exista plena correspondencia '
                          'entre la petición y la respuesta sin evasivas o elusivas.\n\nDe acuerdo con la Corte Constitucional, es '
                          'obligatorio para el Estado garantizar un canal de comunicación entre el interno, las autoridades administrativas '
                          'y la administración de justicia, pues en muchas ocasiones el derecho de petición es “el único mecanismo que tienen '
                          'las personas privadas de la libertad para hacer efectivas las obligaciones estatales, y de esta manera hacer valer '
                          'sus derechos fundamentales” (Sentencia T- 825 de 2009, M.P. Luis Ernesto Vargas Silva).',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: !_showParaQueSirve
                      ? BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  )
                      : null,
                  child: ListTile(
                    title: const Text('¿Para qué sirve?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    trailing: Icon(_showParaQueSirve ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    onTap: () {
                      setState(() {
                        _showParaQueSirve = !_showParaQueSirve;
                      });
                    },
                  ),
                ),
                if (_showParaQueSirve)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'El derecho de petición tiene distintos usos, los más comunes son: el reconocimiento de un derecho, '
                          'la intervención de una entidad o funcionario, la resolución de una situación jurídica, '
                          'la prestación de un servicio, requerir información, consultar, examinar y requerir copias de documentos, '
                          'formular consultas, quejas, denuncias y reclamos e interponer recursos. Debe observarse que se '
                          'excluye información expresamente catalogada como reservada (secreta) en virtud de la Constitución o la Ley.',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.justify,
                    ),
                  ),

                const SizedBox(height: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: primary,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, "derecho_peticion_solicitud");
                  },
                  child: const Text('Crear derecho de petición'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
