import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListaPplPaginada extends StatefulWidget {
  const ListaPplPaginada({super.key});

  @override
  State<ListaPplPaginada> createState() => _ListaPplPaginadaState();
}

class _ListaPplPaginadaState extends State<ListaPplPaginada> {
  final int _pageSize = 50;
  List<DocumentSnapshot> _registros = [];
  DocumentSnapshot? _lastDocument;
  DocumentSnapshot? _firstDocument;
  bool _hasNext = true;
  bool _isLoading = false;

  Future<void> _cargarPagina({bool siguiente = true}) async {
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('Ppl')
        .orderBy('fechaRegistro', descending: true)
        .limit(_pageSize);

    if (siguiente && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    } else if (!siguiente && _firstDocument != null) {
      query = query.endBeforeDocument(_firstDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _registros = snapshot.docs;
        _firstDocument = snapshot.docs.first;
        _lastDocument = snapshot.docs.last;
        _hasNext = snapshot.docs.length == _pageSize;
      });
    } else {
      setState(() {
        _hasNext = false;
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _cargarPagina(); // carga inicial
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Status')),
                  // ➕ Agrega más columnas aquí
                ],
                rows: _registros.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return DataRow(
                    cells: [
                      DataCell(Text('${data['nombre_ppl']} ${data['apellido_ppl']}')),
                      DataCell(Text(data['status'] ?? '')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _firstDocument != null ? () => _cargarPagina(siguiente: false) : null,
              child: const Text("Anterior"),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: _hasNext ? () => _cargarPagina(siguiente: true) : null,
              child: const Text("Siguiente"),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
