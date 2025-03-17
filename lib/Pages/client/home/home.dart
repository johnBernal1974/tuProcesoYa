
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import '../../../commons/main_layaout.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../controllers/tiempo_condena_controller.dart';
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
  double totalDiasRedimidos = 0;
  late CalculoCondenaController _calculoCondenaController;

  @override
  void initState() {
    super.initState();
    _myAuthProvider = MyAuthProvider();
    _calculoCondenaController = CalculoCondenaController(PplProvider()); // 🔥 Instanciar el controlador
    _loadUid();
  }

  Future<void> _loadUid() async {
    final user = _myAuthProvider.getUser();
    if (user != null) {
      setState(() {
        _uid = user.uid;
      });

      await _loadData(); // 🔥 Cargar datos generales del usuario

      // 🔥 Calcular la condena directamente con el controlador
      await _calculoCondenaController.calcularTiempo(_uid);
    }
  }



  Future<void> _loadData() async {
    final pplData = await _pplProvider.getById(_uid);

    if (mounted) {
      setState(() {
        _ppl = pplData;
        _isPaid = pplData?.isPaid ?? false;
        _isLoading = false;
      });

      // 🔥 Calcular tiempo y actualizar valores en setState
      await _calculoCondenaController.calcularTiempo(_uid);
      setState(() {
        porcentajeEjecutado = _calculoCondenaController.porcentajeEjecutado!;
        tiempoCondena = _calculoCondenaController.tiempoCondena!;
      });

      print("✅ Datos actualizados:");
      print("   - porcentajeEjecutado: $porcentajeEjecutado%");
      print("   - tiempoCondena: $tiempoCondena meses");
    }
  }


  Future<double> calcularTotalRedenciones(String pplId) async {
    double totalDiasRedimidos = 0;

    try {
      QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('redenciones')
          .get();

      for (var doc in redencionesSnapshot.docs) {
        double dias = (doc['dias_redimidos'] ?? 0).toDouble();
        totalDiasRedimidos += dias;
      }

      debugPrint("🔹 Total días redimidos: $totalDiasRedimidos");
    } catch (e) {
      debugPrint("❌ Error al calcular total de redenciones: $e");
    }

    return totalDiasRedimidos;
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
        Text(
          "NUI: ${_ppl?.nui ?? "No disponible"}     TD: ${_ppl?.td ?? "No disponible"}",
          style: const TextStyle(fontSize: 14, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco para contraste
            borderRadius: BorderRadius.circular(8), // Bordes suavemente redondeados
            border: Border.all(color: Colors.grey, width: 1), // Línea gris delgada
          ),
          padding: const EdgeInsets.all(12), // Espaciado interno
          child: Column(
            children: [
              const Text(
                "Datos de la condena",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Divider(color: Colors.grey), // Línea divisoria interna
              _buildCondenaInfo(),
            ],
          ),
        ),

        const SizedBox(height: 30),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco
            borderRadius: BorderRadius.circular(8), // Bordes suavemente redondeados
            border: Border.all(color: Colors.grey, width: 1), // Línea gris delgada
          ),
          padding: const EdgeInsets.all(12), // Espaciado interno
          child: Column(
            children: [
              const Text(
                "Beneficios obtenidos",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Divider(color: Colors.grey), // Línea divisoria interna
              _buildBeneficiosList(),
            ],
          ),
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
            backgroundColor: primary, // Color de fondo del botón
          ),
          onPressed: () async {
            // Navegar a la pantalla CheckoutWompi y permitir volver
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CheckoutPage()),
            );

            // Verificar si el usuario regresó con algún resultado
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Regresaste de CheckoutWompi: $result"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Text('Realizar pago', style: TextStyle(color: blanco)),
        ),

      ],
    );
  }

  // para isPid false
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

  // para isPaid true
  Widget _buildBeneficiosList() {
    print("🔍 Construyendo Beneficios - Valores actuales:");
    print("   - porcentajeEjecutado: $porcentajeEjecutado%");
    print("   - tiempoCondena: $tiempoCondena meses");

    return Column(
      children: [
        _buildBeneficioFila(
          'Permiso de 72h',
          33.33,
          'salir del centro de reclusión por un periodo de 72 horas.',
        ),
        const Divider(color: gris),
        _buildBeneficioFila(
          'Prisión Domiciliaria',
          50,
          'cumplir el resto de la condena en su domicilio bajo vigilancia.',
        ),
        const Divider(color: gris),
        _buildBeneficioFila(
          'Libertad Condicional',
          60,
          'obtener la libertad bajo ciertas condiciones y supervisión.',
        ),
        const Divider(color: gris),
        _buildBeneficioFila(
          'Extinción de la Pena',
          100,
          'obtener su libertad definitiva.',
        ),
      ],
    );
  }


  // para idPaid true
  Widget _buildBeneficioFila(String titulo, double porcentajeRequerido, String accion) {
    double porcentaje = _calculoCondenaController.porcentajeEjecutado ?? 0.0;
    int tiempo = _calculoCondenaController.tiempoCondena ?? 0;

    bool cumple = porcentaje >= porcentajeRequerido;
    int diasFaltantes = ((porcentajeRequerido - porcentaje) / 100 * tiempo * 30).ceil();

    print("🔍 Beneficio: $titulo - porcentaje: $porcentaje% - Condena: $tiempo meses");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cumple ? Icons.check_circle : Icons.warning,
                color: cumple ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cumple ? Colors.green : Colors.red,
                  ),
                ),
              ),
              if (!cumple)
                Text(
                  "Restan: $diasFaltantes días",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  cumple
                      ? "Ya se puede solicitar para $accion"
                      : "No se ha cumplido el tiempo establecido para obtener este beneficio.",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cumple ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (cumple)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 25,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      print("Se ha solicitado el beneficio de $titulo");
                    },
                    child: const Text("Solicitar"),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }



  //para isPaid en false
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

  // para isPaid en false
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
              oculto ? '... ??' : valor,
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

  Future<void> calcularTiempo(String id, double diasRedimidos) async {
    final pplData = await _pplProvider.getById(id);
    if (pplData != null) {
      final fechaCaptura = pplData.fechaCaptura;
      tiempoCondena = pplData.tiempoCondena;
      final fechaActual = DateTime.now();

      // 🔹 Restamos los días redimidos a la condena
      final tiempoCondenaReducida = tiempoCondena! * 30 - diasRedimidos.toInt();
      final fechaFinCondena = fechaCaptura?.add(Duration(days: tiempoCondenaReducida));

      final diferenciaRestante = fechaFinCondena?.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura!);

      setState(() {
        mesesRestante = (diferenciaRestante!.inDays ~/ 30);
        diasRestanteExactos = diferenciaRestante.inDays % 30;

        mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
        diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;
        porcentajeEjecutado = ((diferenciaEjecutado.inDays + diasRedimidos) / (tiempoCondena! * 30)) * 100;
      });

      print("Porcentaje de condena ejecutado: $porcentajeEjecutado%");
    } else {
      print("No hay datos");
    }
  }

  Widget _buildCondenaInfo() {
    // 🔥 Validamos que no haya valores nulos antes de usarlos
    int mesesEjecutado = _calculoCondenaController.mesesEjecutado ?? 0;
    int diasEjecutadoExactos = _calculoCondenaController.diasEjecutadoExactos ?? 0;
    double totalDiasRedimidos = _calculoCondenaController.totalDiasRedimidos ?? 0;
    int mesesRestante = _calculoCondenaController.mesesRestante ?? 0;
    int diasRestanteExactos = _calculoCondenaController.diasRestanteExactos ?? 0;
    double porcentajeEjecutado = _calculoCondenaController.porcentajeEjecutado ?? 0.0;
    int tiempoCondena = _calculoCondenaController.tiempoCondena ?? 0; // 🔹 Condena total

    int totalDiasCumplidos = diasEjecutadoExactos + totalDiasRedimidos.toInt();
    int mesesAdicionales = totalDiasCumplidos ~/ 30;
    int diasRestantes = totalDiasCumplidos % 30;
    int mesesCumplidos = mesesEjecutado + mesesAdicionales;

    return Column(
      children: [
        // 🔥 Fila con fondo resaltado para "Condenado a"
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Condenado a",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                "$tiempoCondena meses",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        _buildDatoFila("Condena transcurrida", "$mesesEjecutado meses, $diasEjecutadoExactos días"),
        _buildDatoFila("Tiempo redimido", "$totalDiasRedimidos días"),


        // 🔥 Animación para "Condena total cumplida"
        _buildAnimatedDato("Condena\nTotal Cumplida", mesesCumplidos, diasRestantes, Colors.green.shade200),

        // 🔥 Animación para "Condena restante"
        _buildAnimatedDato("Condena\nRestante", mesesRestante, diasRestanteExactos, Colors.purple.shade100),
        const SizedBox(height: 10),
        _buildDatoFila("Porcentaje ejecutado", "${porcentajeEjecutado.toStringAsFixed(1)}%"),
      ],
    );
  }

  /// **Widget para animar los valores de la condena y su elevación**
  Widget _buildAnimatedDato(String title, int meses, int dias, Color bgColor) {
    return TweenAnimationBuilder(
      duration: const Duration(seconds: 3),
      tween: IntTween(begin: 0, end: meses),
      builder: (context, int mesesAnim, child) {
        return TweenAnimationBuilder(
          duration: const Duration(seconds: 3),
          tween: IntTween(begin: 0, end: dias),
          builder: (context, int diasAnim, child) {
            return TweenAnimationBuilder(
              duration: const Duration(seconds: 3),
              tween: Tween<double>(begin: 0, end: 1), // 🔥 Opacidad del borde
              builder: (context, double borderOpacity, child) {
                return TweenAnimationBuilder(
                  duration: const Duration(seconds: 3),
                  tween: Tween<double>(begin: 6, end: 20), // 🔥 Elevación mucho más alta
                  builder: (context, double elevation, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withOpacity(borderOpacity), // 🔥 Se dibuja el borde con animación
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: elevation,
                            offset: Offset(0, elevation / 2), // 🔥 Sombra con mayor elevación
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, height: 1.1, color: negro),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "$mesesAnim meses",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                "$diasAnim días",
                                style: const TextStyle(fontSize: 11, height: 1.1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }



  /// 🔹 Cada dato en una fila independiente con mejor alineación
  Widget _buildDatoFila(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // 🔹 Espaciado entre filas
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Título a la izquierda, valor a la derecha
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

}
