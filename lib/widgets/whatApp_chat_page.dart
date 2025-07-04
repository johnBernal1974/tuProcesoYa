
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:tuprocesoya/widgets/reproductor_audios_whatsApp.dart';
import 'package:tuprocesoya/widgets/whatsapp_state.dart';
import 'dart:convert';
import '../src/colors/colors.dart';
import 'dart:html' as html;


class WhatsAppChatPage extends StatefulWidget {
  const WhatsAppChatPage({Key? key}) : super(key: key);

  @override
  State<WhatsAppChatPage> createState() => _WhatsAppChatPageState();
}

class _WhatsAppChatPageState extends State<WhatsAppChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, String> _pplNombres = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, Uint8List> _audioCache = {};
  final Map<String, Uint8List> _documentCache = {};
  final ValueNotifier<Map<String, dynamic>?> _mensajeRespondido = ValueNotifier(null);
  bool _enviando = false;


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

      body: LayoutBuilder(
        builder: (context, constraints) {
          final esPequena = esPantallaPequena(context);

          if (esPequena) {
            // Pantalla pequeña: solo lista de conversaciones
            return _buildListaConversaciones(true);
          }

          // Pantalla grande: lista + conversación
          return Row(
            children: [
              _buildListaConversaciones(false),
              Expanded(
                child: ValueListenableBuilder<String?>(
                  valueListenable: selectedNumeroCliente,
                  builder: (context, numero, _) {
                    if (numero == null) {
                      return const Center(child: Text("Selecciona una conversación"));
                    }
                    return _buildChatConversacion(numero, false);
                  },
                ),
              ),
            ],
          );
        },
      ),

    );
  }

  Widget _buildChatConversacion(String numero, bool esPequena) {
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
          padding: esPequena ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12),
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

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: esPequena
                          ? const EdgeInsets.fromLTRB(10, 15, 10, 80)
                          : const EdgeInsets.fromLTRB(50, 15, 50, 80),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final fileName = data['fileName'] ?? 'Documento.pdf';
                        final text = data['text'] ?? '';
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                        final from = data['from'] ?? '';
                        final isAdmin = from == 'admin';
                        final mediaType = data.containsKey('mediaType') ? data['mediaType'] : null;
                        final mediaId = data.containsKey('mediaId') ? data['mediaId'] : null;

                        Widget content;

                        if (mediaType == 'image' && mediaId != null) {
                          // ✅ Si ya está en cache, NO vuelvas a pedirlo
                          if (_imageCache.containsKey(mediaId)) {
                            final bytes = _imageCache[mediaId]!;
                            return _buildImageMessage(
                              isAdmin,
                              bytes,
                              doc.id,
                              mediaId: mediaId,
                              from: data['from'],
                              createdAt: createdAt,
                            );
                          }

                          // Si no, pídelo por HTTP
                          return FutureBuilder<http.Response>(
                            future: http.get(
                              Uri.parse('https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getMediaFile?mediaId=$mediaId'),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Align(
                                  alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                  child: _buildImagePlaceholder(),
                                );
                              }

                              if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
                                return Align(
                                  alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                  child: _buildImagePlaceholder(),
                                );
                              }

                              final bytes = snapshot.data!.bodyBytes;
                              _imageCache[mediaId] = bytes;

                              return _buildImageMessage(isAdmin, bytes, doc.id, mediaId: mediaId, from: data['from']);
                            },
                          );
                        }
                        else if (mediaType == 'audio' && mediaId != null) {
                          if (_audioCache.containsKey(mediaId)) {
                            final bytes = _audioCache[mediaId]!;
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
                                      Padding(
                                        padding: const EdgeInsets.only(right: 50),
                                        child: AudioPlayerWeb(bytes: bytes),
                                      ),
                                      if (createdAt != null)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Text(
                                            formatTimeAMPM(createdAt),
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
                          }

                          return FutureBuilder<http.Response>(
                            future: http.get(
                              Uri.parse('https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getMediaFile?mediaId=$mediaId'),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildAudioPlaceholder();
                              }

                              if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
                                return _buildAudioPlaceholder();
                              }

                              final bytes = snapshot.data!.bodyBytes;
                              _audioCache[mediaId] = bytes;

                              return AudioPlayerWeb(bytes: bytes);
                            },
                          );
                        }

                        else if (mediaType == 'document' && mediaId != null) {
                          if (_documentCache.containsKey(mediaId)) {
                            final bytes = _documentCache[mediaId]!;
                            return _buildDocumentCard(bytes, text, createdAt ?? DateTime.now());
                          }

                          return FutureBuilder<http.Response>(
                            future: http.get(
                              Uri.parse('https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getMediaFile?mediaId=$mediaId'),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildDocumentPlaceholder();
                              }

                              if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
                                return _buildDocumentPlaceholder();
                              }

                              final bytes = snapshot.data!.bodyBytes;
                              _documentCache[mediaId] = bytes;

                              return _buildDocumentCard(bytes, fileName, createdAt ?? DateTime.now());
                            },
                          );
                        }
                        else {
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
                            color: isAdmin ? const Color(0xFFFFF3E0)
                                : Colors.white,
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
                                        formatTimeAMPM(createdAt),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mostrar la respuesta si hay
                    ValueListenableBuilder<Map<String, dynamic>?>(
                      valueListenable: _mensajeRespondido,
                      builder: (context, respuesta, _) {
                        if (respuesta == null) return const SizedBox();
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              if (respuesta['esImagen'])
                                const Icon(Icons.image, size: 20, color: Colors.black54)
                              else
                                const Icon(Icons.format_quote, size: 20, color: Colors.black54),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  respuesta['contenido'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  _mensajeRespondido.value = null;
                                },
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    // Campo de texto
                    Card(
                      color: blanco,
                      surfaceTintColor: blanco,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildListaConversaciones(bool esPequena) {
    return Container(
      width: esPequena ? double.infinity : 500,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Card(
        color: blanco,
        surfaceTintColor: blanco,
        elevation: 3,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
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
                              backgroundColor: snapshotPpl.hasData && snapshotPpl.data!.docs.isNotEmpty
                                  ? (isPaid == true ? Colors.green.shade50 : Colors.red.shade50)
                                  : Colors.grey.shade300,
                              child: Icon(
                                snapshotPpl.hasData && snapshotPpl.data!.docs.isNotEmpty
                                    ? (isPaid == true ? Icons.verified_user_rounded : Icons.mood_bad)
                                    : Icons.new_releases,
                                color: snapshotPpl.hasData && snapshotPpl.data!.docs.isNotEmpty
                                    ? (isPaid == true ? Colors.green : Colors.red)
                                    : Colors.grey,
                              ),
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
                                            "${formatTimeAMPM(createdAt)}",
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
                            subtitle: Builder(
                              builder: (context) {
                                Widget content;

                                if (lastMessage == "(Imagen)") {
                                  content = const Row(
                                    children: [
                                      Icon(Icons.photo, size: 16, color: Colors.black54),
                                      SizedBox(width: 4),
                                      Text(
                                        "Foto",
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ],
                                  );
                                } else if (lastMessage == "(Audio)") {
                                  content = const Row(
                                    children: [
                                      Icon(Icons.mic, size: 16, color: Colors.black54),
                                      SizedBox(width: 4),
                                      Text(
                                        "Audio",
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ],
                                  );
                                } else if (lastMessage == "(Documento)") {
                                  content = const Row(
                                    children: [
                                      Icon(Icons.insert_drive_file, size: 16, color: Colors.black54),
                                      SizedBox(width: 4),
                                      Text(
                                        "Documento",
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ],
                                  );
                                } else {
                                  content = Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  );
                                }

                                return content;
                              },
                            ),
                            onTap: () async {
                              if (esPequena) {
                                // En móvil, navega a otra pantalla
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(
                                      backgroundColor: Colors.green,
                                      title: Text(displayName),
                                    ),
                                    body: _buildChatConversacion(conversationId, esPequena),
                                  ),
                                ));
                              } else {
                                // En escritorio, selecciona
                                selectedNumeroCliente.value = conversationId;
                              }

                              // Marcar como leído
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
    );
  }

  Widget _buildDocumentCard(Uint8List bytes, String fileName, DateTime createdAt) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        elevation: 1.5,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 280, // Máximo ancho
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min, // 👈 Esto es clave
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono PDF
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 10),
                // Nombre y detalles
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "PDF • ${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatTimeAMPM(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                // Botón abrir
                GestureDetector(
                  onTap: () {
                    final blob = html.Blob([bytes], 'application/pdf');
                    final url = html.Url.createObjectUrlFromBlob(blob);
                    html.window.open(url, "_blank");
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.download, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(
      bool isAdmin,
      Uint8List bytes,
      String messageId, {
        String? mediaId,
        String? from,
        DateTime? createdAt, // ⚠️ Asegúrate de que al llamar pases createdAt
      }) {
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
            maxWidth: 250,
          ),
          child: Card(
            elevation: 1.5,
            color: isAdmin ? const Color(0xFFFBC02D)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Imagen + menú
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.black87),
                        onSelected: (value) async {
                          if (value == 'borrar') {
                            _borrarMensaje(messageId);
                          } else if (value == 'responder') {
                            _responderMensaje('Imagen', esImagen: true);
                          } else if (value == 'guardar') {
                            if (mediaId == null || from == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No se puede guardar esta imagen (faltan datos)")),
                              );
                              return;
                            }
                            final response = await http.post(
                              Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/guardarMediaFile"),
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"mediaId": mediaId, "from": from}),
                            );

                            if (response.statusCode == 200) {
                              final json = jsonDecode(response.body);
                              final publicUrl = json["url"];
                              await FirebaseFirestore.instance
                                  .collection("whatsapp_messages")
                                  .doc(messageId)
                                  .update({"publicUrl": publicUrl});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Imagen guardada correctamente")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Error guardando imagen")),
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'borrar',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.black87),
                                SizedBox(width: 8),
                                Text('Borrar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'responder',
                            child: Row(
                              children: [
                                Icon(Icons.reply, size: 18, color: Colors.black87),
                                SizedBox(width: 8),
                                Text('Responder'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'guardar',
                            child: Row(
                              children: [
                                Icon(Icons.save_alt, size: 18, color: Colors.black87),
                                SizedBox(width: 8),
                                Text('Guardar en los docs del usuario'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    child: Text(
                      formatTimeAMPM(createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _responderMensaje(String contenido, {bool esImagen = false}) {
    _mensajeRespondido.value = {
      'contenido': contenido,
      'esImagen': esImagen,
    };
  }

  void _borrarMensaje(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text('¿Borrar mensaje?'),
        content: const Text('Esta acción eliminará la imagen de forma permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade50,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Proceder a borrar
    await FirebaseFirestore.instance
        .collection('whatsapp_messages')
        .where('messageId', isEqualTo: messageId)
        .get()
        .then((query) {
      for (var doc in query.docs) {
        doc.reference.delete();
      }
    });
  }


  void _sendMessage() async {
    final numero = selectedNumeroCliente.value?.trim();
    if (numero == null || numero.isEmpty) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final respuesta = _mensajeRespondido.value;

    // 1. Guardar en Firestore para que se vea en la interfaz
    await FirebaseFirestore.instance.collection('whatsapp_messages').add({
      'from': 'admin',
      'conversationId': numero,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      if (respuesta != null) 'replyTo': respuesta,
    });

    print('DEBUG ENVÍO:');
    print('TO: "$numero"');
    print('TEXT: "$text"');

    // 2. Llamar la Cloud Function HTTP
    try {
      final url = Uri.parse(
          "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendWhatsAppMessage"
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'to': numero,
          'text': text,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Error enviando mensaje real: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error enviando mensaje real: $e');
    }

    _controller.clear();
    _mensajeRespondido.value = null;
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: const Text(
        "Imagen\nno disponible",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
  Widget _buildAudioPlaceholder() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: const Text(
        "Audio no disponible",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }
  Widget _buildDocumentPlaceholder() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      alignment: Alignment.center,
      child: const Text(
        "Documento no disponible",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
    );
  }

  bool esPantallaPequena(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }



  String formatTimeAMPM(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

}
