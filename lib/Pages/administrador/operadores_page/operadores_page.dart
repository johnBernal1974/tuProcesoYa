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
  final int _pageSize = 1;
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
                      itemCount: _documents.length,
                      itemBuilder: (context, index) {
                        var doc = filteredDocs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        String docId = doc.id;

                        _editMode.putIfAbsent(docId, () => false);
                        _selectedEstado.putIfAbsent(docId, () => data['status']);
                        _selectedRol.putIfAbsent(docId, () => data['rol']);

                        return Card(
                          color: blancoCards,
                          surfaceTintColor: blancoCards,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    bool isMobile = constraints.maxWidth < 600;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        isMobile
                                            ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${data['name']} ${data['apellidos']}",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              "Fecha de Registro: ${_formatFecha(data['fecha_registro'])}",
                                              style: const TextStyle(fontSize: 12, color: gris),
                                            ),
                                          ],
                                        )
                                            : Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "${data['name']} ${data['apellidos']}",
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text(
                                              "Fecha de Registro: ${_formatFecha(data['fecha_registro'])}",
                                              style: const TextStyle(fontSize: 12, color: gris),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        isMobile
                                            ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInfoRow("Celular", data['celular']),
                                            _buildInfoRow("Email", data['email']),
                                          ],
                                        )
                                            : Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildInfoRow("Celular", data['celular']),
                                            _buildInfoRow("Email", data['email']),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                if (!_editMode[docId]!) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoRow("Estado", data['status']),
                                      _buildInfoRow("Rol", data['rol']),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _editMode[docId] = true;
                                      });
                                    },
                                    child: const Text("Editar"),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: blanco,
                                    value: _selectedEstado[docId],
                                    items: ["registrado", "activado", "suspendido", "cancelado"]
                                        .map((estado) => DropdownMenuItem(value: estado, child: Text(estado)))
                                        .toList(),
                                    onChanged: (valor) {
                                      setState(() {
                                        _selectedEstado[docId] = valor!;
                                      });
                                    },
                                    decoration: const InputDecoration(labelText: "Estado"),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: blanco,
                                    value: _selectedRol[docId],
                                    items: [
                                      "operador 1", "operador 2", "pasante 1", "pasante 2",
                                      "pasante 3", "coordinador 1", "coordinador 2", "master", "masterFull", ""
                                    ]
                                        .map((rol) => DropdownMenuItem(value: rol, child: Text(rol)))
                                        .toList(),
                                    onChanged: (valor) {
                                      setState(() {
                                        _selectedRol[docId] = valor!;
                                      });
                                    },
                                    decoration: const InputDecoration(labelText: "Rol"),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _updateOperador(docId),
                                        child: const Text("Actualizar"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _editMode[docId] = false;
                                          });
                                        },
                                        child: const Text("Cancelar"),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
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


  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontSize: 12, color: gris)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}





