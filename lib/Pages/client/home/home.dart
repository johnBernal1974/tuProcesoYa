
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
import 'package:rxdart/rxdart.dart';


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
  bool _isTrial = false;
  int _diasRestantesPrueba = 0;
  int? _subscriptionValue;
  Map<String, String> _statusSolicitudes = {};
  bool _statusLoaded = false;
  int _tiempoDePrueba = 7; // valor por defecto si no está en Firebase





  @override
  void initState() {
    super.initState();
    _myAuthProvider = MyAuthProvider();
    _cargarValorSuscripcion();
    _calculoCondenaController = CalculoCondenaController(PplProvider()); // 🔥 Instanciar el controlador
    _loadUid();
  }

  Future<void> _cargarValorSuscripcion() async {
    final config = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    if (config.docs.isNotEmpty) {
      setState(() {
        _subscriptionValue = config.docs.first.data()['valor_subscripcion'];
        _tiempoDePrueba = config.docs.first.data()['tiempoDePrueba'] ?? 7; // 🔥 Aquí traemos el tiempo real
      });
    }
  }

  Future<void> _loadUid() async {
    final user = _myAuthProvider.getUser();
    if (user != null) {
      setState(() {
        _uid = user.uid;
      });
      await _calculoCondenaController.calcularTiempo(_uid);
      await _cargarStatusSolicitudes();
      await _cargarDatosPplYValidarTrial(); // 🔥 Aquí ya se calcula correctamente el Trial.
    }
  }

  Future<void> _cargarDatosPplYValidarTrial() async {
    final doc = await FirebaseFirestore.instance.collection('Ppl').doc(_uid).get();
    if (doc.exists) {
      _ppl = Ppl.fromDocumentSnapshot(doc);
      final fechaRegistro = _ppl?.fechaRegistro;
      if (fechaRegistro != null) {
        final now = DateTime.now();
        final diasPasados = now.difference(fechaRegistro).inDays;
        final configDoc = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
        int tiempoDePrueba = configDoc.docs.first.data()['tiempoDePrueba'] ?? 7;

        setState(() {
          _isTrial = diasPasados < tiempoDePrueba;
          _diasRestantesPrueba = tiempoDePrueba - diasPasados;
          _isLoading = false; // 🔥 Ya puedes construir la pantalla
        });
      }
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
      content: _uid.isEmpty || _isLoading
          ? _buildLoading()
          : StreamBuilder<List<QuerySnapshot>>(
        stream: CombineLatestStream.list([
          FirebaseFirestore.instance
              .collection('permiso_72horas_solicitados')
              .where('idUser', isEqualTo: _uid)
              .snapshots(),
          FirebaseFirestore.instance
              .collection('prision_domiciliaria_solicitados')
              .where('idUser', isEqualTo: _uid)
              .snapshots(),
          FirebaseFirestore.instance
              .collection('libertad_condicional_solicitados')
              .where('idUser', isEqualTo: _uid)
              .snapshots(),
          FirebaseFirestore.instance
              .collection('extincion_pena_solicitados')
              .where('idUser', isEqualTo: _uid)
              .snapshots(),
        ]),
        builder: (context, solicitudesSnapshots) {
          if (!solicitudesSnapshots.hasData) return _buildLoading();

          // 🔁 Recalcular los estados
          final nuevasSolicitudes = solicitudesSnapshots.data!;
          final nuevoStatus = <String, String>{};

          if (nuevasSolicitudes[0].docs.isNotEmpty) {
            nuevoStatus['permiso_72h'] = nuevasSolicitudes[0].docs.first['status'] ?? '';
          }
          if (nuevasSolicitudes[1].docs.isNotEmpty) {
            nuevoStatus['prision_domiciliaria'] = nuevasSolicitudes[1].docs.first['status'] ?? '';
          }
          if (nuevasSolicitudes[2].docs.isNotEmpty) {
            nuevoStatus['libertad_condicional'] = nuevasSolicitudes[2].docs.first['status'] ?? '';
          }
          if (nuevasSolicitudes[3].docs.isNotEmpty) {
            nuevoStatus['extincion_pena'] = nuevasSolicitudes[3].docs.first['status'] ?? '';
          }

          _statusSolicitudes = nuevoStatus;
          _statusLoaded = true;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('Ppl').doc(_uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('No se encontraron datos del usuario'));
              }

              _ppl = Ppl.fromDocumentSnapshot(snapshot.data!);
              _isPaid = _ppl?.isPaid ?? false;

              return SingleChildScrollView(
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
                      if (_isTrial && !_isPaid) _buildTrialCard(),
                      _isPaid || _isTrial ? _buildPaidContent() : _buildUnpaidContent(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Cargando información...',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialCard() {
    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none, // 🔥 Permite que la imagen sobresalga de la tarjeta
        children: [
          Card(
            surfaceTintColor: blanco,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "¡ Felicidades !",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    "Disfruta de tu regalo de bienvenida.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Aún tienes $_diasRestantesPrueba días para explorar todas las funciones de nuestra aplicación.",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: gris,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -25,
            right: -250,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                "assets/images/regalo.png",
                height: 50,
              ),
            ),
          ),
        ],
      ),
    );
  }




  /// Contenido si el usuario **ha pagado**
  Widget _buildPaidContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          "${_ppl?.nombrePpl ?? ""} ${_ppl?.apellidoPpl ?? ""}",
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if(_ppl!.situacion == "En Reclusión")
        Text(
          "NUI: ${_ppl?.nui ?? "No disponible"}     TD: ${_ppl?.td ?? "No disponible"}",
          style: const TextStyle(fontSize: 14, color: Colors.black),
          textAlign: TextAlign.center,
        ),
        if(_ppl!.situacion != "En Reclusión")
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Divider(color: Colors.grey),
              const Text('Dirección registrada para cumplir la situación actual:', style: TextStyle(fontSize: 13, color: negro)),
              Text(
                "${_ppl!.direccion}, ${_ppl!.municipio} - ${_ppl!.departamento}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.1),
              ),
            ],
          ),
        const SizedBox(height: 10),
        situacionPpl(),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: blancoCards, // Fondo blanco para contraste
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
                "Beneficios obtenidos por tiempo cumplido",
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
            backgroundColor: primary,
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutPage(
                  tipoPago: 'suscripcion',
                  valor: _subscriptionValue ?? 0,
                  onTransaccionAprobada: () async {
                    // Lógica adicional después del pago exitoso
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("¡Pago realizado con éxito!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // Puedes refrescar estado o navegar si es necesario
                    setState(() {});
                  },
                ),
              ),
            );
          },
          child: const Text('Realizar pago', style: TextStyle(color: blanco)),
        ),
      ],
    );
  }

  Widget situacionPpl(){
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.black87
      ),
        child: Text(_ppl!.situacion, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)));
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
        if (_ppl!.situacion == "En Reclusión")
          Card(
            surfaceTintColor: Colors.grey,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBeneficioFila(
                "Permiso de 72h",
                33.33,
                "el permiso de 72 horas.",
                "permiso_72h",
                status: _statusSolicitudes["permiso_72h"],
              ),
            ),
          ),
        if (_ppl!.situacion == "En Reclusión")
          Card(
            surfaceTintColor: Colors.grey,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBeneficioFila(
                "Prisión Domiciliaria",
                50,
                "el beneficio para cumplir el resto de la condena en su domicilio bajo vigilancia.",
                "prision_domiciliaria",
                status: _statusSolicitudes["prision_domiciliaria"],
              ),
            ),
          ),
        if (_ppl!.situacion == "En Reclusión" || _ppl!.situacion == "En Prisión domiciliaria")
          Card(
            surfaceTintColor: Colors.grey,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBeneficioFila(
                "Libertad Condicional",
                60,
                "el beneficio para salir del lugar de reclusión bajo libertad condicional",
                "libertad_condicional",
                status: _statusSolicitudes["libertad_condicional"],
              ),
            ),
          ),
        Card(
          surfaceTintColor: Colors.grey,
          color: Colors.grey.shade100,
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildBeneficioFila(
              "Extinción de la Pena",
              100,
              "obtener su libertad definitiva.",
              "extincion_pena",
              status: _statusSolicitudes["extincion_pena"],
            ),
          ),
        ),
      ],
    );
  }


  // para idPaid true
  Widget _buildBeneficioFila(
      String titulo,
      double porcentajeRequerido,
      String accion,
      String idBeneficio, {
        String? status,
      }) {
    final List<String> beneficiosAdquiridos = _ppl?.beneficiosAdquiridos.map((e) => e.toLowerCase().trim()).toList() ?? [];
    final List<String> beneficiosNegados = _ppl?.beneficiosNegados.map((e) => e.toLowerCase().trim()).toList() ?? [];

    final bool adquirido = beneficiosAdquiridos.contains(idBeneficio.toLowerCase().trim()) || beneficiosAdquiridos.contains(titulo.toLowerCase().trim());
    final bool negado = beneficiosNegados.contains(idBeneficio.toLowerCase().trim()) || beneficiosNegados.contains(titulo.toLowerCase().trim());

    double porcentaje = _calculoCondenaController.porcentajeEjecutado ?? 0.0;
    int tiempo = _calculoCondenaController.tiempoCondena ?? 0;
    bool cumple = porcentaje >= porcentajeRequerido;
    int diasFaltantes = ((porcentajeRequerido - porcentaje) / 100 * tiempo * 30).ceil();

    final normalizedStatus = status?.toLowerCase().trim();
    final bool estaEnProceso = [
      'solicitado',
      'diligenciado',
      'revisado',
      'enviado',
      'negado',
      'concedido',
    ].contains(normalizedStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                adquirido
                    ? Icons.verified
                    : negado
                    ? Icons.cancel
                    : cumple
                    ? Icons.check_circle
                    : Icons.warning,
                color: adquirido
                    ? Colors.blue
                    : negado
                    ? Colors.red
                    : cumple
                    ? Colors.green
                    : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: adquirido
                        ? Colors.blue
                        : negado
                        ? Colors.red
                        : cumple
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
              if (!adquirido && !negado && !cumple)
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
                  adquirido
                      ? "Según los registros, ya le fue otorgado el beneficio de $titulo."
                      : negado
                      ? "Según los registros, el beneficio de $titulo fue negado previamente."
                      : !cumple
                      ? "No se ha cumplido el tiempo establecido para obtener este beneficio."
                      : "",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: adquirido || negado ? Colors.black : cumple ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          if (_statusLoaded && cumple && !adquirido && !negado && !estaEnProceso)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Ya se puede solicitar $accion",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_statusLoaded && !adquirido && !negado && cumple && !estaEnProceso)
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => _navegarAInfoPreviaSolicitud(idBeneficio),
                    child: const Text("Solicitar"),
                  ),
                ),
              ),
            ),

          // Mensaje de estado en proceso
          if (_statusLoaded && cumple && !adquirido && !negado && estaEnProceso)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: switch (normalizedStatus) {
                  "solicitado" => Colors.orange.shade50,
                  "diligenciado" => Colors.amber.shade50,
                  "revisado" => Colors.teal.shade50,
                  "enviado" => Colors.green.shade50,
                  "negado" => Colors.red.shade700,
                  "concedido" => Colors.green.shade700,
                  _ => Colors.grey.shade100,
                },
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    switch (normalizedStatus) {
                      "solicitado" => Icons.assignment_outlined,
                      "diligenciado" => Icons.search,
                      "revisado" => Icons.check_circle_outline,
                      "enviado" => Icons.send_outlined,
                      "negado" => Icons.cancel_outlined,
                      "concedido" => Icons.account_balance,
                      _ => Icons.help_outline,
                    },
                    size: 18,
                    color: switch (normalizedStatus) {
                      "solicitado" => Colors.orange,
                      "diligenciado" => Colors.amber.shade700,
                      "revisado" => Colors.teal,
                      "enviado" => Colors.green,
                      "negado" => Colors.white,
                      "concedido" => Colors.white,
                      _ => Colors.grey,
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      switch (normalizedStatus) {
                        "solicitado" => "Hemos recibido la solicitud de $titulo",
                        "diligenciado" => "Se está analizando la solicitud de $titulo",
                        "revisado" => "La solicitud de $titulo está lista para ser enviada",
                        "enviado" => "La solicitud de $titulo fue enviada a la autoridad competente",
                        "negado" => "La solicitud de $titulo fue negada por la autoridad competente",
                        "concedido" => "¡Muy buenas noticias! La solicitud de $titulo fue concedida por la autoridad competente",
                        _ => "Estado desconocido para la solicitud de $titulo",
                      },
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: normalizedStatus == "concedido"
                            ? Colors.white
                            : normalizedStatus == "negado"
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  )
                ],
              ),
            ),

          // Botón "Impugnar" si fue negado
          if (_statusLoaded && normalizedStatus == "negado")
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, 'info_previa_impugnacion_page', arguments: {
                        'beneficio': idBeneficio,
                        'titulo': titulo,
                      });
                    },
                    child: const Text("Impugnar"),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }



  Future<void> _cargarStatusSolicitudes() async {
    final user = FirebaseFirestore.instance.collection('Ppl').doc(_uid);

    final solicitudes = [
      {'coleccion': 'permiso_72horas_solicitados', 'id': 'permiso_72h'},
      {'coleccion': 'prision_domiciliaria_solicitados', 'id': 'prision_domiciliaria'},
      {'coleccion': 'libertad_condicional_solicitados', 'id': 'libertad_condicional'},
      {'coleccion': 'extincion_pena_solicitados', 'id': 'extincion_pena'},
    ];

    final Map<String, String> resultados = {};

    for (final solicitud in solicitudes) {
      final snap = await FirebaseFirestore.instance
          .collection(solicitud['coleccion']!)
          .where('idUser', isEqualTo: _uid)
          .orderBy('fecha', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final status = snap.docs.first.data()['status'] as String?;
        if (status != null) {
          resultados[solicitud['id']!] = status;
        }
      }
    }

    setState(() {
      _statusSolicitudes = resultados;
      _statusLoaded = true;
    });
  }


  void _navegarAInfoPreviaSolicitud(String idBeneficio) {
    switch (idBeneficio.toLowerCase().trim()) {
      case 'permiso_72h':
        Navigator.pushNamed(context, 'info_previa_72h_page');
        break;
      case 'prision_domiciliaria':
        Navigator.pushNamed(context, 'info_previa_solicitud_domiciliaria_page');
        break;
      case 'libertad_condicional':
        Navigator.pushNamed(context, 'info_previa_libertad_condicional_page');
        break;
      case 'extincion_pena':
        Navigator.pushNamed(context, 'solicitud_extincion_pena_page');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ruta de beneficio no reconocida"))
        );
    }
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
        _buildAnimatedDato("Condena\nTotal Cumplida", mesesCumplidos, diasRestantes, Colors.green.shade100),

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
                          color: Colors.white.withOpacity(borderOpacity), // 🔥 Se dibuja el borde con animación
                          width: 5,
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
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.1, color: negro),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "$mesesAnim meses , $diasAnim días" ,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
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
