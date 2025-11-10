import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuprocesoya/commons/wompi/checkout_page.dart';
import '../../providers/auth_provider.dart';
import '../Pages/client/mis_referidos/mis_referidos.dart';
import '../src/colors/colors.dart';
import 'admin_provider.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final MyAuthProvider _authProvider = MyAuthProvider();
  int _pendingSuggestions = 0;
  bool? _isAdmin;
  bool _isLoading = true;
  final ValueNotifier<bool> _isPaid = ValueNotifier<bool>(false);
  bool _isTrial = false;
  String? rol;
  int solicitudesRedencion = 0;
  int solicitudesReadecuacion = 0;
  int solicitudesDomiciliaria = 0;
  int solicitudesPermiso72h = 0;
  int solicitudesCondicional = 0;
  int solicitudesExtincion = 0;
  int solicitudesTraslado = 0;
  int solicitudesTutelas = 0;
  int solicitudesPeticion = 0;
  int solicitudesAcumulacion = 0;
  int solicitudesApelacion = 0;
  int solicitudesDesistimientoApelacion = 0;
  int solicitudesTrasladoPenitenciaria = 0;
  int solicitudesCopiaSentencia = 0;
  int solicitudesAsignacionJEP = 0;



  @override
  void initState() {
    super.initState();
    _fetchPendingSuggestions();
    _checkIfAdmin();
    _loadData();
    _fetchRedencionesSolicitados();
    _fetchDomiciliariasSolicitados();
    _fetchCondicionaleSolicitados();
    _fetchPermiso72Solicitados();
    _fetchTrasladoProcesoslicitados();
    _fetchPeticionlicitados();
    _fetchTutelalicitados();
    _fetchExtincionlicitados();
    _fetchAcumulacionlicitados();
    _fetchApelacionSolicitados();
    _fetchDesistimientoApelacionSolicitados();
    _fetchReadecuacionRedencionesSolicitados();
    _fetchTraladoPenitenciariaSolicitados();
    _fetchCopiaSentenciaSolicitados();
    _fetchAsignacionJEPSolicitados();
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(
        userId).get();
    if (userDoc.exists) {
      final Timestamp? fechaActivacion = userDoc.data()?['fechaActivacion'];
      _isPaid.value = userDoc.data()?['isPaid'] ?? false;
      await _validateTrialPeriod(fechaActivacion);
    }
  }

  Future<void> _validateTrialPeriod(Timestamp? fechaActivacion) async {
    if (fechaActivacion == null) return;

    try {
      final configSnapshot = await FirebaseFirestore.instance
          .collection('configuraciones')
          .limit(1)
          .get();

      final configData = configSnapshot.docs.firstOrNull?.data();

      final int tiempoDePrueba = configData?['tiempoDePrueba'] ?? 7;

      final DateTime fechaActivacionDT = fechaActivacion.toDate();
      final DateTime fechaActual = DateTime.now();
      final int diasTranscurridos =
          fechaActual.difference(fechaActivacionDT).inDays;

      setState(() {
        _isTrial = diasTranscurridos < tiempoDePrueba;
      });
    } catch (e) {
      setState(() {
        _isTrial = false; // Fallback: No trial si falla la config
      });
    }
  }


  Future<void> _checkIfAdmin() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 🔹 Leer de SharedPreferences si ya están guardados
      if (prefs.containsKey('isAdmin') && prefs.containsKey('rol')) {
        _isAdmin = prefs.getBool('isAdmin');
        rol = prefs.getString('rol') ?? "";
      } else {
        // 🔹 Consultar Firestore si no hay caché
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          _isAdmin = false;
          rol = "";
        } else {
          final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(userId).get();

          // 🔹 Intentar cargar el rol desde AdminProvider
          String? nuevoRol;
          try {
            await AdminProvider().loadAdminData();
            nuevoRol = AdminProvider().rol;
          } catch (_) {
            nuevoRol = "";
          }

          _isAdmin = adminDoc.exists;
          rol = nuevoRol ?? "";

          // 🔹 Guardar resultados en SharedPreferences
          await prefs.setBool('isAdmin', _isAdmin!);
          await prefs.setString('rol', rol!);
        }
      }
    } catch (e) {
      // 🔥 En caso de error, marcamos como no admin
      _isAdmin = false;
      rol = "";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<bool>(
      future: esReferidor(), // 👈 verificamos si es referidor
      builder: (context, snapshot) {
        final esReferidorActual = snapshot.data ?? false;

        final drawerItems = _buildDrawerItems(
          context,
          _isAdmin,
          rol,
          esReferidor: esReferidorActual,
        );

        return Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                offset: Offset(2, 0),
                blurRadius: 6,
              ),
            ],
          ),
          child: Drawer(
            elevation: 0,
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 40),
                  _buildDrawerHeader(_isAdmin),
                  const Divider(height: 1, color: grisMedio),
                  ...drawerItems,
                  const Divider(height: 1, color: Colors.white70),
                  _buildLogoutTile(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  Future<void> _fetchPendingSuggestions() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('buzon_sugerencias')
        .where('contestado', isEqualTo: false) // Filtra solo las no respondidas
        .get();

    if (mounted) {
      setState(() {
        _pendingSuggestions = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchRedencionesSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('redenciones_solicitados')
        .where('status', isEqualTo: 'Solicitado') // 👈 Asegúrate de usar comillas
        .get();

    if (mounted) {
      setState(() {
        solicitudesRedencion = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchReadecuacionRedencionesSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('readecuacion_solicitados')
        .where('status', isEqualTo: 'Solicitado') // 👈 Asegúrate de usar comillas
        .get();

    if (mounted) {
      setState(() {
        solicitudesReadecuacion = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchDomiciliariasSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('domiciliaria_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesDomiciliaria = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchCondicionaleSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('condicional_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesCondicional = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchPermiso72Solicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('permiso_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesPermiso72h = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchTrasladoProcesoslicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('trasladoProceso_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesTraslado = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchPeticionlicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('derechos_peticion_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesPeticion = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchTutelalicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('tutelas_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesTutelas = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchExtincionlicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('extincion_pena_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesExtincion = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchAcumulacionlicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('acumulacion_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesAcumulacion = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchApelacionSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('apelacion_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesApelacion = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchDesistimientoApelacionSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('desistimiento_apelacion_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesDesistimientoApelacion = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchTraladoPenitenciariaSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('trasladoPenitenciaria_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesTrasladoPenitenciaria = querySnapshot.docs.length;
      });
    }
  }

  Future<void> _fetchCopiaSentenciaSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('copiaSentencia_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesCopiaSentencia = querySnapshot.docs.length;
      });
    }
  }
  Future<void> _fetchAsignacionJEPSolicitados() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('asignacionJEP_solicitados')
        .where('status', isEqualTo: 'Solicitado')
        .get();
    if (mounted) {
      setState(() {
        solicitudesAsignacionJEP = querySnapshot.docs.length;
      });
    }
  }

  Widget _buildDrawerHeader(bool? isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(color: blanco),
      child: Column(
        children: [
          Image.asset(
              'assets/images/logo_tu_proceso_ya_transparente.png', height: 40),
          if (isAdmin == true) const Text("Administrador"),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(
      BuildContext context,
      bool? isAdmin,
      String? rol, {
        bool esReferidor = false, // 👈 Esto permite que sea opcional
      }) {
    List<Widget> items = [
      const SizedBox(height: 50),
    ];
    if (isAdmin == true) {
      // Para administradores, se muestran diferentes opciones según su rol.
      if (rol == "masterFull") {
        // Para master y masterFull se muestran todos los ítems de admin.
        items.addAll([
          _buildDrawerTile(
              context, "Página principal", Icons.home_filled, 'home_admin'),

          _buildDrawerTile(
              context, "Solicitudes general", Icons.table_chart, 'historial_solicitudes_general_admin'),

          ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.add_chart, color: Colors.deepPurple),
            title: const Text(
              "Solicitudes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            iconColor: Colors.black,
            collapsedIconColor: Colors.black,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Readecuación de redención",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_readecuacion_redenciones_admin',
                  showBadge: solicitudesReadecuacion > 0,
                  contador: solicitudesReadecuacion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Derecho de petición",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_derecho_peticion_admin',
                  showBadge: solicitudesPeticion > 0,
                  contador: solicitudesPeticion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Tutela",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_tutelas_admin',
                  showBadge: solicitudesTutelas > 0,
                  contador: solicitudesTutelas,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Permiso 72 horas",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_permiso_72horas_admin',
                  showBadge: solicitudesPermiso72h > 0,
                  contador: solicitudesPermiso72h,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Prisión domiciliaria",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_prision_domiciliaria_admin',
                  showBadge: solicitudesDomiciliaria > 0,
                  contador: solicitudesDomiciliaria,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Libertad condicional",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_libertad_condicional_admin',
                  showBadge: solicitudesCondicional > 0,
                  contador: solicitudesCondicional,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Extinción de pena",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_extincion_pena_admin',
                  showBadge: solicitudesExtincion > 0,
                  contador: solicitudesExtincion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Traslado de proceso",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_traslado_proceso_admin',
                  showBadge: solicitudesTraslado > 0,
                  contador: solicitudesTraslado,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Redenciones",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_redenciones_admin',
                  showBadge: solicitudesRedencion > 0,
                  contador: solicitudesRedencion,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Acumulación de penas",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_acumulacion_admin',
                  showBadge: solicitudesAcumulacion > 0,
                  contador: solicitudesAcumulacion,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Apelación",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_apelacion_admin',
                  showBadge: solicitudesApelacion > 0,
                  contador: solicitudesApelacion,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Desistimiento de Apelación",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_desistimientoApelacion_admin',
                  showBadge: solicitudesDesistimientoApelacion > 0,
                  contador: solicitudesDesistimientoApelacion,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Traslado de penitenciaria",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_trasladoPenitenciaria_admin',
                  showBadge: solicitudesTrasladoPenitenciaria > 0,
                  contador: solicitudesTrasladoPenitenciaria,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Copia de sentencia",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_copiaSentencia_admin',
                  showBadge: solicitudesCopiaSentencia > 0,
                  contador: solicitudesCopiaSentencia,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Asignación Juzgado EP",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_asignacionJEP_admin',
                  showBadge: solicitudesAsignacionJEP > 0,
                  contador: solicitudesAsignacionJEP,
                ),
              ),

            ],
          ),

          ExpansionTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
            title: const Text(
              "Administración",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              _buildDrawerTile(
                context,
                "Transacciones mes actual",
                Icons.monetization_on,
                'admin_transacciones',
              ),
              _buildDrawerTile(
                context,
                "Historial Transacciones",
                Icons.monitor_heart_rounded,
                'admin_transacciones_historico',
              ),
              _buildDrawerTile(
                context,
                "Referidores",
                Icons.double_arrow_outlined,
                'referidores_page_admin',
              ),
              _buildDrawerTile(
                context,
                "Registrar Referidor",
                Icons.edit_calendar,
                'registrar_referidores_page_admin',
              ),
              _buildDrawerTile(
                context,
                "Pago de comisiones",
                Icons.money_rounded,
                'historial_pago_comisiones_page_admin',
              ),
              _buildDrawerTile(
                context,
                "Buzón de sugerencias",
                Icons.mark_email_unread_outlined,
                'buzon_sugerencias_administrador',
                showBadge: _pendingSuggestions > 0,
              ),
              _buildDrawerTile(
                context,
                "Registro asistido usuarios",
                Icons.add,
                'registraro_asistido_page_admin',
              ),
              _buildDrawerTile(
                context,
                "Registrar Operadores",
                Icons.app_registration,
                'registrar_operadores',
              ),
              _buildDrawerTile(
                context,
                "Operadores",
                Icons.account_box,
                'operadores_page',
              ),
              _buildDrawerTile(
                context,
                "Respuestas a correos",
                Icons.mark_email_read_outlined,
                'ver_respuestas_correos_page_admin',
              ),
              _buildDrawerTile(
                  context,
                  "Configuraciones",
                  Icons.settings,
                  'configuraciones'),
            ],
          ),
        ]);


      } else if (rol == "master") {
        items.addAll([
          _buildDrawerTile(
              context, "Página principal", Icons.home_filled, 'home_admin'),
          _buildDrawerTile(
              context, "Solicitudes general", Icons.table_chart, 'historial_solicitudes_general_admin'),


          ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.add_chart, color: Colors.deepPurple),
            title: const Text(
              "Solicitudes",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            iconColor: Colors.black,
            collapsedIconColor: Colors.black,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Readecuación de redención",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_readecuacion_redenciones_admin',
                  showBadge: solicitudesReadecuacion > 0,
                  contador: solicitudesReadecuacion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Derecho de petición",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_derecho_peticion_admin',
                  showBadge: solicitudesPeticion > 0,
                  contador: solicitudesPeticion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Tutela",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_tutelas_admin',
                  showBadge: solicitudesTutelas > 0,
                  contador: solicitudesTutelas,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Permiso 72 horas",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_permiso_72horas_admin',
                  showBadge: solicitudesPermiso72h > 0,
                  contador: solicitudesPermiso72h,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Prisión domiciliaria",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_prision_domiciliaria_admin',
                  showBadge: solicitudesDomiciliaria > 0,
                  contador: solicitudesDomiciliaria,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Libertad condicional",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_libertad_condicional_admin',
                  showBadge: solicitudesCondicional > 0,
                  contador: solicitudesCondicional,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Extinción de pena",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_extincion_pena_admin',
                  showBadge: solicitudesExtincion > 0,
                  contador: solicitudesExtincion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Traslado de proceso",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_traslado_proceso_admin',
                  showBadge: solicitudesTraslado > 0,
                  contador: solicitudesTraslado,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Redenciones",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_redenciones_admin',
                  showBadge: solicitudesRedencion > 0,
                  contador: solicitudesRedencion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Acumulación de pena",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_acumulacion_admin',
                  showBadge: solicitudesAcumulacion > 0,
                  contador: solicitudesAcumulacion,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Apelación",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_apelacion_admin',
                  showBadge: solicitudesApelacion > 0,
                  contador: solicitudesApelacion,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Desistimiento de Apelación",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_desistimientoApelacion_admin',
                  showBadge: solicitudesDesistimientoApelacion > 0,
                  contador: solicitudesDesistimientoApelacion,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Traslado de penitenciaria",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_trasladoPenitenciaria_admin',
                  showBadge: solicitudesTrasladoPenitenciaria > 0,
                  contador: solicitudesTrasladoPenitenciaria,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Copia de sentencia",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_copiaSentencia_admin',
                  showBadge: solicitudesCopiaSentencia > 0,
                  contador: solicitudesCopiaSentencia,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Asignación Juzgado EP",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_asignacionJEP_admin',
                  showBadge: solicitudesAsignacionJEP > 0,
                  contador: solicitudesAsignacionJEP,
                ),
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
            title: const Text(
              "Administración",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              // _buildDrawerTile(
              //   context,
              //   "Transacciones",
              //   Icons.monitor_heart_rounded,
              //   'admin_transacciones',
              // ),
              _buildDrawerTile(
                context,
                "Referidores",
                Icons.double_arrow_outlined,
                'referidores_page_admin',
              ),
              // _buildDrawerTile(
              //   context,
              //   "Pago de comisiones",
              //   Icons.money_rounded,
              //   'historial_pago_comisiones_page_admin',
              // ),
              _buildDrawerTile(
                context,
                "Buzón de sugerencias",
                Icons.mark_email_unread_outlined,
                'buzon_sugerencias_administrador',
                showBadge: _pendingSuggestions > 0,
              ),
              _buildDrawerTile(
                context,
                "Registro asistido usuarios",
                Icons.add,
                'registraro_asistido_page_admin',
              ),
            ],
          ),
        ]);
      }

      else if (rol == "coordinador 1" || rol == "coordinador 2") {
        // Para coordinadores se muestran un subconjunto de opciones.
        items.addAll([
          _buildDrawerTile(
              context, "Página principal", Icons.home_filled, 'home_admin'),
          _buildDrawerTile(
              context, "Buzón de sugerencias", Icons.mark_email_unread_outlined,
              'buzon_sugerencias_administrador',
              showBadge: _pendingSuggestions > 0),
          ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.add_chart, color: Colors.black, size: 20),
            title: const Text(
              "Historial de solicitudes",
              style: TextStyle(color: Colors.black, fontSize: 13),
            ),
            iconColor: Colors.black,
            collapsedIconColor: Colors.black,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes de derechos petición",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_derecho_peticion_admin',
                  showBadge: solicitudesPeticion > 0,
                  contador: solicitudesPeticion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes de tutela",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_tutelas_admin',
                  showBadge: solicitudesTutelas > 0,
                  contador: solicitudesTutelas,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes permiso 72 horas",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_permiso_72horas_admin',
                  showBadge: solicitudesPermiso72h > 0,
                  contador: solicitudesPermiso72h,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes de prisión domiciliaria",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_prision_domiciliaria_admin',
                  showBadge: solicitudesDomiciliaria > 0,
                  contador: solicitudesDomiciliaria,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes de Libertad condicional",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_libertad_condicional_admin',
                  showBadge: solicitudesCondicional > 0,
                  contador: solicitudesCondicional,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes de Extinción de pena",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_extincion_pena_admin',
                  showBadge: solicitudesExtincion > 0,
                  contador: solicitudesExtincion,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes de Traslado de proceso",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_traslado_proceso_admin',
                  showBadge: solicitudesTraslado > 0,
                  contador: solicitudesTraslado,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildDrawerTile(
                  context,
                  "Solicitudes de Redenciones",
                  Icons.double_arrow_outlined,
                  'historial_solicitudes_redenciones_admin',
                  showBadge: solicitudesRedencion > 0,
                  contador: solicitudesRedencion,
                ),
              ),
            ],
          ),
        ]);
      } else if (rol == "operador 1" || rol == "operador 2") {
        // Para operadores se muestran opciones básicas.
        items.addAll([
          _buildDrawerTile(
              context, "Página principal", Icons.home_filled, 'home_admin'),
        ]);
      } else if (rol == "pasante 1" || rol == "pasante 2") {
        // Para pasantes, se muestra solo la página principal.
        items.add(
          _buildDrawerTile(context, "Historial Solicitudes derechos petición",
              Icons.add_alert_outlined, 'historial_solicitudes_derecho_peticion_admin'),
        );
      }
      else if (rol == "pasante 3" || rol == "pasante 4") {
        // Para pasantes, se muestra solo la página principal.
        items.add(
          _buildDrawerTile(context, "Historial Solicitudes de tutela",
              Icons.abc_rounded, 'historial_solicitudes_tutelas_admin'),
        );
      }
    } else {
      // Menú para usuarios que no son admin.
      items.addAll([
        _buildDrawerTile(
            context, "Página principal", Icons.home_filled, 'home'),
        const Divider(height: 1, color: primary),
        _buildDrawerTile(context, "Solicitar Servicios", Icons.ads_click, 'solicitar_page'),
        _buildDrawerTile(context, "Historial de solicitudes", Icons.add_chart, 'historiales_page'),
        const Divider(height: 5, color: primary),
        _buildDrawerTile(context, "Tus datos", Icons.person_pin, 'mis_datos'),
        _buildDrawerTile(context, "Tus pagos", Icons.attach_money, 'mis_transacciones'),
        _buildDrawerTile(context, "Tus redenciones", Icons.double_arrow_rounded, 'mis_redenciones'),
        const Divider(height: 5, color: primary),

        // 🔥 Submenú "Información general"
        ExpansionTile(
          initiallyExpanded:false,
          leading: const Icon(
              Icons.info_outline, color: Colors.black, size: 20),
          title: const Text("Información general",
              style: TextStyle(color: Colors.black, fontSize: 13)),
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              // 🔥 Espaciado para cada elemento
              child: _buildDrawerTile(context, "Términos y condiciones",
                  Icons.account_balance_outlined, 'terminos_y_condiciones'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildDrawerTile(context, "Derechos del condenado",
                  Icons.monitor_heart_rounded, 'derechos_info'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildDrawerTile(
                  context, "Quiénes somos", Icons.info, 'nosotros'),
            ),
          ],
        ),
        _buildDrawerTile(
            context, "Buzón de sugerencias", Icons.mark_email_unread_outlined,
            'buzon_sugerencias'),
        _buildDrawerTile(context, "Preguntas frecuentes", Icons.question_mark, 'preguntas_frecuentes_page'),

        const Divider(height: 5, color: primary),
        if (esReferidor)
          ListTile(
            leading: const Icon(Icons.group, color: Colors.black54, size: 20),
            title: const Text(
              "Mis referidos",
              style: TextStyle(color: Colors.black, fontSize: 13),
            ),
            onTap: () async {
              final referidorId = await obtenerIdReferidorDesdeIdUser();
              if (referidorId != null) {
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MisReferidosPage(referidorId: referidorId),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No se encontraron referidos.")),
                  );
                }
              }
            },
          ),
      ]);
    }

    items.add(const SizedBox(height: 60)); // Espacio extra al final
    return items;
  }

  Widget _buildDrawerTile(
      BuildContext context,
      String title,
      IconData icon,
      String route, {
        bool showBadge = false,
        int? contador, // 👈 Nuevo parámetro opcional
      }) {
    return ListTile(
      onTap: () {
        if (_isAdmin == true) {
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushNamed(context, route);
          }
          return;
        }

        if (!_isPaid.value && !_isTrial) {
          _showPaymentDialog(context);
          return;
        }

        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          if (contador != null && contador > 0)
            Positioned(
              right: -10,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  '$contador',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (showBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),

      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );

  }

  Future<bool> esReferidor() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("UID es null");
      return false;
    }

    final query = await FirebaseFirestore.instance
        .collection('referidores')
        .where('idUser', isEqualTo: userId)
        .limit(1)
        .get();

    print("Referidor encontrado: ${query.docs.isNotEmpty}");
    return query.docs.isNotEmpty;
  }


  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return FutureBuilder(
          future: _obtenerDatosSuscripcion(),
          builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final datos = snapshot.data!;
            final int valorOriginal = datos['valorOriginal'];
            final int valorConDescuento = datos['valorConDescuento'];
            final bool tieneDescuento = datos['tieneDescuento'];
            final int valorDescuento = valorOriginal - valorConDescuento;
            final int? porcentajeDescuentoPersonalizado = datos['porcentajeDescuentoPersonalizado'];
            final bool esPorReferido = datos['esPorReferido'];

            final formatter = NumberFormat("#,###", "es_CO");

            return AlertDialog(
              backgroundColor: blanco,
              title: const Text("Acceso restringido"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Para acceder a esta sección, debes pagar la suscripción.",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    "Valor original: \$${formatter.format(valorOriginal)}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  if (tieneDescuento) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: blanco,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: esPorReferido ? Colors.green.shade300 : Colors.orange.shade300,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/regalo.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                porcentajeDescuentoPersonalizado != null
                                    ? "¡Tienes un $porcentajeDescuentoPersonalizado% de descuento en tu suscripción!\n\n"
                                    "Ahorrarás \$${formatter.format(valorDescuento)} en este pago."
                                    : "¡Tienes un 20% de descuento por referido!\n\n"
                                    "Ahorrarás \$${formatter.format(valorDescuento)} en este pago.",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Valor a pagar con descuento: \$${formatter.format(valorConDescuento)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],

                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null || !context.mounted) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CheckoutPage(
                          tipoPago: 'suscripcion',
                          valor: valorConDescuento,
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

                            _isPaid.value = true;
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text("Realizar pago", style: TextStyle(color: blanco)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _obtenerDatosSuscripcion() async {
    final configSnapshot = await FirebaseFirestore.instance
        .collection('configuraciones')
        .limit(1)
        .get();

    final int valorOriginal =
    (configSnapshot.docs.first.data()['valor_subscripcion'] ?? 0).toInt();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'valorOriginal': valorOriginal,
        'valorConDescuento': valorOriginal,
        'tieneDescuento': false,
        'porcentajeDescuentoPersonalizado': null,
      };
    }

    final doc = await FirebaseFirestore.instance.collection("Ppl").doc(user.uid).get();
    bool tieneDescuentoReferido = false;
    int? porcentajeDescuentoPersonalizado;

    if (doc.exists) {
      final data = doc.data()!;
      tieneDescuentoReferido = data["referidoPor"] == "355";
      porcentajeDescuentoPersonalizado = (data["descuento"] as Map?)?["porcentaje"];
    }

    final bool tieneDescuento = tieneDescuentoReferido || porcentajeDescuentoPersonalizado != null;

    int valorConDescuento = valorOriginal;
    if (porcentajeDescuentoPersonalizado != null) {
      valorConDescuento = (valorOriginal * (1 - (porcentajeDescuentoPersonalizado / 100))).round();
    } else if (tieneDescuentoReferido) {
      valorConDescuento = (valorOriginal * 0.8).round();
    }

    return {
      'valorOriginal': valorOriginal,
      'valorConDescuento': valorConDescuento,
      'tieneDescuento': tieneDescuento,
      'porcentajeDescuentoPersonalizado': porcentajeDescuentoPersonalizado,
      'esPorReferido': tieneDescuentoReferido,
    };
  }

  Future<String?> obtenerIdReferidorDesdeIdUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final query = await FirebaseFirestore.instance
        .collection('referidores')
        .where('idUser', isEqualTo: uid)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null; // No es referidor
    }

    return query.docs.first.id; // El ID del documento referidor
  }


  Widget _buildLogoutTile(BuildContext context) {
    return DrawerListTitle(
      title: "Cerrar sesión",
      icon: Icons.exit_to_app,
      press: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isAdmin'); // 🔥 Borra datos guardados
        await prefs.remove('rol');

        try {
          await _authProvider.signOut();
          AdminProvider().reset();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, 'login', (Route<dynamic> route) => false);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error al cerrar sesión")),
            );
          }
        }
      },
    );
  }
}

  class DrawerListTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback press;
  final Color? iconColor;

  const DrawerListTitle({
    Key? key,
    required this.title,
    required this.icon,
    required this.press,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      leading: Icon(
        icon,
        color: iconColor ?? primary,
      ),
      title: Text(
        title,
        style: const TextStyle(color: negro, fontSize: 13),
      ),
    );
  }
}

class CardDescuento extends StatelessWidget {
  final int valorDescuento;

  const CardDescuento({super.key, required this.valorDescuento});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,###", "es_CO");

    return Card(
      color: Colors.green.shade50,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset(
              'assets/images/regalo.png',
              width: 50,
              height: 50,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Tienes un 20% de descuento en tu suscripción.\n\nAhorrarás \$${formatter.format(valorDescuento)} en este pago.",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
