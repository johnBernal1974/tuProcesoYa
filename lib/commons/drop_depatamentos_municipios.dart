import 'package:flutter/material.dart';

class DepartamentosMunicipiosWidget extends StatefulWidget {
  final String? departamentoSeleccionado;
  final String? municipioSeleccionado;
  final Function(String, String) onSelectionChanged;

  const DepartamentosMunicipiosWidget({
    Key? key,
    required this.departamentoSeleccionado,
    required this.municipioSeleccionado,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  _DepartamentosMunicipiosWidgetState createState() => _DepartamentosMunicipiosWidgetState();
}

class _DepartamentosMunicipiosWidgetState extends State<DepartamentosMunicipiosWidget> {
  final Map<String, List<String>> departamentosYMunicipios = {
    'Amazonas': ['Leticia', 'Puerto Nariño'],
    'Antioquia': ['Medellín', 'Envigado', 'Bello'],
    'Cundinamarca': ['Bogotá', 'Soacha', 'Zipaquirá'],
    'Valle del Cauca': ['Cali', 'Palmira', 'Buenaventura'],
  };

  String? departamentoSeleccionado;
  String? municipioSeleccionado;
  List<String> municipiosDisponibles = [];

  @override
  void initState() {
    super.initState();
    departamentoSeleccionado = widget.departamentoSeleccionado;
    municipioSeleccionado = widget.municipioSeleccionado;

    // ✅ Asegurar que el departamento seleccionado exista en la lista
    if (departamentoSeleccionado != null &&
        !departamentosYMunicipios.keys.contains(departamentoSeleccionado)) {
      departamentoSeleccionado = null; // 🔥 Resetear si no existe
    }

    if (departamentoSeleccionado != null) {
      municipiosDisponibles = departamentosYMunicipios[departamentoSeleccionado!] ?? [];
    }

    // ✅ Asegurar que el municipio seleccionado exista en la lista
    if (municipioSeleccionado != null && !municipiosDisponibles.contains(municipioSeleccionado)) {
      municipioSeleccionado = null; // 🔥 Resetear si no existe
    }
  }

  void _actualizarMunicipios(String departamento) {
    setState(() {
      departamentoSeleccionado = departamento;
      municipiosDisponibles = departamentosYMunicipios[departamento] ?? [];
      municipioSeleccionado = null;
    });

    widget.onSelectionChanged(departamento, "");
  }

  void _actualizarMunicipio(String municipio) {
    setState(() {
      municipioSeleccionado = municipio;
    });

    widget.onSelectionChanged(departamentoSeleccionado!, municipio);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDropdownContainer(
          title: "Departamento",
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: departamentoSeleccionado, // ✅ Ahora está validado
            hint: const Text("Seleccione un departamento"),
            decoration: _inputDecoration(),
            items: departamentosYMunicipios.keys.map((String departamento) {
              return DropdownMenuItem<String>(
                value: departamento,
                child: Text(departamento),
              );
            }).toList(),
            onChanged: (String? nuevoDepartamento) {
              if (nuevoDepartamento != null) {
                _actualizarMunicipios(nuevoDepartamento);
              }
            },
          ),
        ),

        const SizedBox(height: 20),

        _buildDropdownContainer(
          title: "Municipio",
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: municipioSeleccionado, // ✅ Ahora está validado
            hint: const Text("Seleccione un municipio"),
            decoration: _inputDecoration(),
            items: municipiosDisponibles.map((String municipio) {
              return DropdownMenuItem<String>(
                value: municipio,
                child: Text(municipio),
              );
            }).toList(),
            onChanged: (String? nuevoMunicipio) {
              if (nuevoMunicipio != null) {
                _actualizarMunicipio(nuevoMunicipio);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: child,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}
