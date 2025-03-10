
import 'package:cloud_firestore/cloud_firestore.dart';
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
    return Column(
      children: [
        _buildBeneficioFila(
          'Permiso Administrativo de 72h',
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
    bool cumple = porcentajeEjecutado >= porcentajeRequerido;
    int diasFaltantes = ((porcentajeRequerido - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Espaciado entre filas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cumple ? Icons.check_circle : Icons.warning, // ✅ Si cumple, ⚠️ si no cumple
                color: cumple ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8), // Espacio entre el ícono y el texto
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cumple ? Colors.green : Colors.red, // Verde si cumple, rojo si no
                  ),
                ),
              ),
              if (!cumple) // Muestra "Restan: X días" solo si aún no cumple
                Text(
                  "Restan: $diasFaltantes días",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 4), // Espacio antes del mensaje dinámico
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
                    color: cumple ? Colors.black : Colors.grey, // Negro si cumple, gris si no
                  ),
                ),
              ),
            ],
          ),
          if (cumple) // 🔥 Si cumple, mostrar el botón
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.centerRight, // Alineado a la izquierda
                child: SizedBox(
                  height: 25,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Fondo verde 🌿
                      foregroundColor: Colors.white, // Texto en blanco
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6), // Bordes redondeados suaves 🟢
                      ),
                    ),
                    onPressed: () {
                      // Aquí puedes agregar la función para manejar la solicitud
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
  Widget _buildCondenaInfo() {
    return Column(
      children: [
        _buildDatoFila("Condena transcurrida", "$mesesEjecutado meses, $diasEjecutadoExactos días"),
        _buildDatoFila("Tiempo redimido", "$mesesEjecutado meses, $diasEjecutadoExactos días"),
        _buildDatoFila("Condena restante", "$mesesRestante meses, $diasRestanteExactos días"),
        _buildDatoFila("Porcentaje ejecutado", "${porcentajeEjecutado.toStringAsFixed(1)}%"),
      ],
    );
  }

  /// 🔹 Cada dato en una fila independiente
  Widget _buildDatoFila(String titulo, String valor) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Título a la izquierda, valor a la derecha
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      );

  }


}
