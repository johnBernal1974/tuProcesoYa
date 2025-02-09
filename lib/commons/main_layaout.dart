import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final user = FirebaseAuth.instance.currentUser;
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width >= 600 && width < 1200;
    bool isDesktop = width >= 1200;

    return Scaffold(
      backgroundColor: blanco,
      drawer: isDesktop ? null : const SideBar(),
      appBar: AppBar(
        title: Text(
          pageTitle,
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
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('admin')
                  .doc(user.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data!.exists) {
                  final adminData =
                  snapshot.data!.data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            adminData['name'],
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );

                }
                return const SizedBox.shrink();
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
