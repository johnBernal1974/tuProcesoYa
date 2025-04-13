import 'package:flutter/material.dart';

import '../../../commons/drop_depatamentos_municipios.dart';
import '../../../src/colors/colors.dart';

class SolicitudDomiciliariaPage extends StatefulWidget {
  const SolicitudDomiciliariaPage({super.key});

  @override
  State<SolicitudDomiciliariaPage> createState() => _SolicitudDomiciliariaPageState();
}

class _SolicitudDomiciliariaPageState extends State<SolicitudDomiciliariaPage> {
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nombreResponsableController = TextEditingController();
  final TextEditingController _cedulaResponsableController = TextEditingController();
  final TextEditingController _celularResponsableController = TextEditingController();

  String? archivoRecibo;
  String? archivoDeclaracion;
  String? departamentoSeleccionado;
  String? municipioSeleccionado;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
          title: const Text('Nueva Solicitud', style: TextStyle(color: blanco)),
      backgroundColor: primary),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              children: [
                const Text(
                  'Solicitud de Prisión Domiciliaria',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'La prisión domiciliaria es un beneficio que permite al PPL cumplir su condena en un lugar de residencia previamente aprobado, cuando se cumplen ciertos requisitos legales y humanitarios.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Es necesario suministrar información veraz y completa, así como subir los documentos requeridos para la evaluación de la solicitud.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text('1. Dirección exacta del domicilio donde estará el PPL:', style: TextStyle(
                  fontWeight: FontWeight.bold
                ),),
                const SizedBox(height: 8),
                TextField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección completa',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // ✅ Widget de selección de Departamento y Municipio
                DepartamentosMunicipiosWidget(
                  departamentoSeleccionado: departamentoSeleccionado,
                  municipioSeleccionado: municipioSeleccionado,
                  onSelectionChanged: (String departamento, String municipio) {
                    setState(() {
                      departamentoSeleccionado = departamento;
                      municipioSeleccionado = municipio;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text(
                  '2. Sube un recibo de servicios públicos del domicilio ingresado:', style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.upload_file, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(archivoRecibo ?? 'Subir archivo'),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text(
                  '3. Sube la declaración extra juicio para la solicitud de prisión domiciliaria:', style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.upload_file, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Text(archivoDeclaracion ?? 'Subir archivo'),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text('4. Datos de la persona responsable del PPL en el domicilio:' , style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 10),
                TextField(
                  controller: _nombreResponsableController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo del responsable',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                TextField(
                  controller: _cedulaResponsableController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número de Cédula',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                TextField(
                  controller: _celularResponsableController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de Celular',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary
                  ),
                  onPressed: () {
                    // Validación y envío aquí
                  },
                  child: const Text('Enviar solicitud', style: TextStyle(
                    color: blanco
                  )),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
