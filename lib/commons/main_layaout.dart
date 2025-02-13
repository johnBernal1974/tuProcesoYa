import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuprocesoya/commons/side_bar_menu.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import 'admin_provider.dart'; // Importamos la clase AdminProvider

class MainLayout extends StatefulWidget {
  final Widget content;
  final String pageTitle;

  const MainLayout({Key? key, required this.content, required this.pageTitle})
      : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final AdminProvider _adminProvider = AdminProvider(); // Instancia única

  @override
  void initState() {
    super.initState();
    print("🟢 initState() de MainLayout ejecutado");
    _adminProvider.loadAdminName(); // Carga solo si es necesario
  }

  @override
  Widget build(BuildContext context) {
    print("🔵 build() de MainLayout ejecutado");
    final user = FirebaseAuth.instance.currentUser;
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width >= 600 && width < 1200;
    bool isDesktop = width >= 1200;

    return Scaffold(
      backgroundColor: blanco,
      drawer: isDesktop ? null : const SideBar(),
      appBar: AppBar(
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            color: blanco,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: blanco),
        actions: [
          if (user != null)
            Builder(
              builder: (context) {
                if (_adminProvider.adminName == null) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _adminProvider.adminName!,
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Flex(
              direction: Axis.horizontal,
              children: [
                if (isDesktop)
                  const SizedBox(
                    width: 300,
                    child: SideBar(),
                  ),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : double.infinity,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 20),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: widget.content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
