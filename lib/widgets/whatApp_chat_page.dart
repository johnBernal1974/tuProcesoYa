
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tuprocesoya/widgets/reproductor_audios_whatsApp.dart';
import 'package:tuprocesoya/widgets/whatsapp_state.dart';
import '../commons/admin_provider.dart';
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
  final ValueNotifier<String> _searchTerm = ValueNotifier<String>('');
  final Map<String, Uint8List> _imageCache = {};
  final Map<String, Uint8List> _audioCache = {};
  final Map<String, Uint8List> _documentCache = {};
  final ValueNotifier<Map<String, dynamic>?> _mensajeRespondido = ValueNotifier(null);
  bool _enviando = false;
  bool tieneServicioSolicitado = false;
  Set<String> _usuariosConSolicitudes = {};
  bool _cargandoSolicitudes = true;


  @override
  void initState() {
    super.initState();
    _cargarNombresPpl();
    _cargarSolicitudes();
    _searchController.addListener(() {
      _searchTerm.value = _searchController.text.toLowerCase().trim();
    });

  }

  void _cargarSolicitudes() async {
    final ids = await _obtenerIdsConSolicitudes();
    setState(() {
      _usuariosConSolicitudes = ids;
      _cargandoSolicitudes = false;
    });
  }

  Future<Set<String>> _obtenerIdsConSolicitudes() async {
    final snapshot = await FirebaseFirestore.instance.collection('solicitudes_usuario').get();

    return snapshot.docs
        .map((s) => s['idUser']?.toString())
        .where((id) => id != null)
        .cast<String>()
        .toSet();
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
        String idUsuario = "";

        if (snapshotPpl.hasData && snapshotPpl.data!.docs.isNotEmpty) {
          final d = snapshotPpl.data!.docs.first;
          idUsuario = d.id;
          nombreAcudiente = "${d['nombre_acudiente'] ?? ''} ${d['apellido_acudiente'] ?? ''}".trim();
          nombrePpl = "${d['nombre_ppl'] ?? ''} ${d['apellido_ppl'] ?? ''}".trim();
          isPaid = d['isPaid'] == true;
        }

        bool estaRegistrado = snapshotPpl.hasData && snapshotPpl.data!.docs.isNotEmpty;
        final tieneServicioSolicitado = _usuariosConSolicitudes.contains(idUsuario);


        return Container(
          color: blancoCards,
          padding: esPequena ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              // 🔹 Barra superior con info del usuario ///***nuevo cambio
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
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

                      // 🔹 Tarjeta morada si tiene solicitudes (sin onTap)
                      if (tieneServicioSolicitado)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: MediaQuery.of(context).size.width < 600
                              ? const Icon(Icons.assignment, color: Colors.deepPurple)
                              : Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.deepPurple, width: 1),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.assignment, color: Colors.deepPurple),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tiene solicitudes',
                                    style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 🔹 Tarjeta blanca si está registrado (con navegación)
                      if (estaRegistrado)
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                'editar_registro_admin',
                                arguments: idUsuario,
                              );
                            },
                            child: MediaQuery.of(context).size.width < 600
                                ? const Icon(Icons.person_search, color: Colors.deepPurple)
                                : Card(
                              color: Colors.deepPurple,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_search, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Ver perfil',
                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // 🔹 Botón para enviar plantilla "cambio_estado"
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: MediaQuery.of(context).size.width < 600
                            ? IconButton(
                          tooltip: 'Notificar cambio de estado',
                          icon: const Icon(Icons.campaign, color: Colors.green),
                          onPressed: (!estaRegistrado || idUsuario.isEmpty)
                              ? null
                              : () => _enviarCambioEstado(numero, idUsuario),
                        )
                            : ElevatedButton.icon(
                          onPressed: (!estaRegistrado || idUsuario.isEmpty)
                              ? null
                              : () => _enviarCambioEstado(numero, idUsuario),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.campaign),
                          label: const Text('Notificar'),
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
                        final adminName = data['adminName'] ?? 'Admin';
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
                                      // if (createdAt != null)
                                      //   Positioned(
                                      //     bottom: 0,
                                      //     right: 0,
                                      //     child: Text(
                                      //       formatTimeAMPM(createdAt),
                                      //       style: const TextStyle(
                                      //         fontSize: 11,
                                      //         color: Colors.black87,
                                      //       ),
                                      //     ),
                                      //   ),
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
                          return FutureBuilder<http.Response>(
                            future: _documentCache.containsKey(mediaId)
                                ? Future.value(http.Response.bytes(_documentCache[mediaId]!, 200))
                                : http.get(
                              Uri.parse(
                                'https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/getMediaFile?mediaId=$mediaId',
                              ),
                            ),
                            builder: (context, snapshot) {
                              final alignment = isAdmin ? Alignment.centerRight : Alignment.centerLeft;
                              final crossAlign = isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start;

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Align(
                                  alignment: alignment,
                                  child: _buildDocumentPlaceholder(),
                                );
                              }

                              if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
                                return Align(
                                  alignment: alignment,
                                  child: _buildDocumentPlaceholder(),
                                );
                              }

                              final bytes = snapshot.data!.bodyBytes;
                              _documentCache[mediaId] = bytes;

                              return Align(
                                alignment: alignment,
                                child: Column(
                                  crossAxisAlignment: crossAlign,
                                  children: [
                                    _buildDocumentCard(bytes, fileName, createdAt ?? DateTime.now()),
                                    const SizedBox(height: 2),
                                    Text(
                                      isAdmin ? adminName : 'Usuario',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        else {
                          content = _buildMensaje(data);
                        }

                        return Builder(
                          builder: (context) {
                            final screenWidth = MediaQuery.of(context).size.width;
                            final bool isMobile = screenWidth < 600;

                            final double paddingLeft = isAdmin ? (isMobile ? 50.0 : 180.0) : 0.0;
                            final double paddingRight = isAdmin ? 0.0 : (isMobile ? 50.0 : 180.0);

                            return Align(
                              alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: paddingLeft,
                                  right: paddingRight,
                                ),
                                child: Column(
                                  crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    // Tarjeta del mensaje
                                    Card(
                                      surfaceTintColor: blanco,
                                      elevation: 1.5,
                                      color: isAdmin ? const Color(0xFFD7FFD9) : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            // 👉 Contenido del mensaje
                                            Padding(
                                              padding: const EdgeInsets.only(right: 0), // o ajusta si necesitas espacio
                                              child: content,
                                            ),

                                            const SizedBox(height: 6),

                                            // 👉 Hora y fecha debajo
                                            if (createdAt != null)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    formatTimeAMPM(createdAt),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    formatFechaSolo(createdAt),
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),


                                    // Nombre del admin debajo de la tarjeta
                                    if (isAdmin)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, right: 8),
                                        child: Text(
                                          adminName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
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

                    // Campo de texto con saltos de línea
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

                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.image),
                                            title: const Text("Imagen"),
                                            onTap: () {
                                              Navigator.pop(context);
                                              final numero = selectedNumeroCliente.value;
                                              if (numero != null) {
                                                adjuntarYEnviar(tipo: 'image', numeroDestino: numero);
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.insert_drive_file),
                                            title: const Text("Documento (PDF, Word)"),
                                            onTap: () {
                                              Navigator.pop(context);
                                              final numero = selectedNumeroCliente.value;
                                              if (numero != null) {
                                                adjuntarYEnviar(tipo: 'document', numeroDestino: numero);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                maxLines: null,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                decoration: const InputDecoration(
                                  hintText: 'Escribe un mensaje...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.deepPurple),
                              onPressed: () {
                                _sendMessage();

                                // 🔄 Limpia visualmente justo después del frame
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _controller.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 👇 BLOQUE QUE AGREGA EL SALUDO PERSONALIZADO
                    Builder(
                      builder: (context) {
                        final String numeroNormalizado = numero.startsWith('57') ? numero.substring(2) : numero;
                        final String? nombreCompleto = _pplNombres[numeroNormalizado];
                        final String primerNombre = nombreCompleto?.split(' ').first ?? '';

                        return SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildQuickMessageCard(
                                Icons.waving_hand,
                                "Bienvenida",
                                primerNombre.isNotEmpty
                                    ? "Hola $primerNombre, nos alegra poder atenderte. ¿En qué te podemos ayudar hoy?"
                                    : "Hola, nos alegra poder atenderte. ¿En qué te podemos ayudar hoy?",
                              ),

                              if (!estaRegistrado)
                              _buildQuickMessageCard(
                                Icons.lightbulb,
                                "Explicación\nservicio",
                                """
👋 ¡Hola! Bienvenid@ a *Tu Proceso Ya*.

🟣 Nuestra plataforma es completamente *auto gestionable*, lo que significa que puedes hacer todo el proceso desde tu celular o computador, *sin necesidad de conocimientos técnicos ni jurídicos*.

🛠️ Desde aquí puedes solicitar fácilmente:
✅ Derechos de petición  
✅ Tutelas  
✅ Permisos de 72 horas  
✅ Prisión domiciliaria  
✅ Libertad condicional  
✅ Extinción de la pena  
✅ Redenciones  
✅ Traslado de procesos  
✅ Acumulaciones de pena, entre otros.

👥 Al crear tu usuario, te guiamos paso a paso.  
🧭 Te damos todas las herramientas para que puedas convertirte en *la defensora o defensor de los derechos de tu familiar*.

🕒 El proceso de registro solo toma *unos minutos*.

🎁 Al activar tu usuario, tendrás *24 horas de prueba GRATIS* para:

🔍 Consultar los datos actualizados de la persona privada de la libertad  
📈 Ver qué beneficios puede solicitar  
📅 Saber cuánto tiempo le falta para cada beneficio  
📄 Conocer los documentos necesarios para cada trámite

💡 Es supremamente fácil y está diseñado para acompañarte en todo el proceso.
""",
                              ),

                              if (!estaRegistrado)
                              _buildQuickMessageCard(
                                Icons.app_registration,
                                "Como\nRegistrarse",
                                """
📝 *El proceso de registro es muy fácil*.

Solo ingresa al siguiente enlace, crea tu usuario y en un máximo de *72 horas* activaremos tu servicio:

👉 www.tuprocesoya.com
""",
                              ),

                              if (!estaRegistrado)
                              _buildQuickMessageCard(
                                Icons.info_outline,
                                "Necesario\nregistrarse",
                                """
ℹ️ Para poder orientarte y guiarte correctamente, es *indispensable que estés registrad@ en la plataforma*.

🧾 El registro nos permite acceder a los datos necesarios para darte una orientación clara y precisa, según el caso de tu familiar.

📝 Si aún no te has registrado, puedes hacerlo en pocos minutos aquí:  
👉 www.tuprocesoya.com
""",
                              ),

                              if (estaRegistrado && isPaid )
                              _buildQuickMessageCard(
                                Icons.handshake,
                                "Tienes un\nequipo",
                                """
Con todo gusto. Recuerda que con *Tu Proceso YA*, cuentas ahora con un equipo. Ya no estás sol@ en esta situación tan difícil.

Cuenta con nosotros.
""",
                              ),

                              if (estaRegistrado && isPaid )
                              _buildQuickMessageCard(
                                Icons.hourglass_top,
                                "Espera\nun momento",
                                """
Dame un momento, vamos a revisar tu caso con detenimiento y en breve te comparto la información.

Gracias por tu paciencia.
""",


                              ),
                              if (estaRegistrado && isPaid )
                                _buildQuickMessageCard(
                                    Icons.share,
                                    "Compartir\nLink",
                                    """
Puedes ingresar a la app en:
https://www.tuprocesoya.com
"""),



                              // 🔒 TARJETA 1 – Verificación de identidad (con confirmación)
                              _buildQuickMessageCard(
                                Icons.verified_user,
                                "Verificar\nidentidad",
                                _verificacionIdentidadMensaje(
                                  numero,
                                  nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                ),
                                onTap: () => _confirmarEnvioMensaje(
                                  _verificacionIdentidadMensaje(
                                    numero,
                                    nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                  ),
                                  "verificación de identidad",
                                ),
                              ),

// 🔒 TARJETA 2 – Consentimiento (con confirmación)
                              _buildQuickMessageCard(
                                Icons.privacy_tip,
                                "Borrado/\nSuspensión",
                                _consentimientoMensaje(
                                  numero,
                                  nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                ),
                                onTap: () => _confirmarEnvioMensaje(
                                  _consentimientoMensaje(
                                    numero,
                                    nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                  ),
                                  "consentimiento de borrado/suspensión",
                                ),
                              ),

                              // ✅ Confirmación – Opción 1: Borrado definitivo (48h)
                              // ✅ Confirmación – Opción 1: Borrado definitivo (48 h)
                              _buildQuickMessageCard(
                                Icons.delete_forever,
                                "Confirmar\nBorrado (1)",
                                _confirmacionBorradoMensaje(
                                  nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                  numeroE164: numero,
                                ),
                                onTap: () => _confirmarEnvioMensaje(
                                  _confirmacionBorradoMensaje(
                                    nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                    numeroE164: numero,
                                  ),
                                  "confirmación de borrado (opción 1)",
                                ),
                              ),

// ✅ Confirmación – Opción 2: Suspensión
                              _buildQuickMessageCard(
                                Icons.pause_circle_filled,
                                "Confirmar\nSuspensión (2)",
                                _confirmacionSuspensionMensaje(
                                  nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                  numeroE164: numero,
                                ),
                                onTap: () => _confirmarEnvioMensaje(
                                  _confirmacionSuspensionMensaje(
                                    nombre: primerNombre.isNotEmpty ? primerNombre : null,
                                    numeroE164: numero,
                                  ),
                                  "confirmación de suspensión (opción 2)",
                                ),
                              ),
                              if (estaRegistrado && !isPaid)
                                _buildQuickMessageCard(
                                  Icons.lock_outline,
                                  "Sin Pago\nsuscripción",
                                  """
Gracias por haber creado tu usuario en *Tu Proceso YA*.  
🔍 Hemos notado que aún no has activado tu suscripción.

🙌 Para poder atender todas tus preguntas y brindarte una orientación completa y adecuada, es necesario contar con la suscripción activa.

💡 Al activarla podrás:
✅ Consultar la información actualizada de tu familiar  
✅ Ver qué beneficios puede solicitar  
✅ Iniciar trámites directamente desde la plataforma  
✅ Recibir acompañamiento oportuno en cada paso

🎯 Tu apoyo es fundamental. Al activar tu cuenta estarás más cerca de tu familiar, ayudándole justo cuando más lo necesita.

📲 Puedes hacerlo en pocos minutos desde la aplicación.

❓ *Si necesitas ayuda para hacer el pago, escríbenos y con gusto te orientamos.* 💜
""",
                                ),

                              if (estaRegistrado && !isPaid)
                                _buildQuickMessageCard(
                                  Icons.discount,
                                  "¡Descuento\nespecial!",
                                  """
🎉 *¡Aprovecha esta oportunidad por tiempo limitado!*  
Sabemos lo importante que es apoyar a tu familiar en este momento, por eso queremos ayudarte con un *20% de descuento* si activas tu cuenta en las próximas *2 horas*.

🔓 Al activar tu suscripción podrás:
✅ Ver toda la información actualizada de tu familiar  
✅ Iniciar trámites de manera sencilla desde la plataforma  
✅ Saber si tiene derecho a beneficios y cuánto tiempo le falta  
✅ Recibir acompañamiento oportuno en cada paso

💳 Puedes pagar fácilmente desde cualquier lugar por:  
👉 Nequi  
👉 Daviplata  
👉 PSE  
👉 Tarjeta de crédito o débito

🌐 Solo ingresa aquí para activar con descuento:  
👉 *www.tuprocesoya.com*

💬 ¿Quieres que te generemos el descuento para que puedas ingresar de inmediato?

*Es ahora o nunca.* 💜
""",
                                ),
                            ],
                          ),
                        );
                      },
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

  //helper consentimiento
  // 🔒 CONSENTIMIENTO – Plantilla con número dinámico (y nombre opcional)
  String _consentimientoMensaje(String numeroE164, {String? nombre}) {
    // Muestra el número tal cual llega (E.164: 57XXXXXXXXXX).
    // Si usas formato diferente, ajústalo aquí.
    final saludo = (nombre != null && nombre.trim().isNotEmpty)
        ? "Continuemos $nombre,\n\n"
        : "Continuemos,\n\n";

    return """
${saludo}🟣 *Tu Proceso Ya* – Aviso sobre Protección de Datos Personales  

De acuerdo con la *Ley 1581 de 2012* y el *Decreto 1377 de 2013*, tienes derecho a conocer, actualizar, rectificar, suspender o eliminar tus datos personales en cualquier momento.  

📜 *Derechos del titular:*  
• Conocer qué datos tenemos y con qué finalidad.  
• Solicitar la corrección o actualización de tu información.  
• Pedir la suspensión o eliminación definitiva de tus datos personales.  
• Revocar en cualquier momento la autorización para el tratamiento de tus datos.  

📱 *Verificación de identidad:*  
Esta solicitud se gestiona mediante el número *$numeroE164*, el mismo con el cual fue creada tu cuenta y al que está vinculado tu usuario en *Tu Proceso Ya*.  

⚖️ *Repercusiones de tu decisión:*  
Si eliges eliminar tus datos, borraremos toda tu información registrada (historial, solicitudes, documentos y beneficios asociados).  
Esta acción es **irreversible**; si deseas volver a usar el servicio, deberás registrarte nuevamente desde cero.  

💬 Por favor escribe el número de la opción de tu respuesta:  
1️⃣ *Sí, deseo eliminar definitivamente mis datos personales.*  
2️⃣ *No, deseo conservar mi información y continuar vinculado(a) a la plataforma.*
""";
  }

  // 🔒 VERIFICACIÓN – Plantilla con número dinámico y aclaración de vínculo
  String _verificacionIdentidadMensaje(String numeroE164, {String? nombre}) {
    final saludo = (nombre != null && nombre.trim().isNotEmpty)
        ? "$nombre, haremos una verificación,\n\n"
        : "Haremos una verificación,\n\n";

    return """
${saludo}🟣 *Tu Proceso Ya* – Verificación de identidad  

Antes de continuar con tu solicitud de suspensión o eliminación de datos personales, queremos aclararte lo siguiente:  

📱 Tu cuenta está directamente vinculada al número de WhatsApp *$numeroE164*, con el cual fue creada tu cuenta en la plataforma *Tu Proceso Ya*.  
Por este motivo, entendemos que la persona que responde este mensaje es quien efectivamente abrió la cuenta o el acudiente autorizado.  

Esta verificación es necesaria para poder continuar con el proceso de borrado o suspensión de tus datos personales conforme a la *Ley 1581 de 2012* y el *Decreto 1377 de 2013*.

Para fines de verificación y registro, necesitamos que por favor nos confirmes a continuación tu *nombre completo*. 
""";
  }

  String _confirmacionBorradoMensaje({String? nombre, String? numeroE164}) {
    final saludo = (nombre != null && nombre.trim().isNotEmpty) ? "Perfecto $nombre,\n\n" : "Perfecto,\n\n";
    final lineaNumero = (numeroE164 != null && numeroE164.isNotEmpty)
        ? "Tu solicitud se registró desde el número *$numeroE164* vinculado a tu cuenta.\n\n"
        : "";

    return """
${saludo}Hemos recibido tu decisión de *ELIMINAR definitivamente* tus datos personales.

$lineaNumero📌 Conforme a la Ley 1581 de 2012, procederemos con el borrado total de tu información (historial, solicitudes, documentos y beneficios asociados) en un plazo *no mayor a 48 horas*.

⚠️ Esta acción es *irreversible*. Si deseas volver a usar la plataforma, deberás registrarte nuevamente desde cero.

Gracias por tu confirmación. 💜
""";
  }

  String _confirmacionSuspensionMensaje({String? nombre, String? numeroE164}) {
    final saludo = (nombre != null && nombre.trim().isNotEmpty) ? "Perfecto $nombre,\n\n" : "Perfecto,\n\n";
    final lineaNumero = (numeroE164 != null && numeroE164.isNotEmpty)
        ? "Tu solicitud se registró desde el número *$numeroE164* vinculado a tu cuenta.\n\n"
        : "";

    return """
${saludo}Hemos recibido tu decisión de *SUSPENDER* el tratamiento de tus datos personales.

$lineaNumero🛑 Desde este momento, tu información quedará en estado de *suspensión*: no será usada para nuevos procesos, salvo los estrictamente necesarios para cumplir deberes legales o contractuales ya vigentes.

✅ Podrás *reactivar* tu cuenta cuando desees, informándonos por este mismo medio.

Gracias por tu confirmación. 💜
""";
  }



  // 🔔 CONFIRMACIÓN – Muestra un alert antes de enviar mensajes delicados
  Future<void> _confirmarEnvioMensaje(String texto, String titulo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blancoCards,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Confirmar envío'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas enviar el mensaje de "$titulo"?\n\nEste mensaje tiene validez legal y será registrado en la conversación del usuario.',
          style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.send),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _enviarMensajeRapido(texto);
    }
  }


  String formatFechaSolo(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaComparada = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaComparada == hoy) {
      return 'Hoy';
    } else if (fechaComparada == hoy.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      return DateFormat('d \'de\' MMMM \'de\' y', 'es').format(fecha);
    }
  }

  /// ACA SE CONFIGURA LO QUE SE ESCRIBE DENTRO DEL MENSAJE
  Widget _buildMensaje(Map<String, dynamic> mensaje) {
    final contenido = mensaje['contenido'];
    final esImagen = mensaje['esImagen'] == true;
    final esArchivo = mensaje['esArchivo'] == true;
    final fileName = mensaje['fileName'] ?? 'Archivo';
    final createdAt = (mensaje['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    if (esImagen) {
      return Image.network(contenido, width: 200, height: 200, fit: BoxFit.cover);
    }

    if (esArchivo) {
      return FutureBuilder<http.Response>(
        future: http.get(Uri.parse(contenido)),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Text("Error al cargar el archivo");
          }

          final bytes = snapshot.data!.bodyBytes;
          return _buildDocumentCard(bytes, fileName, createdAt);
        },
      );
    }

    return Text(mensaje['text'] ?? '', style: const TextStyle(
      color: Colors.black,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.2
    ),);
  }


  Widget _buildQuickMessageCard(
      IconData icon,
      String titulo,
      String mensaje, {
        VoidCallback? onTap,
      }) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 600;
        final double cardWidth = isMobile ? 100 : 120;
        final double iconSize = isMobile ? 14 : 16;
        final double fontSize = isMobile ? 9 : 10;

        return GestureDetector(
          onTap: onTap ?? () => _enviarMensajeRapido(mensaje),
          child: SizedBox(
            width: cardWidth,
            child: Card(
              margin: EdgeInsets.zero, // 🚫 quita el margen externo
              surfaceTintColor: blanco,
              color: Colors.white,
              elevation: 0.5, // 🔹 casi plano
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 4 : 6,
                  vertical: isMobile ? 4 : 6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.deepPurple, size: iconSize),
                    const SizedBox(height: 2),
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
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
        child: Column(
          children: [
            // 🟣 Siempre visible, también en móviles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ValueListenableBuilder(
                valueListenable: _searchTerm,
                builder: (context, value, _) {
                  return TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,

                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o apellido',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: value.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchTerm.value = '';
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ===== Resultados de búsqueda en Ppl =====
            if (_cargandoPpl)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_cargandoPpl && _pplResults.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
                child: Row(
                  children: [
                    Icon(Icons.person_search, size: 18, color: Colors.deepPurple),
                    SizedBox(width: 6),
                    Text('Resultados en Ppl', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            if (!_cargandoPpl && _pplResults.isNotEmpty)
              SizedBox(
                height: 220, // scroll propio para no empujar todo
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _pplResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final d = _pplResults[i];
                    final data = d.data();
                    final acudiente = '${data['nombre_acudiente'] ?? ''} ${data['apellido_acudiente'] ?? ''}'.trim();
                    final ppl = '${data['nombre_ppl'] ?? ''} ${data['apellido_ppl'] ?? ''}'.trim();
                    final cel = (data['celularWhatsapp'] ?? '').toString();
                    final e164 = _toE164(cel);

                    return ListTile(
                      dense: true,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(acudiente.isEmpty ? '(Sin acudiente)' : acudiente,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          if (ppl.isNotEmpty) ppl,
                          if (cel.isNotEmpty) '📞 $cel'
                        ].join(' · '),
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          // Abrir chat
                          IconButton(
                            tooltip: 'Abrir chat',
                            icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                            onPressed: cel.isEmpty
                                ? null
                                : () async {
                              await _ensureConversationDoc(e164);
                              selectedNumeroCliente.value = e164;
                              // Si estás en pantalla pequeña, navega al detalle
                              if (esPantallaPequena(context)) {
                                // Reutiliza tu navegación actual
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(
                                      backgroundColor: Colors.green,
                                      iconTheme: const IconThemeData(color: Colors.white),
                                      title: const Text("Conversación", style: TextStyle(color: Colors.white)),
                                    ),
                                    body: _buildChatConversacion(e164, true),
                                  ),
                                ));
                              }
                            },
                          ),
                          // Enviar plantilla cambio_estado
                          IconButton(
                            tooltip: 'Enviar cambio de estado',
                            icon: const Icon(Icons.campaign, color: Colors.green),
                            onPressed: (cel.isEmpty)
                                ? null
                                : () => _enviarCambioEstado(e164, d.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (!_cargandoPpl && _pplResults.isNotEmpty)
              const Divider(height: 1),



            // 🔽 Lista desplazable
            Expanded(
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

                  return ValueListenableBuilder<String>(
                    valueListenable: _searchTerm,
                    builder: (context, filtro, _) {
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index];
                          final conversationId = data['conversationId'];
                          final lastMessage = data['lastMessage'] ?? '';
                          final createdAt = (data['lastMessageAt'] as Timestamp?)?.toDate();
                          final hasUnread = data['hasUnread'] == true;
                          final isSelected = conversationId == selectedNumeroCliente.value;

                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('Ppl')
                                .where(
                              'celularWhatsapp',
                              isEqualTo: conversationId.startsWith('57')
                                  ? conversationId.substring(2)
                                  : conversationId,
                            )
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

                                // Filtro
                                if (filtro.isNotEmpty &&
                                    !nombreAcudiente.toLowerCase().contains(filtro) &&
                                    !apellidoAcudiente.toLowerCase().contains(filtro)) {
                                  return const SizedBox.shrink();
                                }
                              } else if (filtro.isNotEmpty) {
                                return const SizedBox.shrink();
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
                                                "${createdAt.year} ${formatTimeAMPM(createdAt)}",
                                            style: const TextStyle(fontSize: 11, color: Colors.black87),
                                          ),
                                          if (hasUnread)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              width: 14,
                                              height: 14,
                                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                                subtitle: lastMessage == "(Imagen)"
                                    ? const Row(children: [Icon(Icons.photo, size: 16), SizedBox(width: 4), Text("Foto", style: TextStyle(fontSize: 12))])
                                    : lastMessage == "(Audio)"
                                    ? const Row(children: [Icon(Icons.mic, size: 16), SizedBox(width: 4), Text("Audio", style: TextStyle(fontSize: 12))])
                                    : lastMessage == "(Documento)"
                                    ? const Row(children: [Icon(Icons.insert_drive_file, size: 16), SizedBox(width: 4), Text("Documento", style: TextStyle(fontSize: 12))])
                                    : Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () async {
                                  selectedNumeroCliente.value = conversationId;
                                  if (esPequena) {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => Scaffold(
                                        appBar: AppBar(
                                          backgroundColor: Colors.green,
                                          iconTheme: const IconThemeData(color: Colors.white),
                                          title: const Text("Conversación", style: TextStyle(color: Colors.white)),
                                        ),
                                        body: _buildChatConversacion(conversationId, esPequena),
                                      ),
                                    ));
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
          ],
        ),
      ),
    );
  }



  void _enviarMensajeRapido(String texto) async {
    final numero = selectedNumeroCliente.value?.trim();
    if (numero == null || numero.isEmpty) return;

    final nombreAdmin = AdminProvider().adminName;

    await FirebaseFirestore.instance.collection('whatsapp_messages').add({
      'from': 'admin',
      'adminName': nombreAdmin,
      'conversationId': numero,
      'text': texto,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      final url = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendWhatsAppMessage");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'to': numero, 'text': texto}),
      );
      if (response.statusCode != 200) {
        debugPrint('Error enviando mensaje rápido: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error enviando mensaje rápido: $e');
    }

    _mensajeRespondido.value = null;
  }


  Widget _buildDocumentCard(Uint8List bytes, String fileName, DateTime createdAt) {
    return Card(
      elevation: 1.5,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
          minHeight: 80,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono PDF
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 10),

              // Nombre del archivo y detalles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "PDF • ${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTimeAMPM(createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Botón de descarga
              GestureDetector(
                onTap: () {
                  final blob = html.Blob([bytes], 'application/pdf');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  html.window.open(url, "_blank");
                },
                child: const Icon(Icons.download, size: 20, color: Colors.black87),
              ),
            ],
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

    final nombreAdmin = AdminProvider().adminName; // ✅ Aquí traes tu nombre

    await FirebaseFirestore.instance.collection('whatsapp_messages').add({
      'from': 'admin',
      'adminName': nombreAdmin, // ✅ Lo guardas
      'conversationId': numero,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      if (respuesta != null) 'replyTo': respuesta,
    });

    // Cloud Function
    try {
      final url = Uri.parse(
          "https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendWhatsAppMessage");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'to': numero, 'text': text}),
      );

      if (response.statusCode != 200) {
        debugPrint('Error enviando mensaje real: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error enviando mensaje real: $e');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.clear();
    });
    _mensajeRespondido.value = null;
  }


  Future<void> _enviarCambioEstado(String numero, String docId) async {
    // Normaliza a E.164 para CO
    String to = numero.trim();
    if (!to.startsWith('57')) to = '57$to';

    // Loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await http.post(
        Uri.parse('https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/sendCambioEstadoMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'to': to, 'docId': docId}),
      );

      if (context.mounted) Navigator.of(context).pop(); // cierra loader

      if (resp.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mensaje de cambio de estado enviado ✅')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error enviando mensaje: ${resp.statusCode} - ${resp.body}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop(); // cierra loader
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error enviando mensaje: $e')),
        );
      }
    }
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


  Future<void> adjuntarYEnviar({
    required String tipo, // 'image' o 'document'
    required String numeroDestino,
  }) async {
    // 1. Seleccionar archivo
    FilePickerResult? result;
    if (tipo == 'image') {
      result = await FilePicker.platform.pickFiles(type: FileType.image);
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
    }

    if (result == null || result.files.single.bytes == null) return;

    final bytes = result.files.single.bytes!;
    final fileName = result.files.single.name;
    final mimeType = _getMimeType(tipo);

    // 2. Subir a Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('whatsapp_files/$fileName');
    await storageRef.putData(bytes);
    final fileUrl = await storageRef.getDownloadURL();
    final nombreAdmin = AdminProvider().adminName;

    // 3. Llamar a la función Cloud que sube y envía por WhatsApp
    final uri = Uri.parse("https://us-central1-tu-proceso-ya-fe845.cloudfunctions.net/uploadAndSendWhatsAppMedia");

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "fileUrl": fileUrl,
        "mimeType": mimeType,
        "to": numeroDestino,
        "caption": fileName,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Archivo enviado correctamente por WhatsApp");
    } else {
      print("❌ Error al enviar archivo: ${response.body}");
    }

    // 4. Guardar en Firestore para mostrar en el chat
    await FirebaseFirestore.instance.collection('whatsapp_messages').add({
      'from': 'admin',
      'adminName': nombreAdmin, // 👈 Agregado
      'conversationId': numeroDestino,
      'createdAt': FieldValue.serverTimestamp(),
      'esImagen': tipo == 'image',
      'esArchivo': tipo == 'document',
      'fileName': fileName,
      'contenido': fileUrl,
    });

  }


  String _getMimeType(String tipo) {
    switch (tipo) {
      case 'image':
        return 'image/jpeg';
      case 'document':
        return 'application/pdf'; // podrías variarlo por extensión
      case 'audio':
        return 'audio/mpeg'; // o audio/mp3
      case 'video':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  //para barra de busqueda general

// ---- BUSQUEDA PPL ----
  Timer? _debouncePpl;
  bool _cargandoPpl = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _pplResults = [];

  String _toE164(String numero) {
    var n = numero.trim();
    if (n.startsWith('+')) n = n.substring(1);
    if (!n.startsWith('57')) n = '57$n';
    return n;
  }

// Normaliza: minúsculas + sin acentos
  String _normalize(String s) {
    final lower = s.toLowerCase();
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to   = 'aaaaaeeeeiiiiooooouuuunc';
    var out = StringBuffer();
    for (final ch in lower.characters) {
      final i = from.indexOf(ch);
      out.write(i >= 0 ? to[i] : ch);
    }
    return out.toString();
  }

// Ejecuta una consulta por prefijo en un campo lower
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _prefixQuery(
      CollectionReference<Map<String, dynamic>> col,
      String field,
      String q,
      {int limit = 25}
      ) async {
    try {
      final snap = await col
          .orderBy(field)
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(limit)
          .get();
      return snap.docs;
    } on FirebaseException catch (e) {
      // Si falta índice o el campo no existe, devolvemos vacío y luego haremos fallback
      debugPrint('prefixQuery($field) fallback -> $e');
      return [];
    }
  }

  Future<void> _buscarEnPpl(String term) async {
    term = term.trim();
    if (term.isEmpty) {
      setState(() {
        _pplResults = [];
        _cargandoPpl = false;
      });
      return;
    }

    setState(() => _cargandoPpl = true);

    final col = FirebaseFirestore.instance.collection('Ppl').withConverter<Map<String, dynamic>>(
      fromFirestore: (s, _) => s.data() ?? {},
      toFirestore: (m, _) => m,
    );

    try {
      final esNumero = RegExp(r'^\d+$').hasMatch(term);
      // ---- Búsqueda por número exacto en celularWhatsapp ----
      if (esNumero && term.length >= 7) {
        final snap = await col.where('celularWhatsapp', isEqualTo: term).limit(5).get();
        setState(() {
          _pplResults = snap.docs;
          _cargandoPpl = false;
        });
        return;
      }

      // ---- Texto: primero intentamos prefijos en campos *_lower ----
      final q = _normalize(term);
      final futures = <Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>[
        _prefixQuery(col, 'nombre_acudiente_lower', q),
        _prefixQuery(col, 'apellido_acudiente_lower', q),
        _prefixQuery(col, 'nombre_ppl_lower', q),
        _prefixQuery(col, 'apellido_ppl_lower', q),
      ];

      final results = await Future.wait(futures);
      // Unir y quitar duplicados por id
      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> merged = {};
      for (final list in results) {
        for (final d in list) {
          merged[d.id] = d;
        }
      }

      // Si conseguimos algo, listo
      if (merged.isNotEmpty) {
        setState(() {
          _pplResults = merged.values.toList();
          _cargandoPpl = false;
        });
        return;
      }

      // ---- Fallback: traer más docs y filtrar en cliente (normalizando acentos) ----
      // Sube este límite si tu dataset es grande, o pagina si hace falta.
      final snapAll = await col.limit(1000).get();
      final nq = _normalize(term);

      bool matchDoc(Map<String, dynamic> m) {
        final a = _normalize((m['nombre_acudiente'] ?? '').toString());
        final b = _normalize((m['apellido_acudiente'] ?? '').toString());
        final c = _normalize((m['nombre_ppl'] ?? '').toString());
        final e = _normalize((m['apellido_ppl'] ?? '').toString());
        final joined = '$a $b $c $e';
        // Permite buscar por varias palabras en cualquier orden
        final tokens = nq.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
        for (final t in tokens) {
          if (!joined.contains(t)) return false;
        }
        return true;
      }

      final filtered = snapAll.docs.where((d) => matchDoc(d.data())).take(100).toList();

      setState(() {
        _pplResults = filtered;
        _cargandoPpl = false;
      });
    } catch (e) {
      setState(() {
        _pplResults = [];
        _cargandoPpl = false;
      });
      debugPrint('Error buscando en Ppl: $e');
    }
  }

// Debounce al escribir en el buscador
  void _onSearchChanged(String v) {
    _searchTerm.value = v.trim().toLowerCase();
    _debouncePpl?.cancel();
    _debouncePpl = Timer(const Duration(milliseconds: 350), () {
      _buscarEnPpl(v);
    });
  }

// Asegura que exista el doc de conversación para mostrar en la lista
  Future<void> _ensureConversationDoc(String e164) async {
    final ref = FirebaseFirestore.instance.collection('whatsapp_conversations').doc(e164);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'conversationId': e164,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'hasUnread': false,
      }, SetOptions(merge: true));
    }
  }

}
