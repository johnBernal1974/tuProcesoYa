import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuprocesoya/commons/wompi/checkout_page.dart';
import '../../providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchPendingSuggestions();
    _checkIfAdmin();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(
        userId).get();
    if (userDoc.exists) {
      final Timestamp? fechaRegistro = userDoc.data()?['fechaRegistro'];
      _isPaid.value = userDoc.data()?['isPaid'] ?? false;
      await _validateTrialPeriod(fechaRegistro);
    }
  }

  Future<void> _validateTrialPeriod(Timestamp? fechaRegistro) async {
    if (fechaRegistro == null) return;

    try {
      final configSnapshot = await FirebaseFirestore.instance
          .collection('configuraciones')
          .limit(1)
          .get();

      final configData = configSnapshot.docs.firstOrNull?.data();

      final int tiempoDePrueba = configData?['tiempoDePrueba'] ?? 7;

      final DateTime fechaRegistroDT = fechaRegistro.toDate();
      final DateTime fechaActual = DateTime.now();
      final int diasTranscurridos =
          fechaActual.difference(fechaRegistroDT).inDays;

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

    List<Widget> drawerItems = _buildDrawerItems(context, _isAdmin, rol);

    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black38, // Sombra suave
            offset: Offset(2, 0),   // A la derecha
            blurRadius: 6,          // Difuminado
          ),
        ],
      ),
      child: Drawer(
        elevation: 0, // Elevation en 0 ya que usamos BoxShadow
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

  List<Widget> _buildDrawerItems(BuildContext context, bool? isAdmin,
      String? rol) {
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
          _buildDrawerTile(context, "Configuraciones", Icons.settings,
              'configuraciones'),
          ExpansionTile(
            initiallyExpanded:true,
            leading: const Icon(Icons.add_chart, color: Colors.black, size: 20),
            title: const Text("Historial de solicitudes",
                style: TextStyle(color: Colors.black, fontSize: 13)),
            iconColor: Colors.black,
            // 🔥 Color del icono cuando se expande
            collapsedIconColor: Colors.black,
            // 🔥 Color cuando está colapsado
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de derechos petición",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_derecho_peticion_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de tutela",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_tutelas_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes permiso 72 horas",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_permiso_72horas_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de prisión domiciliaria",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_prision_domiciliaria_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de Libertad condicional",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_libertad_condicional_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de Extinción de pena",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_extincion_pena_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de Traslado de proceso",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_traslado_proceso_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de Redenciones",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_redenciones_admin'),
              ),
            ],
          ),
          _buildDrawerTile(context, " Historial Transacciones", Icons.monitor_heart_rounded,
              'admin_transacciones'),
          _buildDrawerTile(context, " Referidores", Icons.double_arrow_outlined,
              'referidores_page_admin'),
          _buildDrawerTile(context, " Registrar Referidor", Icons.double_arrow_outlined,
              'registrar_referidores_page_admin'),
          _buildDrawerTile(
              context, "Buzón de sugerencias", Icons.mark_email_unread_outlined,
              'buzon_sugerencias_administrador',
              showBadge: _pendingSuggestions > 0),
          _buildDrawerTile(
              context, "Registro asistido usuarios", Icons.add,
              'registraro_asistido_page_admin'),

          _buildDrawerTile(
              context, "Registrar Operadores", Icons.app_registration,
              'registrar_operadores'),
          _buildDrawerTile(
              context, "Operadores", Icons.account_box, 'operadores_page'),
        ]);


      } else if (rol == "master") {
        items.addAll([
          _buildDrawerTile(
              context, "Página principal", Icons.home_filled, 'home_admin'),

          ExpansionTile(
            initiallyExpanded:true,
            leading: const Icon(Icons.add_chart, color: Colors.black, size: 20),
            title: const Text("Historial de solicitudes",
                style: TextStyle(color: Colors.black, fontSize: 13)),
            iconColor: Colors.black,
            // 🔥 Color del icono cuando se expande
            collapsedIconColor: Colors.black,
            // 🔥 Color cuando está colapsado
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de derechos petición",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_derecho_peticion_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de tutela",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_tutelas_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes permiso 72 horas",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_permiso_72horas_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de prisión domiciliaria",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_prision_domiciliaria_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de Libertad condicional",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_libertad_condicional_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de Extinción de pena",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_extincion_pena_admin'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                // 🔥 Espaciado para cada elemento
                child: _buildDrawerTile(
                    context, "Solicitudes de Traslado de proceso",
                    Icons.double_arrow_outlined,
                    'historial_solicitudes_traslado_proceso_admin'),
              ),
            ],
          ),
          _buildDrawerTile(context, " Historial Transacciones", Icons.monitor_heart_rounded,
              'admin_transacciones'),
          _buildDrawerTile(
              context, "Buzón de sugerencias", Icons.mark_email_unread_outlined,
              'buzon_sugerencias_administrador',
              showBadge: _pendingSuggestions > 0),
          _buildDrawerTile(context, " Referidores", Icons.double_arrow_outlined,
              'referidores_page_admin'),
          _buildDrawerTile(
              context, "Registro asistido usuarios", Icons.add,
              'registraro_asistido_page_admin'),
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
          _buildDrawerTile(context, "Historial Solicitudes derechos petición",
              Icons.add_alert_outlined, 'historial_solicitudes_derecho_peticion_admin'),
          _buildDrawerTile(context, "Historial Solicitudes de tutela",
              Icons.abc_rounded, 'historial_solicitudes_tutelas_admin'),
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
        _buildDrawerTile(context, "Tus datos", Icons.person_pin, 'mis_datos'),
        _buildDrawerTile(context, "Solicitar derecho de petición", Icons.account_balance_outlined, 'derecho_peticion'),
        _buildDrawerTile(context, "Solicitar acción de tutela", Icons.gavel, 'tutela'),
        _buildDrawerTile(context, "Solicitar traslado de proceso", Icons.swap_horiz, 'solicitud_traslado_proceso_page'),
        _buildDrawerTile(context, "Solicitar Redenciones", Icons.work_outline , 'solicitud_redenciones_page'),
        _buildDrawerTile(context, "Tus pagos", Icons.attach_money, 'mis_transacciones'),
        _buildDrawerTile(context, "Historial de solicitudes", Icons.add_chart, 'historiales_page'),
        _buildDrawerTile(context, "Tus redenciones", Icons.double_arrow_rounded, 'mis_redenciones'),
        // 🔥 Submenú "Información general"
        ExpansionTile(
          initiallyExpanded:true,
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
        _buildDrawerTile(context, "Preguntas frecuentes", Icons.double_arrow_rounded, 'preguntas_frecuentes_page'),
      ]);
    }


    items.add(const SizedBox(height: 60)); // Espacio extra al final
    return items;
  }


  Widget _buildDrawerTile(BuildContext context, String title, IconData icon,
      String route, {bool showBadge = false}) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isPaid,
      builder: (context, isPaid, child) {
        return ListTile(
          onTap: () {
            // ✅ Si el usuario es admin, no aplicar la restricción
            if (_isAdmin == true) {
              if (ModalRoute
                  .of(context)
                  ?.settings
                  .name != route) {
                Navigator.pushNamed(context, route);
              }
              return;
            }

            // 🔥 Solo restringimos a usuarios NO admin
            if (!isPaid && !_isTrial) {
              _showPaymentDialog(context);
              return;
            }
            print('isPaid: $isPaid, isTrial: $_isTrial, isAdmin: $_isAdmin');

            if (ModalRoute
                .of(context)
                ?.settings
                .name != route) {
              Navigator.pushNamed(context, route);
            }
          },
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: primary, size: 20),
              if (showBadge)
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
            style: const TextStyle(color: Colors.black, fontSize: 13),
          ),
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text("Acceso restringido"),
          content: const Text(
            "Para acceder a esta sección, debes pagar la suscripción.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ✅ Usa el context del diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // ✅ Cierra el diálogo

                final configSnapshot = await FirebaseFirestore.instance
                    .collection('configuraciones')
                    .limit(1)
                    .get();

                final int valorSuscripcion =
                (configSnapshot.docs.first.data()['valor_subscripcion'] ?? 0).toInt();

                final user = FirebaseAuth.instance.currentUser;
                if (user == null || !context.mounted) return;

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

                        // ✅ Actualiza el estado del menú para mostrar contenido desbloqueado
                        _isPaid.value = true;
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                );
              },
              child: const Text("Realizar pago"),
            ),
          ],
        );
      },
    );
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
