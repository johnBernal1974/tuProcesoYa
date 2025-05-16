import 'package:flutter/material.dart';

class CentroReclusionSelector extends StatelessWidget {
  final List<Map<String, String>> centros;
  final Function(Map<String, String>) onSelected;
  final String? centroSeleccionadoNombre;
  final bool error;

  const CentroReclusionSelector({
    super.key,
    required this.centros,
    required this.onSelected,
    this.centroSeleccionadoNombre,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Map<String, String>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable.empty();
        return centros.where((option) =>
            option['nombre']!.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      displayStringForOption: (option) => option['nombre']!,
      onSelected: onSelected,
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        if (centroSeleccionadoNombre != null && centroSeleccionadoNombre!.isNotEmpty) {
          textEditingController.text = centroSeleccionadoNombre!;
        }

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          maxLines: null,
          minLines: 1,
          expands: false,
          decoration: InputDecoration(
            labelText: "Centro de reclusión",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelStyle: const TextStyle(color: Colors.black),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            // BORDES
            border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2)),
            focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2)),
            errorText: error ? 'Campo obligatorio' : null,
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Material(
          elevation: 4,
          child: Container(
            color: Colors.amber[50],
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  title: Text(option['nombre']!),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
