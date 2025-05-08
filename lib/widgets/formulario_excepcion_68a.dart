import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FormularioExcepcion68A extends StatefulWidget {
  final void Function(List<PlatformFile>) onArchivosSeleccionados;

  const FormularioExcepcion68A({super.key, required this.onArchivosSeleccionados});

  @override
  State<FormularioExcepcion68A> createState() => _FormularioExcepcion68AState();
}

class _FormularioExcepcion68AState extends State<FormularioExcepcion68A> {
  String? excepcionSeleccionada;
  final TextEditingController comentariosController = TextEditingController();
  List<PlatformFile> archivosAdjuntos = [];

  final List<String> opcionesExcepcion = [
    'Mujer embarazada',
    'Madre lactante',
    'Persona con enfermedad grave o terminal',
    'Mayor de 60 años',
    'Único cuidador de personas dependientes',
    'Discapacidad severa',
    "Excepciones reconocidas (tutela, jurisprudencia, etc.)"
  ];

  Future<void> _seleccionarArchivos() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        archivosAdjuntos.addAll(result.files);
      });
      widget.onArchivosSeleccionados(archivosAdjuntos);
    }
  }

  void _eliminarArchivo(PlatformFile file) {
    setState(() {
      archivosAdjuntos.remove(file);
      widget.onArchivosSeleccionados(archivosAdjuntos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          value: excepcionSeleccionada,
          items: opcionesExcepcion.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(e),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              excepcionSeleccionada = value;
            });
          },
          decoration: const InputDecoration(
            labelText: "Seleccionar la condición",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text("Describe detalladamente la situación que justifica tu solicitud, indicando por qué consideras que cumples con una de las excepciones al artículo 68A."),
        const SizedBox(height: 20),
        TextFormField(
          controller: comentariosController,
          minLines: 3,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: "Descripción",
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _seleccionarArchivos,
          child: Row(
            children: [
              Icon(
                archivosAdjuntos.isNotEmpty ? Icons.check_circle : Icons.upload_file,
                color: archivosAdjuntos.isNotEmpty ? Colors.green : Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  archivosAdjuntos.isNotEmpty ? 'Archivos seleccionados' : 'Subir archivos soporte',
                  style: TextStyle(
                    color: archivosAdjuntos.isNotEmpty ? Colors.black : Colors.deepPurple,
                    decoration: archivosAdjuntos.isNotEmpty
                        ? TextDecoration.none
                        : TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (archivosAdjuntos.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: archivosAdjuntos.map((file) {
              return Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      file.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    tooltip: "Eliminar archivo",
                    onPressed: () => _eliminarArchivo(file),
                  ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}
