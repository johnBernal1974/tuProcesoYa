

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../src/colors/colors.dart';

class WhatsAppChatPage extends StatefulWidget {
  const WhatsAppChatPage({Key? key}) : super(key: key);

  @override
  State<WhatsAppChatPage> createState() => _WhatsAppChatPageState();
}

class _WhatsAppChatPageState extends State<WhatsAppChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, String> _pplNombres = {};
  final ValueNotifier<String?> selectedNumeroCliente = ValueNotifier<String?>(null);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Map<String, Uint8List> _imageCache = {};




  @override
  void initState() {
    super.initState();
    _cargarNombresPpl();
  }


  Future<void> _cargarNombresPpl() async {
    final query = await FirebaseFirestore.instance.collection('Ppl').get();

    setState(() {
      _pplNombres = {
        for (var d in query.docs)
          d['celularWhatsapp']?.toString() ?? '': '${d['nombre_acudiente'] ?? ''} ${d['apellido_acudiente'] ?? ''}'.trim()
      };
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blancoCards,
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Chat WhatsApp",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      body: Row(
        children: [
          // Columna izquierda: lista de conversaciones
          Container(
            width: 500,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Card(
              color: blanco,
              surfaceTintColor: blanco,
              elevation: 3,
              margin: EdgeInsets.zero, // Para que ocupe todo el ancho
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: Padding(
                padding: const EdgeInsets.only(top: 8), // Un poco de separación arriba
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('whatsapp_conversations')
                      .orderBy('lastMessageAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(child: Text("No hay conversaciones"));
                    }

                    return ValueListenableBuilder<String?>(
                      valueListenable: selectedNumeroCliente,
                      builder: (context, selectedValue, _) {
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index];
                            final conversationId = data['conversationId'];
                            final lastMessage = data['lastMessage'] ?? '';
                            final createdAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
                            final hasUnread = data['hasUnread'] == true;
                            final isSelected = conversationId == selectedValue;

                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Ppl')
                                  .where('celularWhatsapp',
                                  isEqualTo: conversationId.startsWith('57')
                                      ? conversationId.substring(2)
                                      : conversationId)
                                  .limit(1)
                                  .get(),
                              builder: (context, snapshotPpl) {
                                String displayName = conversationId;
                                bool? isPaid;
                                if (snapshotPpl.hasData && snapshotPpl.data!.docs.isNotEmpty) {
                                  final d = snapshotPpl.data!.docs.first;
                                  final nombreAcudiente = d['nombre_acudiente'] ?? '';
                                  final apellidoAcudiente = d['apellido_acudiente'] ?? '';
                                  displayName = "$nombreAcudiente $apellidoAcudiente";
                                  isPaid = d['isPaid'] == true;
                                }

                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade50,
                                    child: const Icon(Icons.person, color: Colors.green),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          displayName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (createdAt != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "${createdAt.day.toString().padLeft(2, '0')}/"
                                                  "${createdAt.month.toString().padLeft(2, '0')}/"
                                                  "${createdAt.year} "
                                                  "${createdAt.hour.toString().padLeft(2, '0')}:"
                                                  "${createdAt.minute.toString().padLeft(2, '0')}",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            if (hasUnread)
                                              Container(
                                                margin: const EdgeInsets.only(top: 4),
                                                width: 14,
                                                height: 14,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastMessage,
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isPaid != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isPaid ? Icons.check_circle : Icons.cancel,
                                                size: 16,
                                                color: isPaid ? Colors.green : Colors.redAccent,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isPaid ? "Suscrito" : "Sin pago",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isPaid ? Colors.green : Colors.redAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () async {
                                    selectedNumeroCliente.value = conversationId;

                                    // ✅ Marcar todos los mensajes como leídos
                                    await FirebaseFirestore.instance
                                        .collection('whatsapp_messages')
                                        .where('conversationId', isEqualTo: conversationId)
                                        .where('isRead', isEqualTo: false)
                                        .where('from', isNotEqualTo: 'admin')
                                        .get()
                                        .then((q) async {
                                      for (var d in q.docs) {
                                        await d.reference.update({'isRead': true});
                                      }
                                    });

                                    // ✅ Marcar la conversación como leída
                                    await FirebaseFirestore.instance
                                        .collection('whatsapp_conversations')
                                        .doc(conversationId)
                                        .set({'hasUnread': false}, SetOptions(merge: true));
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          // Columna derecha: mensajes del cliente seleccionado
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: selectedNumeroCliente,
              builder: (context, numero, _) {
                if (numero == null) {
                  return const Center(
                    child: Text("Selecciona una conversación"),
                  );
                }

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Ppl')
                      .where('celularWhatsapp',
                      isEqualTo: numero.startsWith('57') ? numero.substring(2) : numero)
                      .limit(1)
                      .get(),
                  builder: (context, snapshotPpl) {
                    String nombreAcudiente = "Sin registro";
                    String nombrePpl = "";
                    bool isPaid = false;

                    if (snapshotPpl.hasData && snapshotPpl.data!.docs.isNotEmpty) {
                      final d = snapshotPpl.data!.docs.first;
                      nombreAcudiente = "${d['nombre_acudiente'] ?? ''} ${d['apellido_acudiente'] ?? ''}".trim();
                      nombrePpl = "${d['nombre_ppl'] ?? ''} ${d['apellido_ppl'] ?? ''}".trim();
                      isPaid = d['isPaid'] == true;
                    }

                    return Container(
                      color: Colors.brown.shade50,
                      child: Column(
                        children: [
                          // 🔹 Barra superior con info del usuario
                          Card(
                            color: blanco,
                            surfaceTintColor: blanco,
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.green.shade50,
                                    child: const Icon(Icons.person, color: Colors.green),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombreAcudiente,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        if (nombrePpl.isNotEmpty)
                                          Text(
                                            nombrePpl,
                                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          ),
                                        Text(
                                          numero,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              isPaid ? Icons.check_circle : Icons.cancel,
                                              size: 16,
                                              color: isPaid ? Colors.green : Colors.redAccent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isPaid ? "Suscripción al día" : "Sin pago",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isPaid ? Colors.green : Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('whatsapp_messages')
                                  .where('conversationId', isEqualTo: numero)
                                  .orderBy('createdAt', descending: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Center(child: Text("Error: ${snapshot.error}"));
                                }

                                final docs = snapshot.data?.docs ?? [];

                                if (docs.isEmpty) {
                                  return const Center(child: Text("No hay mensajes"));
                                }

                                return ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                  itemCount: docs.length,
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final data = doc.data() as Map<String, dynamic>;
                                    final text = data['text'] ?? '';
                                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                                    final from = data['from'] ?? '';
                                    final isAdmin = from == 'admin';
                                    final mediaType = data.containsKey('mediaType') ? data['mediaType'] : null;
                                    final mediaId = data.containsKey('mediaId') ? data['mediaId'] : null;

                                    Widget content;

                                    if (mediaType == 'image' && mediaId != null) {
                                      // Si ya está en cache
                                      if (_imageCache.containsKey(mediaId)) {
                                        final bytes = _imageCache[mediaId]!;

                                        return _buildImageMessage(isAdmin, bytes);
                                      }

                                      // Si no está en cache, descargarla
                                      return FutureBuilder<http.Response>(
                                        future: http.get(
                                          Uri.parse('https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getMediaFile?mediaId=$mediaId'),
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 150,
                                              height: 150,
                                              child: Center(child: CircularProgressIndicator()),
                                            );
                                          }

                                          if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
                                            return const Text("Error cargando imagen");
                                          }

                                          final bytes = snapshot.data!.bodyBytes;

                                          // Guardar en cache
                                          _imageCache[mediaId] = bytes;

                                          return _buildImageMessage(isAdmin, bytes);
                                        },
                                      );
                                    }
                                    else if (mediaType == 'audio') {
                                      content = const Text(
                                        '🎵 Mensaje de audio recibido',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                      );
                                    } else if (mediaType == 'document') {
                                      content = const Text(
                                        '📄 Documento recibido',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                      );
                                    } else {
                                      content = Text(
                                        text,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.1,
                                        ),
                                        textHeightBehavior: const TextHeightBehavior(
                                          applyHeightToFirstAscent: false,
                                          applyHeightToLastDescent: true,
                                        ),
                                      );
                                    }

                                    return Align(
                                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Card(
                                        surfaceTintColor: blanco,
                                        elevation: 1.5,
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          child: Stack(
                                            children: [
                                              // Contenido dinámico
                                              Padding(
                                                padding: const EdgeInsets.only(right: 50),
                                                child: content,
                                              ),
                                              if (createdAt != null)
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: Text(
                                                    '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          // 🔹 Caja de texto dentro de una Card
                          Padding(
                            padding: const EdgeInsets.all(12), // margen alrededor de la card
                            child: Card(
                              color: blanco,
                              surfaceTintColor: blanco,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Escribe un mensaje...',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send, color: Colors.deepPurple),
                                      onPressed: _sendMessage,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )

                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildImageMessage(bool isAdmin, Uint8List bytes) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: InteractiveViewer(
                maxScale: 8.0,
                minScale: 0.5,
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 200,
          ),
          child: Card(
            elevation: 1.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _sendMessage() async {
    if (selectedNumeroCliente == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('whatsapp_messages').add({
      'from': 'admin',
      'conversationId': selectedNumeroCliente,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }
}
