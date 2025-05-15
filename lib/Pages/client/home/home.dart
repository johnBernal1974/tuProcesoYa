
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _checkSubscriptionStatus();
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
              .collection('permiso_solicitados')
              .where('idUser', isEqualTo: _uid)
              .snapshots(),
          FirebaseFirestore.instance
              .collection('domiciliaria_solicitados')
              .where('idUser', isEqualTo: _uid)
              .snapshots(),
          FirebaseFirestore.instance
              .collection('condicional_solicitados')
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
                return const Center(child: Text(''));
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
                      if (_isTrial && !_isPaid) _buildTrialCard(context),
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

  Widget _buildTrialCard(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: blanco,
            title: const Text("Periodo de prueba"),
            content: const Text(
              "Actualmente estás disfrutando del periodo de prueba gratuito. "
                  "Si deseas acceder de inmediato a todos los beneficios, puedes realizar el pago de la suscripción desde ahora.",
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.justify,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: () async {
                  Navigator.pop(context); // Cierra el diálogo

                  final user = FirebaseAuth.instance.currentUser;

                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Tu sesión ha expirado. Inicia sesión nuevamente."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final snapshot = await FirebaseFirestore.instance
                        .collection("configuraciones")
                        .limit(1)
                        .get();

                    if (snapshot.docs.isEmpty || snapshot.docs.first.data()["valor_subscripcion"] == null) {
                      throw Exception("No se encontró el valor de la suscripción.");
                    }

                    final int valorSuscripcion = snapshot.docs.first["valor_subscripcion"];

                    if(context.mounted){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPage(
                            tipoPago: 'suscripcion',
                            valor: valorSuscripcion,
                            onTransaccionAprobada: () async {
                              await FirebaseFirestore.instance
                                  .collection("Ppl")
                                  .doc(user.uid)
                                  .update({
                                "isPaid": true,
                                "fechaSuscripcion": FieldValue.serverTimestamp(),
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("¡Suscripción activada con éxito!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No se pudo obtener el valor de la suscripción."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text("Pagar suscripción", style: TextStyle(color: blanco)),
              ),
            ],
          ),
        );
      },
      child: SizedBox(
        child: Stack(
          clipBehavior: Clip.none,
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
      ),
    );
  }

  Future<void> _checkSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection("Ppl").doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return;

    bool isPaid = userData["isPaid"] ?? false;
    final Timestamp? fechaSuscripcion = userData["fechaSuscripcion"];

    // 🔄 Obtener duración desde "configuraciones"
    final configSnapshot = await FirebaseFirestore.instance
        .collection("configuraciones")
        .limit(1)
        .get();

    if (configSnapshot.docs.isEmpty) return;

    final configData = configSnapshot.docs.first.data();
    final int duracionDias = configData["tiempo_suscripcion"] ?? 180;

    if (isPaid && fechaSuscripcion != null) {
      final ahora = DateTime.now();
      final fechaPago = fechaSuscripcion.toDate();
      final vencimiento = fechaPago.add(Duration(days: duracionDias));
      final diasTranscurridos = ahora.difference(fechaPago).inDays;
      final diasRestantes = duracionDias - diasTranscurridos;

      print("🟢 Fecha de suscripción: $fechaPago");
      print("📅 Días transcurridos: $diasTranscurridos");
      print("⏳ Días restantes: $diasRestantes");
      print("🔚 Fecha de vencimiento: $vencimiento");

      if (ahora.isAfter(vencimiento)) {
        print("❌ La suscripción ha vencido. Desactivando isPaid.");
        await FirebaseFirestore.instance
            .collection("Ppl")
            .doc(user.uid)
            .update({"isPaid": false});
        isPaid = false;
      } else {
        print("✅ La suscripción sigue activa.");
      }
    }

    setState(() {
      _isPaid = isPaid;
    });
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
                    final user = FirebaseAuth.instance.currentUser;

                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection("Ppl")
                          .doc(user.uid)
                          .update({
                        "isPaid": true,
                        "fechaSuscripcion": FieldValue.serverTimestamp(),
                      });
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("¡Suscripción activada con éxito!"),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Refrescar estado si deseas que desaparezca el contenido de "no suscrito"
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
      'solicitado', 'diligenciado', 'revisado', 'enviado', 'negado', 'concedido',
    ].contains(normalizedStatus);

    final bool esExtincion = idBeneficio.toLowerCase().contains("extincion");
    final bool esExento = _ppl?.exento ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esExento && !esExtincion
                    ? Icons.block
                    : adquirido
                    ? Icons.verified
                    : negado
                    ? Icons.cancel
                    : cumple
                    ? Icons.check_circle
                    : Icons.warning,
                color: esExento && !esExtincion
                    ? Colors.deepOrange
                    : adquirido
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
                    color: esExento && !esExtincion
                        ? Colors.deepOrange
                        : adquirido
                        ? Colors.blue
                        : negado
                        ? Colors.red
                        : cumple
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          if (negado) ...[
            const SizedBox(height: 4),
            Text(
              "Según los registros, el beneficio de $titulo fue negado previamente.",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ],

          if (adquirido) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Según los registros, ya le fue otorgado el beneficio de $titulo.",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (esExento && !esExtincion && !cumple) ...[
            const Text(
              "No se ha cumplido el tiempo establecido para acceder a este beneficio.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Restan: $diasFaltantes días",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],

          if (!cumple && !adquirido && !negado && (!esExento || esExtincion)) ...[
            const SizedBox(height: 4),
            const Text(
              "No se ha cumplido el tiempo establecido para acceder a este beneficio.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Restan: $diasFaltantes días",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ],

          // 🔹 Si cumple el tiempo, no ha sido adquirido/negado y no está en proceso
          if (_statusLoaded &&
              cumple &&
              !adquirido &&
              !negado &&
              !estaEnProceso &&
              (!esExento || esExtincion)) ...[
            const SizedBox(height: 6),
            Text(
              "Buena noticia! Ya se puede solicitar $accion",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 28,
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
          ],


          if (esExento && !esExtincion && cumple) ...[
            const Text(
              "Se ha cumplido el tiempo mínimo requerido por la ley para acceder a este beneficio.",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 4),
            const Text(
              "Restan: 0 días",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(
                    text: "Según el artículo 68A del Código Penal, ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: "esta persona está exenta de acceder a este beneficio por disposición legal.\n\n",
                  ),
                  TextSpan(
                    text: "Sin embargo, existen excepciones legales en las que podría evaluarse la concesión del beneficio, tales como:\n\n",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: "• Mujer embarazada\n"),
                  TextSpan(text: "• Madre lactante\n"),
                  TextSpan(text: "• Persona con enfermedad grave o terminal\n"),
                  TextSpan(text: "• Persona mayor de 60 años\n"),
                  TextSpan(text: "• Único responsable del cuidado de hijos menores, adultos mayores o personas con discapacidad\n"),
                  TextSpan(text: "• Persona con discapacidad física, sensorial, cognitiva o mental\n"),
                  TextSpan(text: "• Casos excepcionales donde se afecten gravemente derechos fundamentales\n\n"),
                  TextSpan(text: "Si el PPL cuenta con alguna de estas condiciones, puede hacer clic en el botón 'Solicitar' para que su caso sea evaluado.\n\n"),
                  TextSpan(text: "Por favor abstenerse de enviar la solicitud si no cuenta con una de las anteriores condiciones.\n\n"),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  final ruta = switch (idBeneficio.toLowerCase().trim()) {
                    'prision_domiciliaria' => 'solicitud_domiciliaria_page',
                    'libertad_condicional' => 'solicitud_condicional_page',
                    'permiso_72h' => 'solicitud_72h_page',
                    'extincion_pena' => 'solicitud_extincion_pena_page',
                    _ => 'solicitud_generica_page',
                  };
                  Navigator.pushNamed(
                    context,
                    ruta,
                    arguments: {
                      'tipoSolicitud': idBeneficio,
                      'excepcionActivada': true,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                child: const Text("Solicitar"),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Future<void> _cargarStatusSolicitudes() async {
    final user = FirebaseFirestore.instance.collection('Ppl').doc(_uid);

    final solicitudes = [
      {'coleccion': 'permiso_solicitados', 'id': 'permiso_72h'},
      {'coleccion': 'domiciliaria_solicitados', 'id': 'prision_domiciliaria'},
      {'coleccion': 'condicional_solicitados', 'id': 'libertad_condicional'},
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
