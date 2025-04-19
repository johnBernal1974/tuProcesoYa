
import 'dart:math';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../commons/archivo _uplouder.dart';
import '../../../commons/base_textfield.dart';
import '../../../commons/drop_depatamentos_municipios.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_domiciliaria/solicitud_exitosa_domiciliaria.dart';

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
  String? archivoInsolvencia;
  String? urlArchivoRecibo;
  String? urlArchivoDeclaracion;
  String? urlArchivoInsolvencia;
  String? departamentoSeleccionado;
  String? municipioSeleccionado;
  String? parentescoSeleccionado;

  List<PlatformFile> _selectedFiles = [];
  List<String> archivosUrls = [];

  String? archivoCedulaResponsable;
  String? urlArchivoCedulaResponsable;

  List<PlatformFile> archivosHijos = [];
  List<String> urlsArchivosHijos = [];
  String? docIdSolicitud;

  //nuevos campos para los hijos
  List<Map<String, String>> hijos = [];
  final TextEditingController _nombreHijoController = TextEditingController();
  final TextEditingController _edadHijoController = TextEditingController();

  bool tieneHijosConvivientes = false;



  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
          title: const Text('Nueva Solicitud', style: TextStyle(color: blanco)),
          iconTheme: const IconThemeData(color: Colors.white, size: 30),
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
                  '2. Sube un recibo de servicios públicos de dicho domicilio:', style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('recibo'),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoRecibo ?? 'Subir archivo',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      if (archivoRecibo != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => eliminarArchivo('recibo'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text(
                  '3. Sube la declaración extra juicio para la solicitud de prisión domiciliaria:', style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('declaracion'),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoDeclaracion ?? 'Subir archivo',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      if (archivoDeclaracion != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => eliminarArchivo('declaracion'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text(
                    '4. Sube la certificación de insolvencia económica en un solo documento:', style: TextStyle(
                    fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('insolvencia'),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoInsolvencia ?? 'Subir archivo',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      if (archivoInsolvencia != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => eliminarArchivo('insolvencia'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text('5. Datos de la persona responsable del PPL en el domicilio:' , style: TextStyle(
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
                const SizedBox(height: 24),
                const Text(
                  "6. Por favor selecciona qué relación tiene la persona responsable con el PPL (persona privada de la libertad)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Ejemplo: la persona responsable es la Madre, el Esposo, la Hermana, el Amigo, etc.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: blanco,
                  decoration: const InputDecoration(
                    labelText: 'Parentesco del responsable con el PPL',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                  value: parentescoSeleccionado,
                  items: const [
                    // 👨‍👩‍👧‍👦 Familia directa
                    DropdownMenuItem(value: 'Madre', child: Text('Madre')),
                    DropdownMenuItem(value: 'Padre', child: Text('Padre')),
                    DropdownMenuItem(value: 'Hija', child: Text('Hija')),
                    DropdownMenuItem(value: 'Hijo', child: Text('Hijo')),
                    DropdownMenuItem(value: 'Esposa', child: Text('Esposa')),
                    DropdownMenuItem(value: 'Esposo', child: Text('Esposo')),

                    // 👵👴 Abuelos
                    DropdownMenuItem(value: 'Abuela', child: Text('Abuela')),
                    DropdownMenuItem(value: 'Abuelo', child: Text('Abuelo')),

                    // 👧👦 Nietos
                    DropdownMenuItem(value: 'Nieta', child: Text('Nieta')),
                    DropdownMenuItem(value: 'Nieto', child: Text('Nieto')),

                    // 🧍‍♂️🧍‍♀️ Hermanos
                    DropdownMenuItem(value: 'Hermana', child: Text('Hermana')),
                    DropdownMenuItem(value: 'Hermano', child: Text('Hermano')),

                    // 👨‍👧‍👦 Tíos y primos
                    DropdownMenuItem(value: 'Tía', child: Text('Tía')),
                    DropdownMenuItem(value: 'Tío', child: Text('Tío')),
                    DropdownMenuItem(value: 'Prima', child: Text('Prima')),
                    DropdownMenuItem(value: 'Primo', child: Text('Primo')),

                    // 👨‍❤️‍👨 Pareja no conyugal
                    DropdownMenuItem(value: 'Compañera', child: Text('Compañera')),
                    DropdownMenuItem(value: 'Compañero', child: Text('Compañero')),

                    // 👨‍👧‍👦 Familia política
                    DropdownMenuItem(value: 'Cuñada', child: Text('Cuñada')),
                    DropdownMenuItem(value: 'Cuñado', child: Text('Cuñado')),
                    DropdownMenuItem(value: 'Suegra', child: Text('Suegra')),
                    DropdownMenuItem(value: 'Suegro', child: Text('Suegro')),
                    DropdownMenuItem(value: 'Nuera', child: Text('Nuera')),
                    DropdownMenuItem(value: 'Yerno', child: Text('Yerno')),

                    // 👧👦 Sobrinos
                    DropdownMenuItem(value: 'Sobrina', child: Text('Sobrina')),
                    DropdownMenuItem(value: 'Sobrino', child: Text('Sobrino')),

                    // 👥 Amistades
                    DropdownMenuItem(value: 'Amiga', child: Text('Amiga')),
                    DropdownMenuItem(value: 'Amigo', child: Text('Amigo')),

                    // ❓ Otro
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],

                  onChanged: (value) {
                    setState(() {
                      parentescoSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                const Text(
                  '7. Sube la fotocopia de la cédula de la persona responsable:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('cedula_responsable'),
                  child: Row(
                    children: [
                      const Icon(Icons.upload_file, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoCedulaResponsable ?? 'Subir archivo',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      if (archivoCedulaResponsable != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => eliminarArchivo('cedula_responsable'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: tieneHijosConvivientes,
                  onChanged: (value) {
                    setState(() {
                      tieneHijosConvivientes = value ?? false;
                    });
                  },
                  title: const Text(
                    '¿Vivirá con sus hijos mientras cumple el beneficio de prisión domiciliaria? Solo aplica para hijos menores de 18 años.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                if (tieneHijosConvivientes) ...[
                  const SizedBox(height: 24),
                  const Divider(color: negroLetras, height: 1),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      formularioHijos(),
                      const SizedBox(height: 24),
                      const Divider(color: negroLetras, height: 1),
                      const SizedBox(height: 24),
                      const Text(
                        '9. Adjuntar los documentos de identidad de los hijos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: pickMultipleFilesHijos,
                        child: const Row(
                          children: [
                            Icon(Icons.upload_file, color: Colors.deepPurple),
                            SizedBox(width: 8),
                            Text(
                              'Subir archivos de los hijos',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (archivosHijos.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: archivosHijos.map((file) {
                            return Row(
                              children: [
                                const Icon(Icons.upload_file, color: Colors.deepPurple, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                  tooltip: "Eliminar archivo",
                                  onPressed: () => eliminarArchivoHijo(file),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(color: negroLetras, height: 1),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary
                  ),
                  onPressed: validarYEnviar,
                  child: const Text('Enviar solicitud', style: TextStyle(
                    color: blanco
                  )),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void eliminarArchivoHijo(PlatformFile file) {
    setState(() {
      int index = archivosHijos.indexWhere((f) => f.name == file.name);
      if (index != -1) {
        archivosHijos.removeAt(index);
        if (index < urlsArchivosHijos.length) {
          urlsArchivosHijos.removeAt(index);
        }
      }
    });
  }

  void eliminarArchivo(String tipo) {
    setState(() {
      if (tipo == 'recibo') {
        archivoRecibo = null;
        urlArchivoRecibo = null;
      } else if (tipo == 'declaracion') {
        archivoDeclaracion = null;
        urlArchivoDeclaracion = null;
      } else if (tipo == 'cedula_responsable') {
        archivoCedulaResponsable = null;
        urlArchivoCedulaResponsable = null;
      }
      else if (tipo == 'insolvencia') {
        archivoInsolvencia = null;
        urlArchivoInsolvencia = null;
      }
    });
  }

  Future<void> pickSingleFile(String tipo) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Mostrar el nombre inmediatamente
        setState(() {
          if (tipo == 'recibo') {
            archivoRecibo = file.name;
          } else if (tipo == 'declaracion') {
            archivoDeclaracion = file.name;
          } else if (tipo == 'cedula_responsable') {
            archivoCedulaResponsable = file.name;
          }
          else if (tipo == 'insolvencia') {
            archivoInsolvencia = file.name;
          }
        });

        docIdSolicitud ??= FirebaseFirestore.instance.collection('prision_domiciliaria_solicitados').doc().id;
        String path = 'solicitudes_prision_domiciliaria/$docIdSolicitud/${file.name}';

        String? downloadUrl = await ArchivoUploader.subirArchivo(
          file: file,
          rutaDestino: path,
        );

        if (downloadUrl != null) {
          setState(() {
            if (tipo == 'recibo') {
              urlArchivoRecibo = downloadUrl;
            } else if (tipo == 'declaracion') {
              urlArchivoDeclaracion = downloadUrl;
            } else if (tipo == 'cedula_responsable') {
              urlArchivoCedulaResponsable = downloadUrl;
            } else if (tipo == 'insolvencia') {
              urlArchivoInsolvencia = downloadUrl;
            }
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Archivo subido exitosamente."),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No se pudo subir el archivo, intenta nuevamente."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al seleccionar archivo: $e");
      }
    }
  }

  Future<void> pickMultipleFilesHijos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null && result.files.isNotEmpty) {
        docIdSolicitud ??= FirebaseFirestore.instance.collection('prision_domiciliaria_solicitados').doc().id;

        for (PlatformFile file in result.files) {
          if (!archivosHijos.any((f) => f.name == file.name)) {
            archivosHijos.add(file);

            String path = 'solicitudes_prision_domiciliaria/$docIdSolicitud/hijos/${file.name}';

            String? downloadUrl = await ArchivoUploader.subirArchivo(
              file: file,
              rutaDestino: path,
            );

            if (downloadUrl != null) {
              urlsArchivosHijos.add(downloadUrl);
            }
          }
        }

        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error al seleccionar archivos de hijos: $e");
      }
    }
  }

  void validarYEnviar() async {
    if (_direccionController.text.trim().isEmpty ||
        departamentoSeleccionado == null ||
        municipioSeleccionado == null ||
        archivoRecibo == null ||
        archivoDeclaracion == null ||
        archivoCedulaResponsable == null ||
        archivoInsolvencia == null ||
        _nombreResponsableController.text.trim().isEmpty ||
        _cedulaResponsableController.text.trim().isEmpty ||
        _celularResponsableController.text.trim().isEmpty ||
        parentescoSeleccionado == null || parentescoSeleccionado!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos y sube los documentos requeridos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Validar número de celular
    final celular = _celularResponsableController.text.trim();
    if (celular.length != 10 || !RegExp(r'^\d+$').hasMatch(celular)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El número de celular debe tener exactamente 10 dígitos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Validar número de cédula
    final cedula = _cedulaResponsableController.text.trim();
    if (cedula.length < 7 || cedula.length > 10 || !RegExp(r'^\d+$').hasMatch(cedula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La cédula debe tener entre 7 y 10 dígitos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 🔹 Validar hijos si aplica
    if (tieneHijosConvivientes) {
      if (hijos.isEmpty || archivosHijos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor, agrega los datos de los hijos y sube sus documentos."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      for (var hijo in hijos) {
        final nombre = hijo['nombre']?.trim() ?? '';
        final edadStr = hijo['edad'] ?? '0';
        final edad = int.tryParse(edadStr) ?? 0;

        if (nombre.isEmpty || edad <= 0 || edad >= 18) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Verifica que cada hijo tenga nombre y una edad válida menor de 18 años."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    await verificarSaldoYEnviarSolicitud();
  }


  Future<void> verificarSaldoYEnviarSolicitud() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorDomiciliaria = (configSnapshot.docs.first.data()['valor_domiciliaria'] ?? 0).toDouble();

    if (saldo < valorDomiciliaria) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: blanco,
          title: const Text("Pago requerido"),
          content: const Text("Para enviar esta solicitud debes realizar el pago del servicio."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(
                      tipoPago: 'domiciliaria',
                      valor: valorDomiciliaria.toInt(),
                      onTransaccionAprobada: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final userRef = FirebaseFirestore.instance.collection('Ppl').doc(user.uid);
                        final userDoc = await userRef.get();
                        final double saldoActual = (userDoc.data()?['saldo'] ?? 0).toDouble();

                        final nuevoSaldo = saldoActual - valorDomiciliaria;
                        await userRef.update({'saldo': nuevoSaldo});

                        await enviarSolicitudPrisionDomiciliaria();
                      },
                    ),
                  ),

                );
              },
              child: const Text("Pagar"),
            ),
          ],
        ),
      );
      return;
    }

    await enviarSolicitudPrisionDomiciliaria();
  }

  Future<void> enviarSolicitudPrisionDomiciliaria() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorDomiciliaria = (configSnapshot.docs.first.data()['valor_domiciliaria'] ?? 0).toDouble();

    if (!context.mounted) return;

    bool confirmarEnvio = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Confirmar envío"),
        content: const Text("Ya puedes enviar tu solicitud de Prisión domiciliaria"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Enviar")),
        ],
      ),
    );

    if (!confirmarEnvio) return;

    if(context.mounted){
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: blancoCards,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Subiendo información..."),
            ],
          ),
        ),
      );
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String docId = firestore.collection('prision_domiciliaria_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      List<String> urls = [];

      for (PlatformFile file in _selectedFiles) {
        try {
          String filePath = 'solicitudes_prision_domiciliaria/$docId/${file.name}';
          Reference storageRef = FirebaseStorage.instance.ref(filePath);
          UploadTask uploadTask = kIsWeb ? storageRef.putData(file.bytes!) : storageRef.putFile(File(file.path!));
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          archivosUrls.add(downloadUrl);
        } catch (_) {}
      }

      await firestore.collection('prision_domiciliaria_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'direccion': _direccionController.text.trim(),
        'departamento': departamentoSeleccionado,
        'municipio': municipioSeleccionado,
        'nombre_responsable': _nombreResponsableController.text.trim(),
        'cedula_responsable': _cedulaResponsableController.text.trim(),
        'celular_responsable': _celularResponsableController.text.trim(),
        'parentesco': parentescoSeleccionado,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
        'archivos': [
          if (urlArchivoRecibo != null) urlArchivoRecibo!,
          if (urlArchivoDeclaracion != null) urlArchivoDeclaracion!,
          if (urlArchivoInsolvencia != null) urlArchivoInsolvencia!,
          ...archivosUrls,
        ],
        'archivo_cedula_responsable': urlArchivoCedulaResponsable,
        if (tieneHijosConvivientes) 'hijos': hijos,
        if (tieneHijosConvivientes) 'documentos_hijos': urlsArchivosHijos,
      });


      await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).update({
        'saldo': saldo - valorDomiciliaria,
      });

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaDomiciliariaPage(numeroSeguimiento: numeroSeguimiento),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Hubo un problema al guardar la solicitud."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar")),
            ],
          ),
        );
      }
    }
  }

  Widget formularioHijos(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "8. Información de los Hijos",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CampoTextoGris(
                label: "Nombre del hijo",
                controller: _nombreHijoController,
                keyboardType: TextInputType.name,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 100,
              child: CampoTextoGris(
                label: "Edad",
                controller: _edadHijoController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final nombre = _nombreHijoController.text.trim();
                final edad = _edadHijoController.text.trim();
                if (nombre.isNotEmpty && edad.isNotEmpty) {
                  setState(() {
                    hijos.add({"nombre": nombre, "edad": edad});
                    _nombreHijoController.clear();
                    _edadHijoController.clear();
                  });
                }
              },
              child: const Icon(Icons.add),
            )
          ],
        ),
        const SizedBox(height: 10),
        // Lista de hijos agregados
        ...hijos.map((hijo) => ListTile(
          title: Text(hijo['nombre'] ?? ''),
          subtitle: Text("Edad: ${hijo['edad']} años"),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                hijos.remove(hijo);
              });
            },
          ),
        )),
      ],
    );
  }

}
