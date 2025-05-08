
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
import '../../../widgets/formulario_excepcion_68a.dart';
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
  List<PlatformFile> excepcionArchivos = [];



  @override
  void initState() {
    super.initState();
    docIdSolicitud = FirebaseFirestore.instance.collection('domiciliaria_solicitados').doc().id;
  }

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
                if (ModalRoute.of(context)?.settings.arguments is Map &&
                    (ModalRoute.of(context)?.settings.arguments as Map)['excepcionActivada'] == true) ...[
                  const SizedBox(height: 24),
                  const Divider(color: negroLetras, height: 1),
                  const SizedBox(height: 24),
                  const Text(
                    'Informaste que cuentas con una de las condiciones para acceder a este beneficio excluido según el art. 68A',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  FormularioExcepcion68A(
                    onArchivosSeleccionados: (archivos) {
                      // 🔸 Puedes guardar estos archivos en una lista temporal
                      excepcionArchivos = archivos;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
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
                  '2. Sube un recibo de servicios públicos de dicho domicilio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('recibo'),
                  child: Row(
                    children: [
                      Icon(
                        archivoRecibo != null ? Icons.check_circle : Icons.upload_file,
                        color: archivoRecibo != null ? Colors.green : Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoRecibo ?? 'Subir archivo',
                          style: TextStyle(
                            color: archivoRecibo != null ? Colors.black : Colors.deepPurple,
                            decoration: archivoRecibo != null ? TextDecoration.none : TextDecoration.underline,
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
                  '3. Sube la declaración extra juicio para la solicitud de prisión domiciliaria:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('declaracion'),
                  child: Row(
                    children: [
                      Icon(
                        archivoDeclaracion != null ? Icons.check_circle : Icons.upload_file,
                        color: archivoDeclaracion != null ? Colors.green : Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoDeclaracion ?? 'Subir archivo',
                          style: TextStyle(
                            color: archivoDeclaracion != null ? Colors.black : Colors.deepPurple,
                            decoration: archivoDeclaracion != null ? TextDecoration.none : TextDecoration.underline,
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
                const SizedBox(height: 24),
                const Text(
                  "5. Por favor selecciona qué relación tiene la persona responsable con el PPL (persona privada de la libertad)",
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
                  '6. Sube la fotocopia de la cédula de la persona responsable:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => pickSingleFile('cedula_responsable'),
                  child: Row(
                    children: [
                      Icon(
                        archivoCedulaResponsable != null ? Icons.check_circle : Icons.upload_file,
                        color: archivoCedulaResponsable != null ? Colors.green : Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archivoCedulaResponsable ?? 'Subir archivo',
                          style: TextStyle(
                            color: archivoCedulaResponsable != null ? Colors.black : Colors.deepPurple,
                            decoration: archivoCedulaResponsable != null ? TextDecoration.none : TextDecoration.underline,
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
                ingresarReparacionVictima(),
                const SizedBox(height: 24),

                // 🔹 Widget adicional si hay excepción activada por Art. 68A

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
                    'Selecciona esta opción si el Ppl vivirá con sus hijos mientras cumple el beneficio de prisión domiciliaria. Solo aplica para hijos menores de 18 años.',
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
                        '10. Adjuntar los documentos de identidad de los hijos',
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

                      // ✅ Lista de archivos seleccionados
                      if (archivosHijos.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: archivosHijos.map((file) {
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
                    backgroundColor: primary,
                  ),
                  onPressed: () async {
                    final validado = await validarCampos();
                    if (validado) {
                      final confirmado = await mostrarConfirmacionEnvio(context);
                      if (confirmado) {
                        await enviarSolicitud();
                      }
                    }
                  },
                  child: const Text(
                    'Enviar solicitud',
                    style: TextStyle(color: blanco),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> validarCampos() async {
    if (_direccionController.text.trim().isEmpty ||
        departamentoSeleccionado == null ||
        municipioSeleccionado == null ||
        archivoRecibo == null ||
        archivoDeclaracion == null ||
        archivoCedulaResponsable == null ||
        _opcionReparacionSeleccionada == null || _opcionReparacionSeleccionada!.isEmpty ||
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
      return false;
    }

    final celular = _celularResponsableController.text.trim();
    if (celular.length != 10 || !RegExp(r'^\d+$').hasMatch(celular)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El número de celular debe tener exactamente 10 dígitos."),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final cedula = _cedulaResponsableController.text.trim();
    if (cedula.length < 7 || cedula.length > 10 || !RegExp(r'^\d+$').hasMatch(cedula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La cédula debe tener entre 7 y 10 dígitos."),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (tieneHijosConvivientes) {
      if (hijos.isEmpty || archivosHijos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Por favor, agrega los datos de los hijos y sube sus documentos."),
            backgroundColor: Colors.red,
          ),
        );
        return false;
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
          return false;
        }
      }
    }

    return true; // ✅ Todo validado bien
  }


  Future<bool> mostrarConfirmacionEnvio(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text('Confirmar envío'),
          content: const Text('¿Estás seguro de enviar la solicitud?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar', style: TextStyle(color: blanco)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> enviarSolicitud() async {
    await verificarSaldoYEnviarSolicitud();
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
          } else if (tipo == 'insolvencia') {
            archivoInsolvencia = file.name;
          }
        });

        final String docId = docIdSolicitud!;
        String path = 'domiciliaria/$docId/archivos/${file.name}';

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
        print("❌ Error al seleccionar archivo: $e");
      }
    }
  }


  Future<void> pickMultipleFilesHijos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null && result.files.isNotEmpty) {
        final String docId = docIdSolicitud!;

        for (PlatformFile file in result.files) {
          if (!archivosHijos.any((f) => f.name == file.name)) {
            archivosHijos.add(file);

            String path = 'domiciliaria/$docId/archivos/hijos/${file.name}';

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


  final List<Map<String, String>> _opcionesReparacion = [
    {
      'clave': 'reparado',
      'texto': 'Se ha reparado a la víctima.'
    },
    {
      'clave': 'garantia',
      'texto': 'Se ha asegurado el pago de la indemnización mediante garantía personal, real, bancaria o acuerdo de pago.'
    },
    {
      'clave': 'insolvencia',
      'texto': 'No se ha reparado a la víctima ni asegurado el pago de la indemnización debido a estado de insolvencia.'
    },
  ];


  String? _opcionReparacionSeleccionada;

  Widget ingresarReparacionVictima() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "7. Reparación de la víctima (* Selección obligatoria *)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text("Indica si se realizó la reparación a la víctima, se aseguró el pago o si no ha sido posible por razones de insolvencia.",
            style: TextStyle(fontSize: 12, color: Colors.black87)),
        const SizedBox(height: 8),
        ..._opcionesReparacion.map((opcion) {
          return CheckboxListTile(
            value: _opcionReparacionSeleccionada == opcion['clave'],
            onChanged: (selected) {
              setState(() {
                _opcionReparacionSeleccionada =
                (_opcionReparacionSeleccionada == opcion['clave']) ? null : opcion['clave'];
              });
            },
            title: Text(opcion['texto']!, style: const TextStyle(fontSize: 14)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),


        if (_opcionReparacionSeleccionada ==
            "insolvencia")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '8. Recuerda que si tienes certificado de insolvencia puedes adjuntarlo para fortalecer tu solicitud (Opcional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => pickSingleFile('insolvencia'),
                child: Row(
                  children: [
                    Icon(
                      archivoInsolvencia != null ? Icons.check_circle : Icons.upload_file,
                      color: archivoInsolvencia != null ? Colors.green : Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        archivoInsolvencia ?? 'Subir archivo',
                        style: TextStyle(
                          color: archivoInsolvencia != null ? Colors.black : Colors.deepPurple,
                          decoration: archivoInsolvencia != null ? TextDecoration.none : TextDecoration.underline,
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
            ],
          ),
      ],
    );
  }

  void validarYEnviar() async {
    if (_direccionController.text.trim().isEmpty ||
        departamentoSeleccionado == null ||
        municipioSeleccionado == null ||
        archivoRecibo == null ||
        archivoDeclaracion == null ||
        archivoCedulaResponsable == null ||
        _opcionReparacionSeleccionada == null || _opcionReparacionSeleccionada!.isEmpty ||
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
            ),
          );
          return;
        }
      }
    }

    await verificarSaldoYEnviarSolicitud();
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance
        .collection('configuraciones')
        .limit(1)
        .get();

    final double valorDomiciliaria =
    (configSnapshot.docs.first.data()['valor_domiciliaria'] ?? 0).toDouble();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Pago requerido"),
        content: const Text("Para enviar esta solicitud debes realizar el pago del servicio."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
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
                      await enviarSolicitudPrisionDomiciliaria(valorDomiciliaria);
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
  }


  Future<void> enviarSolicitudPrisionDomiciliaria(double valorDomiciliaria) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

    if (context.mounted) {
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
      if (docIdSolicitud == null) {
        throw Exception("docIdSolicitud no ha sido inicializado.");
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String docId = docIdSolicitud!;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      List<String> urls = [];

      for (PlatformFile file in _selectedFiles) {
        try {
          String filePath = 'domiciliaria/$docId/archivos/${file.name}';

          Reference storageRef = FirebaseStorage.instance.ref(filePath);
          UploadTask uploadTask = kIsWeb
              ? storageRef.putData(file.bytes!)
              : storageRef.putFile(File(file.path!));
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();
          archivosUrls.add(downloadUrl);
        } catch (_) {}
      }

      await firestore.collection('domiciliaria_solicitados').doc(docId).set({
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
        'reparacion': _opcionReparacionSeleccionada,
      });

      await descontarSaldo(valorDomiciliaria);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaDomiciliariaPage(
              numeroSeguimiento: numeroSeguimiento,
            ),
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
        );
      }
      if (kDebugMode) {
        print("❌ Error al guardar solicitud: $e");
      }
    }
  }


  Future<void> descontarSaldo(double valor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('Ppl').doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final datos = snapshot.data();
      final double saldoActual = (datos?['saldo'] ?? 0).toDouble();
      final double nuevoSaldo = saldoActual - valor;

      // 🔒 Solo descontar si hay saldo suficiente
      if (nuevoSaldo >= 0) {
        await docRef.update({'saldo': nuevoSaldo});
      } else {
        debugPrint('⚠️ Saldo insuficiente, no se pudo descontar');
      }
    }
  }

  Widget formularioHijos(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "9. Información de los Hijos",
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
            Column(
              children: [
                const Text("Guardar", style: TextStyle(fontSize: 11)),
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
                  child: const Icon(Icons.save),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 10),
        // Lista de hijos agregados
        ...hijos.map((hijo) => ListTile(
          title: Text(hijo['nombre'] ?? ''),
          subtitle: Text("Edad: ${hijo['edad']} años"),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
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
