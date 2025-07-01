import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WhatsAppChatWidget extends StatefulWidget {
  final String numeroCliente;

  const WhatsAppChatWidget({
    Key? key,
    required this.numeroCliente,
  }) : super(key: key);

  @override
  State<WhatsAppChatWidget> createState() => _WhatsAppChatWidgetState();
}

class _WhatsAppChatWidgetState extends State<WhatsAppChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('whatsapp_messages')
                .where('conversationId', isEqualTo: widget.numeroCliente)
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(child: Text('No hay mensajes'));
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index];
                  final text = data['text'] ?? '';
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (createdAt != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
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
      ],
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('whatsapp_messages').add({
      'from': 'admin',
      'conversationId': widget.numeroCliente,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }
}
