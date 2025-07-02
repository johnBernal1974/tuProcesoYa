import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuprocesoya/commons/side_bar_menu.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../widgets/tabla_tarifas.dart';
import '../widgets/whatApp_chat_page.dart';
import '../widgets/whatsapp_state.dart';
import '../widgets/whtasApp_floting_button.dart';
import 'admin_provider.dart'; // Importamos la clase AdminProvider
import 'dart:html' as html;


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
  bool _isAdmin = false;
  bool _isLoadingAdminCheck = true;
  String? _ultimaConversacionId;

  @override
  void initState() {
    super.initState();
    _checkIfUserIsAdmin();
  }

  Future<void> _checkIfUserIsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool isAdmin = await _adminProvider.isUserAdmin(user.uid);
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
        _isLoadingAdminCheck = false;
      });
    }

    if (_isAdmin) {
      await _adminProvider.loadAdminData(); // Cargar solo si es admin
      setState(() {}); // Refrescar el widget con el nombre del admin
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    double width = MediaQuery.of(context).size.width;
    bool isTablet = width >= 600 && width < 1200;
    bool isDesktop = width >= 1200;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey.shade100,
      drawer: const SideBar(),
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
                if (_isLoadingAdminCheck) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }
                if (!_isAdmin) return const SizedBox();
                if (_adminProvider.adminName == null) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }
                return Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            insetPadding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: TablaPreciosWidget(),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_view, color: Colors.white),
                      label: const Text(
                        "Tarifas",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
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
                  ],
                );
              },
            ),

        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Flex(
                  direction: Axis.horizontal,
                  children: [
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
          if (_isAdmin)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('whatsapp_conversations')
                      .orderBy('lastMessageAt', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return WhatsAppChatFloatingButton(
                        acudienteNombre: "",
                        isPaid: false,
                        numeroCliente: "",
                        hasUnread: false,
                        onTap: () {},
                      );
                    }

                    final doc = snapshot.data!.docs.first;
                    final conversationId = doc['conversationId'] ?? '';
                    final hasUnread = doc['hasUnread'] == true;

                    // 🔔 Revisa si es una conversación nueva
                    if (_ultimaConversacionId == null) {
                      _ultimaConversacionId = doc.id;
                    } else if (_ultimaConversacionId != doc.id) {
                      _ultimaConversacionId = doc.id;
                      _playNotificationSound(); // ✅ Aquí reproducimos el sonido
                    }

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Ppl')
                          .where('celularWhatsapp',
                          isEqualTo: conversationId.startsWith('57')
                              ? conversationId.substring(2)
                              : conversationId)
                          .limit(1)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox();
                        }

                        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                          return WhatsAppChatFloatingButton(
                            acudienteNombre: "",
                            isPaid: false,
                            numeroCliente: "",
                            hasUnread: hasUnread,
                            onTap: () {},
                          );
                        }

                        final userData = userSnapshot.data!.docs.first;
                        final acudienteNombre =
                        "${userData['nombre_acudiente'] ?? ''} ${userData['apellido_acudiente'] ?? ''}".trim();
                        final isPaid = userData['isPaid'] == true;

                        return WhatsAppChatFloatingButton(
                          acudienteNombre: acudienteNombre,
                          isPaid: isPaid,
                          numeroCliente: conversationId.startsWith("57")
                              ? conversationId
                              : "57$conversationId",
                          hasUnread: hasUnread,
                          onTap: () {
                            selectedNumeroCliente.value = conversationId.startsWith("57")
                                ? conversationId
                                : "57$conversationId";
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WhatsAppChatPage(),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
  void _playNotificationSound() {
    final audio = html.AudioElement('sounds/notifica_whatsapp.mp3');
    audio.play();
  }
}
