import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    final configDoc = await FirebaseFirestore.instance.collection(
        'configuraciones').doc('general').get();
    final int tiempoDePrueba = configDoc.data()?['tiempoDePrueba'] ??
        7; // 🔹 Default 7 días

    final DateTime fechaRegistroDT = fechaRegistro.toDate();
    final DateTime fechaActual = DateTime.now();
    final int diasTranscurridos = fechaActual
        .difference(fechaRegistroDT)
        .inDays;

    setState(() {
      _isTrial = diasTranscurridos < tiempoDePrueba;
    });
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

    return Drawer(
      elevation: 1,
      child: Container(
        color: blanco,
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
          _buildDrawerTile(
              context, "Buzón de sugerencias", Icons.mark_email_unread_outlined,
              'buzon_sugerencias_administrador',
              showBadge: _pendingSuggestions > 0),
          _buildDrawerTile(context, "Configuraciones", Icons.settings,
              'configuraciones'),
          _buildDrawerTile(context, "atender tutela", Icons.settings,
              'atender_tutela'),
          _buildDrawerTile(context, "pa las tutelas", Icons.settings,
              'derechos_tutelables_page'),
          _buildDrawerTile(context, "Solicitudes derechos petición",
              Icons.add_alert_outlined, 'solicitudes_derecho_peticion_admin'),
          _buildDrawerTile(
              context, "Registrar Operadores", Icons.app_registration,
              'registrar_operadores'),
          _buildDrawerTile(
              context, "Operadores", Icons.account_box, 'operadores_page'),
          _buildDrawerTile(context, "Transacciones", Icons.account_box,
              'admin_transacciones'),
        ]);
      } else if (rol == "master") {
        items.addAll([
          _buildDrawerTile(
              context, "Página principal", Icons.home_filled, 'home_admin'),
          _buildDrawerTile(
              context, "Buzón de sugerencias", Icons.mark_email_unread_outlined,
              'buzon_sugerencias_administrador',
              showBadge: _pendingSuggestions > 0),
          _buildDrawerTile(context, "Solicitudes derechos petición",
              Icons.add_alert_outlined, 'solicitudes_derecho_peticion_admin'),
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
          _buildDrawerTile(context, "Solicitudes derechos petición",
              Icons.add_alert_outlined, 'solicitudes_derecho_peticion_admin'),
        ]);
      } else if (rol == "operador 1" || rol == "operador 2") {
        // Para operadores se muestran opciones básicas.
        items.addAll([
          _buildDrawerTile(
              context, "Página principal", Icons.home_filled, 'home_admin'),
        ]);
      } else
      if (rol == "pasante 1" || rol == "pasante 2" || rol == "pasante 3") {
        // Para pasantes, se muestra solo la página principal.
        items.add(
          _buildDrawerTile(context, "Solicitudes derechos petición",
              Icons.add_alert_outlined, 'solicitudes_derecho_peticion_admin'),
        );
      }
    } else {
      // Menú para usuarios que no son admin.
      items.addAll([
        _buildDrawerTile(
            context, "Página principal", Icons.home_filled, 'home'),
        _buildDrawerTile(context, "Tus datos", Icons.person_pin, 'mis_datos'),
        _buildDrawerTile(context, "Solicitar servicios", Icons.edit_calendar,
            'solicitudes_page'),


        ExpansionTile(
          leading: const Icon(
              Icons.attach_money, color: Colors.black, size: 20),
          title: const Text(
              "Recargas", style: TextStyle(color: Colors.black, fontSize: 13)),
          iconColor: Colors.black,
          // 🔥 Color del icono cuando se expande
          collapsedIconColor: Colors.black,
          // 🔥 Color cuando está colapsado
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              // 🔥 Espaciado para cada elemento
              child: _buildDrawerTile(
                  context, "Recargar cuenta", Icons.monetization_on_outlined,
                  'checkout_wompi'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              // 🔥 Espaciado para cada elemento
              child: _buildDrawerTile(
                  context, "Tus transacciones", Icons.payments_rounded,
                  'mis_transacciones'),
            ),
          ],
        ),

        ExpansionTile(
          leading: const Icon(Icons.add_chart, color: Colors.black, size: 20),
          title: const Text("Historiales",
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
                  context, "Tus Solicitudes derecho peticion",
                  Icons.history_edu_outlined,
                  'historial_solicitudes_derechos_peticion'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              // 🔥 Espaciado para cada elemento
              child: _buildDrawerTile(
                  context, "Tus Redenciones", Icons.filter_9_plus_outlined,
                  'mis_redenciones'),
            ),
          ],
        ),

        // 🔥 Submenú "Información general"
        ExpansionTile(
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text("Acceso restringido"),
          content: const Text(
              "Para acceder a esta sección, debes pagar la suscripción."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, 'checkout_wompi');
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
