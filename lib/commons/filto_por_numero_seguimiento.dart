import 'package:flutter/material.dart';

class FiltroDerechosPeticion extends StatefulWidget {
  final Function(String) onSearch;

  const FiltroDerechosPeticion({Key? key, required this.onSearch}) : super(key: key);

  @override
  _FiltroDerechosPeticionState createState() => _FiltroDerechosPeticionState();
}

class _FiltroDerechosPeticionState extends State<FiltroDerechosPeticion> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          // 🔹 Campo de búsqueda
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Buscar por número de seguimiento",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch(""); // 🔹 Limpia el filtro
                  },
                )
                    : null,
              ),
            ),
          ),

          const SizedBox(width: 10), // 🔹 Espaciado entre el campo y el botón

          // 🔹 Botón de búsqueda
          ElevatedButton(
            onPressed: () {
              widget.onSearch(_controller.text.trim()); // 🔥 Ejecutar búsqueda manualmente
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              backgroundColor: Colors.blue,
            ),
            child: const Text("Buscar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
