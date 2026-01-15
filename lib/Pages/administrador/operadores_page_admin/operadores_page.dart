import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class OperadoresPage extends StatefulWidget {
  const OperadoresPage({super.key});

  @override
  _OperadoresPageState createState() => _OperadoresPageState();
}

class _OperadoresPageState extends State<OperadoresPage> {
  final Map<String, bool> _editMode = {}; // Controla qué tarjetas están en modo edición
  final Map<String, String> _selectedEstado = {};
  final Map<String, String> _selectedRol = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchText = ""; // Variable para almacenar el texto de búsqueda

  // 🔹 Variables para paginación
  List<DocumentSnapshot> _documents = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 5;
  bool _isLoadingMore = false;


  @override
  void initState() {
    super.initState();
    _fetchOperadores();
  }


  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width >= 1000 ? 800 : double.infinity;
    return MainLayout(
      pageTitle: "Operadores Registrados",
      content: Column(
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gris, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              width: cardWidth,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: "Buscar operador",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('admin').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay operadores registrados"));
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String fullName = "${data['name']} ${data['apellidos']}".toLowerCase();
                  return fullName.contains(_searchController.text.toLowerCase());
                }).toList();

                return Center(
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(10),
                    child: ListView.builder(
                      key: const PageStorageKey<String>('operadores_list'),
                      itemCount: filteredDocs.isNotEmpty ? filteredDocs.length : 0,
                      itemBuilder: (context, index) {
                        //if (index >= filteredDocs.length) return const SizedBox();
                        var doc = filteredDocs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        String docId = doc.id;

                        _editMode.putIfAbsent(docId, () => false);
                        _selectedEstado.putIfAbsent(docId, () => data['status']);
                        _selectedRol.putIfAbsent(docId, () => data['rol']);

                        return OperadorCard(
                          doc: doc,
                          onUpdate: (docId, status, rol) async {
                            await FirebaseFirestore.instance.collection('admin').doc(docId).update({
                              'status': status,
                              'rol': rol,
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Operador actualizado con éxito")),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary
                ),
                onPressed: _hasMore
                    ? () async {
                  setState(() => _isLoadingMore = true);
                  await _fetchOperadores(loadMore: true);
                  setState(() => _isLoadingMore = false);
                }
                    : null,
                child: _isLoadingMore
                    ? const CircularProgressIndicator()
                    : const Text("Cargar más", style: TextStyle(color: blanco),),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _fetchOperadores({bool loadMore = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('admin')
        .orderBy('fecha_registro', descending: true)
        .limit(_pageSize);

    if (loadMore && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    print('Cantidad de documentos cargados: ${querySnapshot.docs.length}');

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _lastDocument = querySnapshot.docs.last;
        _documents.addAll(querySnapshot.docs);
        _hasMore = querySnapshot.docs.length == _pageSize;
      });
    } else {
      setState(() => _hasMore = false);
    }

    setState(() => _isLoading = false);
  }

  String _formatFecha(Timestamp? timestamp, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (timestamp == null) return "";
    DateTime fecha = timestamp.toDate();
    return DateFormat(formato, 'es').format(fecha);
  }

  Future<void> _updateOperador(String id) async {
    await FirebaseFirestore.instance.collection('admin').doc(id).update({
      'status': _selectedEstado[id],
      'rol': _selectedRol[id],
    });

    setState(() {
      _editMode[id] = false; // Cierra la edición al guardar
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Operador actualizado con éxito")),
    );
  }
  InputDecoration _inputGrey(String label) {
    final grey = Colors.grey.shade400;
    final greyFocused = Colors.grey.shade600;

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: greyFocused, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: grey, width: 1),
      ),

      // aunque haya error, igual gris (si quieres rojo en error, me dices)
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: grey, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: greyFocused, width: 1.5),
      ),
    );
  }



  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontSize: 12, color: gris)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class OperadorCard extends StatefulWidget {
  final DocumentSnapshot doc;
  final Future<void> Function(String docId, String status, String rol) onUpdate;

  const OperadorCard({
    super.key,
    required this.doc,
    required this.onUpdate,
  });

  @override
  State<OperadorCard> createState() => _OperadorCardState();
}

class _OperadorCardState extends State<OperadorCard> {
  bool _edit = false;
  late String _estado;
  late String _rol;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _estado = (data['status'] ?? '').toString();
    _rol = (data['rol'] ?? '').toString();
  }

  InputDecoration _inputGrey(String label) {
    final grey = Colors.grey.shade400;
    final greyFocused = Colors.grey.shade600;
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: greyFocused, width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: grey, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final docId = widget.doc.id;

    return Card(
      color: blancoCards,
      surfaceTintColor: blancoCards,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${data['name']} ${data['apellidos']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoRow("Celular", (data['celular'] ?? '').toString()),
                _buildInfoRow("Email", (data['email'] ?? '').toString()),
              ],
            ),
            const SizedBox(height: 10),

            if (!_edit) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoRow("Estado", (data['status'] ?? '').toString()),
                  _buildInfoRow("Rol", (data['rol'] ?? '').toString()),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => setState(() => _edit = true),
                child: const Text("Editar"),
              ),
            ] else ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: blanco,
                value: _estado,
                items: ["registrado", "activado", "suspendido", "cancelado"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _estado = v ?? _estado),
                decoration: _inputGrey("Estado"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: blanco,
                value: _rol,
                items: [
                  "operador 1","operador 2","pasante 1","pasante 2","filtrado",
                  "pasante 3","coordinador 1","coordinador 2","master","masterFull",""
                ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _rol = v ?? _rol),
                decoration: _inputGrey("Rol"),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await widget.onUpdate(docId, _estado, _rol);
                      if (mounted) setState(() => _edit = false);
                    },
                    child: const Text("Actualizar"),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _edit = false),
                    child: const Text("Cancelar"),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontSize: 12, color: gris)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}






