import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchPendingSuggestions();
  }

  Future<bool> _checkIfAdmin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return false; // El usuario no está autenticado
    }

    final adminsCollection = FirebaseFirestore.instance.collection('admin');
    final adminDoc = await adminsCollection.doc(userId).get();

    return adminDoc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkIfAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Drawer(
            elevation: 1,
            child: Container(
              color: violetaOscuro,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 40),
                  _buildDrawerHeader(snapshot.data),
                  const Divider(height: 1, color: grisMedio),
                  ..._buildDrawerItems(context, snapshot.data),
                ],
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
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

  Widget _buildDrawerHeader(bool? isAdmin) {
    if (isAdmin ?? false) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: const BoxDecoration(
          color: blancoCards,
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo_tu_proceso_ya_transparente.png',
              height: 40,
            ),
            const Text("Administrador")
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: const BoxDecoration(
          color: blancoCards,
        ),
        child: Image.asset(
          'assets/images/logo_tu_proceso_ya_transparente.png',
          height: 40,
        ),
      );
    }
  }

  List<Widget> _buildDrawerItems(BuildContext context, bool? isAdmin) {
    if (isAdmin == true) {
      return [
        const SizedBox(height: 50),
        _buildDrawerTile(context, "Página principal", Icons.home_filled, 'home_admin'),
        _buildDrawerTile(context, "Buzón de sugerencias", Icons.mark_email_unread_outlined, 'buzon_sugerencias_administrador', showBadge: _pendingSuggestions > 0),
        _buildDrawerTile(context, "Configuraciones", Icons.settings, 'prices_page'),
        _buildLogoutTile(context),
      ];
    } else {
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
