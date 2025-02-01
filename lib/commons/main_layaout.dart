import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/side_bar_menu.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

class MainLayout extends StatelessWidget {
  final Widget content;
  final String pageTitle;

  const MainLayout({Key? key, required this.content, required this.pageTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery
        .of(context)
        .size
        .width; // Obtén el ancho de la pantalla
    bool isTablet = width >= 600 && width < 1200;
    bool isDesktop = width >= 1200;

    return Scaffold(
      backgroundColor: blanco,
      drawer: isDesktop ? null : const SideBar(),
      // Sidebar fijo en PC, Drawer en móviles y tablets
      appBar: AppBar(
        title: Text(pageTitle,
            style: const TextStyle(color: blanco, fontWeight: FontWeight.w900)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: blanco),
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
                      maxWidth: isDesktop ? 1200 : double.infinity, // Máximo 1200px en escritorio
                    ),
                    margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 40 : 20),
                    // Márgenes adaptables
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    // Espaciado superior
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: content,
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
