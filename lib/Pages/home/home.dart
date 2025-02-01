import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import '../../commons/main_layaout.dart';
import '../../models/ppl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ppl_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late MyAuthProvider _myAuthProvider;
  late String _uid;
  Ppl? _ppl;
  final PplProvider _pplProvider = PplProvider();
  int diasEjecutado = 0;
  int mesesEjecutado = 0;
  int diasEjecutadoExactos = 0;

  int diasRestante = 0;
  int mesesRestante = 0;
  int diasRestanteExactos = 0;
  double porcentajeEjecutado =0;
  int tiempoCondena =0;


  @override
  void initState() {
    super.initState();
    _myAuthProvider = MyAuthProvider();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final user = _myAuthProvider.getUser();
    if (user != null) {
      setState(() {
        _uid = user.uid;
      });
      await _loadData();
      calcularTiempo(_myAuthProvider.getUser()!.uid);

    }
  }

  Future<void> _loadData() async {
    final pplProvider = PplProvider();
    final pplData = await pplProvider.getById(_uid);
    setState(() {
      _ppl = pplData;
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return MainLayout(
      pageTitle: 'Página Principal',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo_tu_proceso_ya_transparente.png', height: 40),
            Text(
              'Hoy es: ${DateFormat('d \'de\' MMMM \'de\' y', 'es').format(DateTime.now())}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text("${_ppl?.nombrePpl ?? ""} ${_ppl?.apellidoPpl ?? ""}", style: const TextStyle(
              fontWeight: FontWeight.bold
            ), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: primary, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Tiempo de condena\ntranscurrido',
                            style: TextStyle(fontSize: screenWidth > 600 ? 16 : 11, fontWeight: FontWeight.bold,
                            color: negroLetras),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mesesEjecutado == 1
                                ? diasEjecutadoExactos == 1
                                ? '$mesesEjecutado mes : $diasEjecutadoExactos día'
                                : '$mesesEjecutado mes : $diasEjecutadoExactos días'
                                : diasEjecutadoExactos == 1
                                ? '$mesesEjecutado meses : $diasEjecutadoExactos día'
                                : '$mesesEjecutado meses : $diasEjecutadoExactos días',
                            style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Card(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: primary, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Tiempo de condena\nrestante',
                            style: TextStyle(fontSize: screenWidth > 600 ? 16 : 11, fontWeight: FontWeight.bold,
                            color: negroLetras),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mesesRestante == 1
                                ? diasRestanteExactos == 1
                                ? '$mesesRestante mes : $diasRestanteExactos día'
                                : '$mesesRestante mes : $diasRestanteExactos días'
                                : mesesRestante > 0
                                ? diasRestanteExactos == 1
                                ? '$mesesRestante meses : $diasRestanteExactos día'
                                : '$mesesRestante meses : $diasRestanteExactos días'
                                : diasRestanteExactos == 1
                                ? '$diasRestanteExactos día'
                                : '$diasRestanteExactos días',
                            style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Porcentaje de condena ejecutado: ${porcentajeEjecutado.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            Column(
              children: [
                _buildBenefitCard(
                  title: 'Permiso Administrativo de 72 horas',
                  condition: porcentajeEjecutado >= 33.33,
                  remainingTime: ((33.33 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                ),
                _buildBenefitCard(
                  title: 'Prisión Domiciliaria',
                  condition: porcentajeEjecutado >= 50,
                  remainingTime: ((50 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                ),
                _buildBenefitCard(
                  title: 'Libertad Condicional',
                  condition: porcentajeEjecutado >= 60,
                  remainingTime: ((60 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                ),
                _buildBenefitCard(
                  title: 'Extinción de la Pena',
                  condition: porcentajeEjecutado >= 100,
                  remainingTime: ((100 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard({required String title, required bool condition, required int remainingTime}) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: condition ? Colors.green : Colors.red, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      elevation: 3,
      color: condition ? Colors.green : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              condition ? Icons.notifications : Icons.access_time, // Cambia a reloj si la tarjeta es roja
              color: condition ? Colors.white : Colors.black, // Negro si la tarjeta es roja
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: condition
                          ? 'Se ha completado el tiempo establecido para acceder al beneficio de '
                          : 'Aún no se puede acceder a ',
                      style: TextStyle(
                        fontSize: 12,
                        color: condition ? Colors.white : Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: title, // Texto en negrilla
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold, // Negrilla
                        color: condition ? Colors.white : Colors.black,
                      ),
                    ),
                    if (!condition) // Solo agregar este texto si la condición es falsa
                      TextSpan(
                        text: '. Faltan $remainingTime días para completar el tiempo establecido.',
                        style: TextStyle(
                          fontSize: 12,
                          color: condition ? Colors.white : Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Future<void> calcularTiempo(String id) async {
    final pplData = await _pplProvider.getById(id);
    if (pplData != null) {
      final fechaCaptura = pplData.fechaCaptura;
      tiempoCondena = pplData.tiempoCondena;
      final fechaActual = DateTime.now();
      final fechaFinCondena = fechaCaptura?.add(Duration(days: tiempoCondena * 30));

      final diferenciaRestante = fechaFinCondena?.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura!);

      setState(() {
        mesesRestante = (diferenciaRestante!.inDays ~/ 30)!;
        diasRestanteExactos = diferenciaRestante.inDays % 30;

        mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
        diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;
      });

      // Validaciones para beneficios
      porcentajeEjecutado = (diferenciaEjecutado.inDays / (tiempoCondena * 30)) * 100;
      print("Porcentaje de condena ejecutado: $porcentajeEjecutado%");

      if (porcentajeEjecutado >= 33.33) {
        print("Se aplica el beneficio de permiso administrativo de 72 horas");
      } else {
        print("No se aplica el beneficio de permiso administrativo de 72 horas");
      }

      if (porcentajeEjecutado >= 50) {
        print("Se aplica el beneficio de prisión domiciliaria");
      } else {
        print("No se aplica el beneficio de prisión domiciliaria");
      }

      if (porcentajeEjecutado >= 60) {
        print("Se aplica el beneficio de libertad condicional");
      } else {
        print("No se aplica el beneficio de libertad condicional");
      }

      if (porcentajeEjecutado >= 100) {
        print("Se aplica el beneficio de extinción de la pena");
      } else {
        print("No se aplica el beneficio de extinción de la pena");
      }

      print("Tiempo restante: $mesesRestante meses y $diasRestanteExactos días");
      print("Tiempo ejecutado: $mesesEjecutado meses y $diasEjecutadoExactos días");
    } else {
      print("No hay datos");
    }
  }
}
