import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuscarPplPorCentroWidget extends StatefulWidget {
  const BuscarPplPorCentroWidget({super.key});

  @override
  State<BuscarPplPorCentroWidget> createState() =>
      _BuscarPplPorCentroWidgetState();
}

class _BuscarPplPorCentroWidgetState extends State<BuscarPplPorCentroWidget> {
  final TextEditingController _busquedaController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _buscarPpl() async {
    final termino = _busquedaController.text.trim().toLowerCase();

    if (termino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un término')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Cargar colección completa (solo si no es gigantesca)
      final querySnapshot = await _firestore.collection('Ppl').get();

      final resultados = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final centro = (data['centro_reclusion'] ?? '').toString().toLowerCase();
        return centro.contains(termino);
      }).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Resultados (${resultados.length})'),
            content: SizedBox(
              width: double.maxFinite,
              child: resultados.isEmpty
                  ? const Text('No se encontraron resultados.')
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: resultados.length,
                itemBuilder: (context, index) {
                  final data = resultados[index].data();

                  final nombre = data['nombre_ppl'] ?? '';
                  final apellido = data['apellido_ppl'] ?? '';
                  final centro = data['centro_reclusion'] ?? 'Sin dato';

                  return ListTile(
                    title: Text('$nombre $apellido'),
                    subtitle: Text('Centro: $centro'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Buscar PPL por centro de reclusión',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _busquedaController,
                decoration: const InputDecoration(
                  labelText: 'Escribe la ciudad o parte del nombre',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _buscarPpl,
              child: _isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Buscar'),
            ),
          ],
        ),
      ],
    );
  }
}
