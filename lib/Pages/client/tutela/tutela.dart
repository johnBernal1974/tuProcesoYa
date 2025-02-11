import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class TutelaPage extends StatefulWidget {
  const TutelaPage({super.key});

  @override
  State<TutelaPage> createState() => _TutelaPageState();
}

class _TutelaPageState extends State<TutelaPage> {
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
                const Text('Acción de Tutela', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
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
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'La acción de tutela es un mecanismo de protección constitucional que busca proteger de manera '
                                'inmediata los ',
                          ),
                          TextSpan(
                            text: 'derechos fundamentales',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' de todas las personas, cuando se encuentren amenazados '
                                'o vulnerados por parte de cualquier autoridad pública o de algún particular en circunstancias '
                                'específicas.\n\nDebe tenerse en cuenta que la acción de tutela sólo es aceptada por el '
                                'juez cuando el afectado no tenga otro medio judicial para defenderse salvo que se compruebe '
                                'que, existiendo otro medio judicial, este no es idóneo ni eficaz para proteger los ',
                          ),
                          TextSpan(
                            text: 'derechos fundamentales',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' vulnerados y aun cuando el mismo medio judicial sea idóneo, este pierde su eficacia frente '
                                'a la ocurrencia de un perjuicio irremediable, irreparable e inminente. Asimismo, tampoco es '
                                'procedente cuando pueda utilizarse el habeas corpus o cuando se solicite el amparo de '
                                'derechos colectivos.\n\nSegún la Corte Constitucional, un ',
                          ),
                          TextSpan(
                            text: 'derecho fundamental',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' es aquel que posee '
                                'una conexión con la preservación de la dignidad humana entendida esta como la protección de la '
                                'autonomía, la igualdad y la no discriminación y la existencia de condiciones sociales y económicas '
                                'idóneas para el sujeto. Ejemplo de ',
                          ),
                          TextSpan(
                            text: 'derechos fundamentales',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' en el campo del derecho penitenciario '
                                'son, entre otros, el derecho a la salud, a la información, de petición, al debido proceso, '
                                'a la unidad familiar, a la igualdad y al trabajo.',
                          ),
                        ],
                      ),
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
                      'La acción de tutela sirve para que un juez emita una orden dirigida a la autoridad pública o al particular, según '
                          'corresponda, con el fin de que estos cesen las actividades amenazadoras o vulneradoras '
                          'del derecho fundamental. Igualmente, para que estos sujetos tomen las medidas necesarias '
                          'para evitar dicha vulneración y se garanticen los derechos fundamentales del solicitante.\n\n'
                          'Cuando sean particulares los accionados, la tutela es procedente en los siguientes casos: relación '
                          'de subordinación (como un contrato laboral); relación de indefensión (en las situaciones '
                          'en donde haya una relación de poder) o que esté encargado de la prestación de servicios públicos',
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
                    Navigator.pushNamed(context, "tutela_solicitud");
                  },
                  child: const Text('Crear acción de tutela'),
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
