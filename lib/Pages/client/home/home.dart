
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../../commons/main_layaout.dart';
import '../../../models/ppl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ppl_provider.dart';

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
  bool _isPaid = false;
  bool _isLoading = true; // 🔹 Nuevo estado para evitar mostrar la UI antes de validar



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
    if (mounted) {
      setState(() {
        _ppl = pplData;
        _isPaid = pplData?.isPaid ?? false;
        _isLoading = false; // 🔹 Solo cuando termine de cargar
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Página Principal',
      content: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 🔹 No carga la UI hasta tener datos
          : SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 800 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo_tu_proceso_ya_transparente.png', height: 40),
              Text(
                'Hoy es: ${DateFormat('d \'de\' MMMM \'de\' y', 'es').format(DateTime.now())}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              _isPaid ? _buildPaidContent() : _buildUnpaidContent(),
            ],
          ),
        ),
      ),
    );
  }


  /// Contenido si el usuario **ha pagado**
  Widget _buildPaidContent() {
    return Column(
      children: [
        Text(
          "${_ppl?.nombrePpl ?? ""} ${_ppl?.apellidoPpl ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCondenaCard('Tiempo de\nCondena\ntranscurrida', mesesEjecutado, diasEjecutadoExactos),
            const SizedBox(width: 10),
            _buildCondenaCard('Tiempo de\nCondena\nrestante', mesesRestante, diasRestanteExactos),
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
    );
  }

  /// Contenido si el usuario **no ha pagado**
  Widget _buildUnpaidContent() {
    return Column(
      children: [
        Text(
          "${_ppl?.nombrePpl ?? ""} ${_ppl?.apellidoPpl ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          "NUI: ${_ppl?.nui ?? "No disponible"}     TD: ${_ppl?.td ?? "No disponible"}",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCondenaCard('Tiempo de\nCondena\ntranscurrida', 0, 0, oculto: true),
            const SizedBox(width: 10),
            _buildCondenaCard('Tiempo de\nCondena\nrestante', 0, 0, oculto: true),
          ],
        ),
         Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             _buildPorcentajeCard(0, oculto: true),
             const SizedBox(width: 10),
             _buildBeneficioCard("Beneficios adquiridos por tiempo", "0 días", oculto: true),
           ],
         ),
        const SizedBox(height: 50),
        const Text(
          '¡Has el pago de la suscripción!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primary, height: 1.1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Text(
          'Accede a una experiencia completa y exclusiva en nuestra plataforma. Desbloquea todos los beneficios y servicios que tenemos para ti.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary
          ),
          onPressed: () {
            // Acción para realizar el pago
          },
          child: const Text('Realizar pago', style: TextStyle(color: blanco)),
        ),
      ],
    );
  }

  /// **Modificación en _buildCondenaCard()**
  Widget _buildCondenaCard(String title, int meses, int dias, {bool oculto = false}) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: oculto ? Colors.grey.shade400 : primary, width: 1),
        borderRadius: BorderRadius.circular(oculto ? 8 : 4),
      ),
      elevation: 2,
      child: Container(
        width: oculto ? 120 : null, // Ancho fijo si es oculto
        constraints: const BoxConstraints(minHeight: 80), // Altura mínima
        decoration: BoxDecoration(
          color: Colors.white, // Fondo blanco
          borderRadius: BorderRadius.circular(oculto ? 8 : 4),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1,
                color: oculto ? Colors.grey.shade700 : Colors.black, // Texto más oscuro si no es oculto
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              oculto ? '... meses' : '$meses meses : $dias días',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: oculto ? Colors.grey.shade500 : Colors.black87, // Más oscuro si está visible
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPorcentajeCard(double porcentaje, {bool oculto = false}) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: Container(
        width: 120, // Ancho fijo
        constraints: const BoxConstraints(minHeight: 80), // Altura mínima
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // Fondo gris claro para efecto de borrador
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Porcentaje de condena ejecutado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1,
                color: Colors.grey.shade700, // Texto en tono gris oscuro
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              oculto ? '... %' : '${porcentaje.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: oculto ? Colors.grey.shade500 : Colors.black87, // Diferenciación de colores
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficioCard(String titulo, String valor, {bool oculto = false}) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 2,
      child: Container(
        width: 120, // Ancho fijo
        constraints: const BoxConstraints(minHeight: 80), // Altura mínima
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // Fondo gris claro para efecto de borrador
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1,
                color: Colors.grey.shade700, // Texto en tono gris oscuro
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              oculto ? '... Cumplido' : valor,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: oculto ? Colors.grey.shade500 : Colors.black87, // Diferenciación de colores
              ),
            ),
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
