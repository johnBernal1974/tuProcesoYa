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

  @override
  void initState() {
    super.initState();
    _fetchPendingSuggestions();
    _checkIfAdmin();

  }

  Future<void> _checkIfAdmin() async {
    final prefs = await SharedPreferences.getInstance();

    // Revisa si ya tenemos el valor almacenado
    if (prefs.containsKey('isAdmin')) {
      setState(() {
        _isAdmin = prefs.getBool('isAdmin');
        _isLoading = false; // Termina la carga
      });
      return;
    }

    // Si no está en SharedPreferences, consulta Firestore
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isAdmin = false;
        _isLoading = false;
      });
      return;
    }

    final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(userId).get();

    if (mounted) {
      setState(() {
        _isAdmin = adminDoc.exists;
        _isLoading = false;
      });
      await prefs.setBool('isAdmin', adminDoc.exists); // Guarda el valor
    }
  }


  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 1,
      child: Container(
        color: violetaOscuro,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) // Muestra un loader mientras carga
            : ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 40),
            _buildDrawerHeader(_isAdmin),
            const Divider(height: 1, color: grisMedio),
            ..._buildDrawerItems(context, _isAdmin),
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
      decoration: const BoxDecoration(color: blancoCards),
      child: Column(
        children: [
          Image.asset('assets/images/logo_tu_proceso_ya_transparente.png', height: 40),
          if (isAdmin == true) const Text("Administrador"),
        ],
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, bool? isAdmin) {
    if (isAdmin == true) {
      // Menú para administradores
      return [
        const SizedBox(height: 50),
        _buildDrawerTile(context, "Página principal", Icons.home_filled, 'home_admin'),
        _buildDrawerTile(context, "Buzón de sugerencias", Icons.mark_email_unread_outlined, 'buzon_sugerencias_administrador', showBadge: _pendingSuggestions > 0),
        _buildDrawerTile(context, "Configuraciones", Icons.settings, 'configuraciones_admin'),
        _buildDrawerTile(context, "Solicitudes derechos petición", Icons.add_alert_outlined, 'solicitudes_derecho_peticion_admin'),
        _buildLogoutTile(context),
      ];
    } else {
      // Menú para usuarios normales
      return [
        const SizedBox(height: 50),
        _buildDrawerTile(context, "Home", Icons.home_filled, 'home'),
        _buildDrawerTile(context, "Mis datos", Icons.person_pin, 'mis_datos'),
        _buildDrawerTile(context, "Derechos del condenado", Icons.monitor_heart_rounded, 'derechos_info'),
        _buildDrawerTile(context, "Solicitar servicios", Icons.event_note_outlined, 'solicitudes_page'),
        _buildDrawerTile(context, "Quienes somos", Icons.info, 'nosotros'),
        _buildDrawerTile(context, "Buzón de sugerencias", Icons.mark_email_unread_outlined, 'buzon_sugerencias'),
        _buildLogoutTile(context),
      ];
    }
  }


  Widget _buildDrawerTile(BuildContext context, String title, IconData icon, String route, {bool showBadge = false}) {
    return ListTile(
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white),
          if (showBadge) // Si hay sugerencias sin responder, muestra el punto rojo
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
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }



  Widget _buildLogoutTile(BuildContext context) {
    return DrawerListTitle(
      title: "Cerrar sesión",
      icon: Icons.exit_to_app,
      press: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: blanco,
              title: const Text("Confirmación"),
              content: const Text("¿Estás seguro de que deseas cerrar sesión?",
                  style: TextStyle(color: Colors.black)),
              actions: <Widget>[
                TextButton(
                  child: const Text("SI", style: TextStyle(color: Colors.black)),
                  onPressed: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('isAdmin'); // 🔹 BORRA EL ESTADO GUARDADO
                      await _authProvider.signOut();
                      AdminProvider().reset();
                      if(context.mounted){
                        Navigator.of(context).pop();
                        Navigator.pushNamedAndRemoveUntil(context, 'login', (Route<dynamic> route) => false);
                      }

                    } catch (e) {
                      if(context.mounted){
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error al cerrar sesión"),
                          ),
                        );
                      }
                    }
                  },
                ),
                TextButton(
                  child: const Text("NO", style: TextStyle(color: Colors.black)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
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
        color: iconColor ?? Colors.white,
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
