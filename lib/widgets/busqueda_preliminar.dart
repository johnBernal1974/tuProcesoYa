import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../src/colors/colors.dart';

/// ---- Helpers generales ----

String _formatearMesesDias(int totalDias) {
  if (totalDias <= 0) return '0 días';

  final int meses = totalDias ~/ 30; // convención: 30 días = 1 mes
  final int dias = totalDias % 30;

  if (meses > 0 && dias > 0) {
    return '$meses meses y $dias días';
  } else if (meses > 0) {
    return '$meses meses';
  } else {
    return '$dias días';
  }
}

class _BeneficioResumen {
  final String nombre;
  final int diasDesde;

  _BeneficioResumen(this.nombre, this.diasDesde);
}

class DelitoItem {
  final String nombre;
  final bool excluidoBeneficios; // Art. 68A CP u otros

  const DelitoItem(this.nombre, {this.excluidoBeneficios = false});
}

/// ---- Decoración de inputs (borde gris siempre, rojo solo en error) ----
InputDecoration _inputDecoration(String label) {
  final grey = Colors.grey.shade400;
  final greyFocused = Colors.grey.shade600;

  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: grey),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: greyFocused, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

/// ---- Widget principal ----

class CalculoCondenaWidget extends StatefulWidget {
  final void Function({
  required int totalCondenaDias,
  required int diasEjecutados,
  required int diasRedimidos,
  required int diasCumplidos,
  required int diasRestantes,
  required double porcentajeCumplido,
  required DateTime fechaCaptura,
  })? onValidated;

  const CalculoCondenaWidget({
    super.key,
    this.onValidated,
  });

  @override
  State<CalculoCondenaWidget> createState() => _CalculoCondenaWidgetState();
}

class _CalculoCondenaWidgetState extends State<CalculoCondenaWidget> {
  final _formKey = GlobalKey<FormState>();

  // ---- Delito ----
  final List<DelitoItem> _delitos = const [
    // Ejemplo base. Idealmente esta lista completa la podrías cargar desde Firestore.
    DelitoItem('Delitos contra la Administración Pública', excluidoBeneficios: true),
    DelitoItem('Delitos contra la libertad, integridad y formación sexual', excluidoBeneficios: true),
    DelitoItem('Extorsión', excluidoBeneficios: true),
    DelitoItem('Feminicidio', excluidoBeneficios: true),
    DelitoItem('Homicidio agravado', excluidoBeneficios: true),
    DelitoItem('Lavado de activos', excluidoBeneficios: true),
    DelitoItem('Secuestro extorsivo', excluidoBeneficios: true),
    DelitoItem('Secuestro simple', excluidoBeneficios: true),
    DelitoItem('Terrorismo', excluidoBeneficios: true),
    DelitoItem('Tráfico de estupefacientes', excluidoBeneficios: true),
    DelitoItem('Violencia intrafamiliar', excluidoBeneficios: true),
    DelitoItem('Concierto para delinquir agravado', excluidoBeneficios: true),
    // No excluidos (ejemplo)
    DelitoItem('Homicidio simple'),
    DelitoItem('Hurto calificado'),
    DelitoItem('Rebelión'),
    // Otro
    DelitoItem('Otro (escribir)'),
  ];



  DelitoItem? _delitoSeleccionado;
  final TextEditingController _otroDelitoCtrl = TextEditingController();

  bool get _delitoEsExcluido =>
      _delitoSeleccionado?.excluidoBeneficios ?? false;

  String get _nombreDelitoElegido {
    if (_delitoSeleccionado == null) return '';
    if (_delitoSeleccionado!.nombre == 'Otro (escribir)') {
      return _otroDelitoCtrl.text.trim();
    }
    return _delitoSeleccionado!.nombre;
  }

  // ---- Campos de condena ----
  final TextEditingController _mesesCtrl = TextEditingController();
  final TextEditingController _diasCtrl = TextEditingController();
  final TextEditingController _diasRedimidosCtrl = TextEditingController();
  DateTime? _fechaCaptura;

  // ---- Resultados ----
  int? _diasEjecutados;
  int? _totalCondenaDias;
  int? _diasCumplidos;
  int? _diasRestantes;
  double? _porcentajeCumplido;
  int? _diasFaltantesPrimerBeneficio;

  // ---- Datos del acudiente ----
  final TextEditingController _acudienteNombresCtrl = TextEditingController();
  final TextEditingController _acudienteApellidosCtrl = TextEditingController();
  final TextEditingController _acudienteDocumentoCtrl = TextEditingController();
  final TextEditingController _acudienteCelularCtrl = TextEditingController();

  String? _acudienteParentescoSeleccionado;
  String? _acudienteTipoDocumentoSeleccionado;


  final List<String> _parentescos = [
    // 👪 Padres
    'Madre',
    'Padre',

    // 👧👦 Hijos
    'Hija',
    'Hijo',

    // 💑 Cónyuge
    'Esposa',
    'Esposo',

    // 👵👴 Abuelos
    'Abuela',
    'Abuelo',

    // 👧👦 Nietos
    'Nieta',
    'Nieto',

    // 🧍‍♂️🧍‍♀️ Hermanos
    'Hermana',
    'Hermano',

    // 👨‍👧‍👦 Tíos y primos
    'Tía',
    'Tío',
    'Prima',
    'Primo',

    // 👨‍❤️‍👨 Pareja no conyugal
    'Compañera',
    'Compañero',

    // 👨‍👩‍👧‍👦 Familia política
    'Cuñada',
    'Cuñado',
    'Suegra',
    'Suegro',
    'Nuera',
    'Yerno',

    // 👧👦 Sobrinos
    'Sobrina',
    'Sobrino',

    // 👥 Amistades
    'Amiga',
    'Amigo',

    // 👨‍⚖️ Representantes legales o similares
    'Abogado/a',
    'Tutor/a',
    'Padrastro',
    'Madrastra',
    'Hermanastro',
    'Hermanastra',
    'Hijastro',
    'Hijastra',

    // 🙋‍♀️ En nombre propio
    'En nombre propio',

    // ❓ Otro
    'Otro',
  ];

  final List<String> _tiposDocumentoAcudiente = [
    'Cédula de ciudadanía',
    'Cédula de extranjería',
  ];




  // ---- Datos del PPL ----
  final TextEditingController _nombresCtrl = TextEditingController();
  final TextEditingController _apellidosCtrl = TextEditingController();
  final TextEditingController _numeroDocCtrl = TextEditingController();
  final TextEditingController _tdCtrl = TextEditingController();
  final TextEditingController _nuiCtrl = TextEditingController();
  final TextEditingController _numeroProcesoCtrl = TextEditingController();
  final TextEditingController _patioCtrl = TextEditingController();
  String? _tipoDocumentoSeleccionado;

  List<_BeneficioResumen> _beneficiosCumplidos = [];

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // ---- Estado de guardado / resumen ----
  bool _guardando = false;
  String? _resumenGuardado;

  // LISTAS OBTENIDAS DESDE FIRESTORE
  List<Map<String, Object>> centrosReclusionTodos = [];
  List<Map<String, String>> juzgadosEjecucionPenas = [];
  List<Map<String, String>> juzgadosConocimiento = [];

  bool _isLoadingCentros = false;
  bool _isLoadingEjecucion = false;
  bool _isLoadingConocimiento = false;

// VALORES SELECCIONADOS EN LOS DROPS
  String? _centroReclusionSeleccionadoId;
  String? _juzgadoEjecucionSeleccionadoId;
  String? _juzgadoConocimientoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _fetchDatosParaDrops();
  }

  Future<void> _fetchDatosParaDrops() async {
    await _fetchTodosCentrosReclusion();
    await _fetchJuzgadosEjecucion();
    await _fetchTodosJuzgadosConocimiento(forzar: true);

    setState(() {
      _isLoadingCentros = false;
      _isLoadingEjecucion = false;
      _isLoadingConocimiento = false;
    });
  }

  Future<void> _fetchTodosCentrosReclusion() async {
    if (_isLoadingCentros) return;
    _isLoadingCentros = true;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('centros_reclusion')
          .get();

      List<Map<String, Object>> fetchedTodosCentros = querySnapshot.docs.map((doc) {
        final regionalId = doc.reference.parent.parent?.id ?? "";
        final data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'nombre': data.containsKey('nombre') ? data['nombre'].toString() : '',
          'regional': regionalId,
          'correos': {
            'correo_direccion': data.containsKey('correo_direccion') ? data['correo_direccion'] ?? '' : '',
            'correo_juridica': data.containsKey('correo_juridica') ? data['correo_juridica'] ?? '' : '',
            'correo_principal': data.containsKey('correo_principal') ? data['correo_principal'] ?? '' : '',
            'correo_sanidad': data.containsKey('correo_sanidad') ? data['correo_sanidad'] ?? '' : '',
          }
        };
      }).toList();

      // 👉 ORDEN ALFABÉTICO POR NOMBRE
      fetchedTodosCentros.sort((a, b) {
        final nombreA = (a['nombre'] ?? '') as String;
        final nombreB = (b['nombre'] ?? '') as String;
        return nombreA.toLowerCase().compareTo(nombreB.toLowerCase());
      });

      if (mounted) {
        setState(() {
          centrosReclusionTodos = fetchedTodosCentros;
        });
      }
    } catch (e) {
      debugPrint("❌ Error al obtener centros de reclusión: $e");
    } finally {
      _isLoadingCentros = false;
    }
  }


  Future<void> _fetchJuzgadosEjecucion() async {
    if (_isLoadingEjecucion) return;
    _isLoadingEjecucion = true;

    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('ejecucion_penas').get();

      List<Map<String, String>> fetchedEjecucionPenas = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'juzgadoEP': doc.get('juzgadoEP').toString(),
          'email': doc.get('email').toString(),
        };
      }).toList();

      // 👉 ORDEN ALFABÉTICO POR NOMBRE DEL JUZGADO
      fetchedEjecucionPenas.sort((a, b) {
        final nombreA = a['juzgadoEP'] ?? '';
        final nombreB = b['juzgadoEP'] ?? '';
        return nombreA.toLowerCase().compareTo(nombreB.toLowerCase());
      });

      if (mounted) {
        setState(() {
          juzgadosEjecucionPenas = fetchedEjecucionPenas;
        });
      }
    } catch (e) {
      debugPrint("❌ Error al obtener los juzgados de ejecución: $e");
    } finally {
      _isLoadingEjecucion = false;
    }
  }


  Future<void> _fetchTodosJuzgadosConocimiento({bool forzar = false}) async {
    if (!forzar && juzgadosConocimiento.isNotEmpty) return;
    if (_isLoadingConocimiento) return;
    _isLoadingConocimiento = true;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('juzgados')
          .get();

      List<Map<String, String>> fetchedJuzgados = querySnapshot.docs.map((doc) {
        final ciudadId = doc.reference.parent.parent?.id ?? "";
        final data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'nombre': data['nombre'].toString(),
          'correo': data.containsKey('correo') ? data['correo'].toString() : '',
          'ciudad': ciudadId,
        };
      }).toList();

      // 👉 ORDEN ALFABÉTICO POR NOMBRE DEL JUZGADO
      fetchedJuzgados.sort((a, b) {
        final nombreA = a['nombre'] ?? '';
        final nombreB = b['nombre'] ?? '';
        return nombreA.toLowerCase().compareTo(nombreB.toLowerCase());
      });

      if (mounted) {
        setState(() {
          juzgadosConocimiento = fetchedJuzgados;
        });
      }

      debugPrint("✅ Juzgados de conocimiento cargados correctamente.");
    } catch (e) {
      debugPrint("❌ Error al obtener los juzgados de conocimiento: $e");
    } finally {
      _isLoadingConocimiento = false;
    }
  }


  // 🔎 Helpers para mostrar nombre en el payload si quieres
  String? _buscarNombreCentroPorId(String? id) {
    if (id == null) return null;
    final match = centrosReclusionTodos.firstWhere(
          (c) => c['id'] == id,
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    return match['nombre'] as String?;
  }

  String? _buscarNombreJuzgadoEjecucionPorId(String? id) {
    if (id == null) return null;
    final match = juzgadosEjecucionPenas.firstWhere(
          (j) => j['id'] == id,
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    return match['juzgadoEP'];
  }

  String? _buscarNombreJuzgadoConocimientoPorId(String? id) {
    if (id == null) return null;
    final match = juzgadosConocimiento.firstWhere(
          (j) => j['id'] == id,
      orElse: () => {},
    );
    if (match.isEmpty) return null;
    return match['nombre'];
  }





  @override
  void dispose() {
    _mesesCtrl.dispose();
    _diasCtrl.dispose();
    _diasRedimidosCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _numeroDocCtrl.dispose();
    _tdCtrl.dispose();
    _nuiCtrl.dispose();
    _otroDelitoCtrl.dispose();
    _numeroProcesoCtrl.dispose();
    _patioCtrl.dispose();
    super.dispose();
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();

    _mesesCtrl.clear();
    _diasCtrl.clear();
    _diasRedimidosCtrl.clear();
    _nombresCtrl.clear();
    _apellidosCtrl.clear();
    _numeroDocCtrl.clear();
    _tdCtrl.clear();
    _nuiCtrl.clear();
    _otroDelitoCtrl.clear();
    _numeroProcesoCtrl.clear();
    _patioCtrl.clear();

    _delitoSeleccionado = null;
    _tipoDocumentoSeleccionado = null;
    _fechaCaptura = null;

    _centroReclusionSeleccionadoId = null;
    _juzgadoEjecucionSeleccionadoId = null;
    _juzgadoConocimientoSeleccionadoId = null;

    _diasEjecutados = null;
    _totalCondenaDias = null;
    _diasCumplidos = null;
    _diasRestantes = null;
    _porcentajeCumplido = null;
    _beneficiosCumplidos = [];
    _diasFaltantesPrimerBeneficio = null;
  }

  Future<void> _seleccionarFechaCaptura() async {
    final ahora = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaCaptura ?? ahora,
      firstDate: DateTime(1990),
      lastDate: ahora,
      helpText: 'Selecciona la fecha de captura',
      locale: const Locale('es', 'CO'),
    );

    if (picked != null) {
      setState(() {
        _fechaCaptura = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;

    if (_delitoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona el delito')),
      );
      return;
    }

    if (_delitoSeleccionado!.nombre == 'Otro (escribir)' &&
        _otroDelitoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del delito')),
      );
      return;
    }

    if (_fechaCaptura == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona la fecha de captura')),
      );
      return;
    }

    final int meses = int.tryParse(_mesesCtrl.text.trim()) ?? 0;
    final int diasCondena = int.tryParse(_diasCtrl.text.trim()) ?? 0;
    final int diasRedimidos = int.tryParse(_diasRedimidosCtrl.text.trim()) ?? 0;

    final int totalMesesEnDias = meses * 30;
    final int totalCondenaDias = totalMesesEnDias + diasCondena;

    final now = DateTime.now();
    int diasEjecutados = now.difference(_fechaCaptura!).inDays;
    if (diasEjecutados < 0) diasEjecutados = 0;

    final int diasCumplidos = diasEjecutados + diasRedimidos;

    int diasRestantes = totalCondenaDias - diasCumplidos;
    if (diasRestantes < 0) diasRestantes = 0;

    double porcentajeCumplido = 0;
    if (totalCondenaDias > 0) {
      porcentajeCumplido = (diasCumplidos / totalCondenaDias) * 100;
    }

    final List<_BeneficioResumen> beneficiosCumplidosTemp = [];

    void evaluarBeneficio(String nombre, double porcentajeRequerido) {
      final int diasUmbral =
      (totalCondenaDias * (porcentajeRequerido / 100)).round();
      final int diferencia = diasCumplidos - diasUmbral;
      if (diferencia >= 0) {
        beneficiosCumplidosTemp.add(
          _BeneficioResumen(nombre, diferencia),
        );
      }
    }

    evaluarBeneficio('Permiso administrativo de hasta 72 horas', 33.33);
    evaluarBeneficio('Prisión domiciliaria', 50.0);
    evaluarBeneficio('Libertad condicional', 60.0);
    evaluarBeneficio('Extinción de la pena', 100.0);

    int? diasFaltantesPrimerBeneficio;
    if (beneficiosCumplidosTemp.isEmpty && totalCondenaDias > 0) {
      final int diasUmbralPrimer =
      (totalCondenaDias * (33.33 / 100)).round();
      int faltan = diasUmbralPrimer - diasCumplidos;
      if (faltan < 0) faltan = 0;
      diasFaltantesPrimerBeneficio = faltan;
    }

    setState(() {
      _diasEjecutados = diasEjecutados;
      _totalCondenaDias = totalCondenaDias;
      _diasCumplidos = diasCumplidos;
      _diasRestantes = diasRestantes;
      _porcentajeCumplido = porcentajeCumplido;

      _beneficiosCumplidos = beneficiosCumplidosTemp;
      _diasFaltantesPrimerBeneficio = diasFaltantesPrimerBeneficio;
    });

    if (widget.onValidated != null) {
      widget.onValidated!(
        totalCondenaDias: totalCondenaDias,
        diasEjecutados: diasEjecutados,
        diasRedimidos: diasRedimidos,
        diasCumplidos: diasCumplidos,
        diasRestantes: diasRestantes,
        porcentajeCumplido: porcentajeCumplido,
        fechaCaptura: _fechaCaptura!,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool hayResultados = _diasEjecutados != null &&
        _totalCondenaDias != null &&
        _diasCumplidos != null &&
        _diasRestantes != null &&
        _porcentajeCumplido != null;

    return Card(
      elevation: 3,
      color: blancoCards, // 👈 tu color de fondo
      surfaceTintColor: blancoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───────── TARJETA VERDE DESPUÉS DE GUARDAR ─────────
                if (_resumenGuardado != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 👇 Convertimos el texto en líneas y damos estilo
                        ..._resumenGuardado!
                            .split('\n')
                            .where((linea) => linea.trim().isNotEmpty)
                            .map((linea) {
                          final partes = linea.split(': ');

                          // Si la línea tiene formato "Titulo: valor"
                          if (partes.length > 1) {
                            final titulo = partes[0];
                            final valor = partes.sublist(1).join(': '); // por si hay más ':'

                            return RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$titulo: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: valor,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Para líneas como "Beneficios cumplidos:" o frases sueltas
                            return Text(
                              linea,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                        }).toList(),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _resumenGuardado = null; // 👈 vuelve a mostrar el formulario
                              });
                            },
                            child: const Text('Siguiente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ───────── FORMULARIO COMPLETO SOLO SI NO HAY RESUMEN ─────────
                if (_resumenGuardado == null) ...[
                  Text(
                    'Cálculo de condena',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- DELITO (DROP + OPCIÓN OTRO) ----
                  DropdownButtonFormField<DelitoItem>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    decoration: _inputDecoration('Delito'),
                    value: _delitoSeleccionado,
                    items: _delitos
                        .map(
                          (d) => DropdownMenuItem<DelitoItem>(
                        value: d,
                        child: Text(
                          d.nombre,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: d.excluidoBeneficios ? Colors.red : null,
                          ),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _delitoSeleccionado = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona el delito';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  if (_delitoSeleccionado != null && _delitoEsExcluido)
                    Text(
                      'Este delito está excluido de varios beneficios y subrogados (Art. 68A CP).',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                  if (_delitoSeleccionado != null &&
                      _delitoSeleccionado!.nombre == 'Otro (escribir)') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _otroDelitoCtrl,
                      decoration: _inputDecoration('Especificar delito'),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ---- CAMPOS DE CONDENA ----
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mesesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Meses de condena'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obligatorio';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Solo números';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _diasCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Días de condena'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Obligatorio';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Solo números';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ---- FECHA CAPTURA (con validador) ----
                  FormField<DateTime>(
                    validator: (value) {
                      if (_fechaCaptura == null) {
                        return 'Selecciona la fecha de captura';
                      }
                      return null;
                    },
                    builder: (state) {
                      return InkWell(
                        onTap: () async {
                          await _seleccionarFechaCaptura();
                          state.didChange(_fechaCaptura);
                        },
                        child: InputDecorator(
                          decoration:
                          _inputDecoration('Fecha de captura').copyWith(
                            errorText: state.errorText,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fechaCaptura == null
                                    ? 'Selecciona la fecha'
                                    : _dateFormat.format(_fechaCaptura!),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ---- DÍAS REDIMIDOS ----
                  TextFormField(
                    controller: _diasRedimidosCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Días redimidos'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Obligatorio';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Solo números';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ---- BOTÓN VALIDAR ----
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calcular,
                      child: const Text('Validar'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (hayResultados) ...[
                    const Divider(),
                    Text(
                      'Resultados',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _ResultadoChip(
                          titulo: 'Condena total',
                          valor: _formatearMesesDias(_totalCondenaDias!),
                        ),
                        _ResultadoChip(
                          titulo: 'Días ejecutados',
                          valor: _formatearMesesDias(_diasEjecutados!),
                        ),
                        _ResultadoChip(
                          titulo: 'Días redimidos',
                          valor: _formatearMesesDias(
                            int.tryParse(_diasRedimidosCtrl.text.trim()) ?? 0,
                          ),
                        ),
                        _ResultadoChip(
                          titulo: 'Condena total cumplida',
                          valor: _formatearMesesDias(_diasCumplidos!),
                        ),
                        _ResultadoChip(
                          titulo: 'Condena restante',
                          valor: _formatearMesesDias(_diasRestantes!),
                        ),
                        _ResultadoChip(
                          titulo: '% cumplido',
                          valor:
                          '${_porcentajeCumplido!.toStringAsFixed(2)}%',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Beneficios según porcentaje cumplido',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: [
                        _BeneficioCard(
                          titulo: 'Permiso administrativo de hasta 72 horas',
                          porcentajeRequerido: 33.33,
                          porcentajeActual: _porcentajeCumplido!,
                          totalCondenaDias: _totalCondenaDias!,
                          diasCumplidos: _diasCumplidos!,
                        ),
                        const SizedBox(height: 8),
                        _BeneficioCard(
                          titulo: 'Prisión domiciliaria',
                          porcentajeRequerido: 50.0,
                          porcentajeActual: _porcentajeCumplido!,
                          totalCondenaDias: _totalCondenaDias!,
                          diasCumplidos: _diasCumplidos!,
                        ),
                        const SizedBox(height: 8),
                        _BeneficioCard(
                          titulo: 'Libertad condicional',
                          porcentajeRequerido: 60.0,
                          porcentajeActual: _porcentajeCumplido!,
                          totalCondenaDias: _totalCondenaDias!,
                          diasCumplidos: _diasCumplidos!,
                        ),
                        const SizedBox(height: 8),
                        _BeneficioCard(
                          titulo: 'Extinción de la pena',
                          porcentajeRequerido: 100.0,
                          porcentajeActual: _porcentajeCumplido!,
                          totalCondenaDias: _totalCondenaDias!,
                          diasCumplidos: _diasCumplidos!,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_beneficiosCumplidos.isEmpty &&
                        _diasFaltantesPrimerBeneficio != null)
                      Text(
                        'Para alcanzar el primer beneficio (72 horas) faltan '
                            '${_formatearMesesDias(_diasFaltantesPrimerBeneficio!)}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // ---- DATOS DEL PPL ----
                    const Divider(),
                    Text(
                      'Datos del PPL',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombresCtrl,
                            decoration: _inputDecoration('Nombres'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidosCtrl,
                            decoration: _inputDecoration('Apellidos'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Tipo de documento'),
                      value: _tipoDocumentoSeleccionado,
                      items: const [
                        DropdownMenuItem(
                          value: 'Cédula de ciudadanía',
                          child: Text('Cédula de ciudadanía'),
                        ),
                        DropdownMenuItem(
                          value: 'Cédula de extranjería',
                          child: Text('Cédula de extranjería'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tipoDocumentoSeleccionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona una opción';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _numeroDocCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                      _inputDecoration('Número de documento'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _tdCtrl,
                      decoration: _inputDecoration('TD'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nuiCtrl,
                      decoration: _inputDecoration('NUI'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // 🔹 Patio
                    TextFormField(
                      controller: _patioCtrl,
                      decoration: _inputDecoration('Patio'),
                    ),
                    const SizedBox(height: 16),
                    // 🔹 Número de proceso
                    TextFormField(
                      controller: _numeroProcesoCtrl,
                      decoration: _inputDecoration('Número de proceso'),
                      // lo puedes dejar sin validator si no es obligatorio
                    ),

                    const SizedBox(height: 12),

                    // 🔹 Centro de reclusión (DROP)
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Centro de reclusión'),
                      value: _centroReclusionSeleccionadoId,
                      isExpanded: true,
                      items: centrosReclusionTodos.map((centro) {
                        final nombre = (centro['nombre'] ?? '') as String;
                        final regional = (centro['regional'] ?? '') as String;
                        final id = (centro['id'] ?? '') as String;
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            '$nombre ($regional)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _centroReclusionSeleccionadoId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // 🔹 Juzgado de ejecución de penas (DROP)
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Juzgado de ejecución de penas'),
                      value: _juzgadoEjecucionSeleccionadoId,
                      isExpanded: true,
                      items: juzgadosEjecucionPenas.map((j) {
                        return DropdownMenuItem<String>(
                          value: j['id'],
                          child: Text(
                            j['juzgadoEP'] ?? '',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _juzgadoEjecucionSeleccionadoId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // 🔹 Juzgado de conocimiento (DROP)
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Juzgado de conocimiento'),
                      value: _juzgadoConocimientoSeleccionadoId,
                      isExpanded: true,
                      items: juzgadosConocimiento.map((j) {
                        final ciudad = j['ciudad'] ?? '';
                        final nombre = j['nombre'] ?? '';
                        return DropdownMenuItem<String>(
                          value: j['id'],
                          child: Text(
                            '$nombre ($ciudad)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _juzgadoConocimientoSeleccionadoId = value;
                        });
                      },
                    ),

                    const Divider(),
                    Text(
                      'Datos del acudiente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

// 🔹 Nombres y apellidos
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _acudienteNombresCtrl,
                            decoration: _inputDecoration('Nombres'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _acudienteApellidosCtrl,
                            decoration: _inputDecoration('Apellidos'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Obligatorio';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

// 🔹 Parentesco
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Parentesco'),
                      value: _acudienteParentescoSeleccionado,
                      items: _parentescos
                          .map(
                            (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _acudienteParentescoSeleccionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona el parentesco';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

// 🔹 Tipo de documento
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Tipo de documento'),
                      value: _acudienteTipoDocumentoSeleccionado,
                      items: _tiposDocumentoAcudiente
                          .map(
                            (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t),
                        ),
                      )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _acudienteTipoDocumentoSeleccionado = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona el tipo de documento';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

// 🔹 Número de documento
                    TextFormField(
                      controller: _acudienteDocumentoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Número de documento'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obligatorio';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

// 🔹 Celular / WhatsApp
                    TextFormField(
                      controller: _acudienteCelularCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Número de celular / WhatsApp'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obligatorio';
                        }
                        if (value.length < 10) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardando
                            ? null
                            : () async {
                          if (!_formKey.currentState!.validate()) return;

                          if (_totalCondenaDias == null ||
                              _diasCumplidos == null ||
                              _porcentajeCumplido == null ||
                              _fechaCaptura == null ||
                              _diasEjecutados == null ||
                              _diasRestantes == null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Primero debes calcular la condena antes de guardar.',
                                ),
                              ),
                            );
                            return;
                          }

                          final int diasRedimidosInt =
                              int.tryParse(_diasRedimidosCtrl.text.trim()) ?? 0;

                          // Confirmación
                          final bool? confirmar = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Confirmar guardado'),
                                content: const Text(
                                  '¿Deseas guardar este análisis en la base de datos?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Guardar'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmar != true) return;

                          final double p = _porcentajeCumplido!;
                          final bool permiso72Cumplido = p >= 33.33;
                          final bool domiciliariaCumplida = p >= 50.0;
                          final bool condicionalCumplida = p >= 60.0;
                          final bool extincionCumplida = p >= 100.0;

                          final bool tieneAlgunBeneficio =
                              permiso72Cumplido ||
                                  domiciliariaCumplida ||
                                  condicionalCumplida ||
                                  extincionCumplida;

                          final List<String>
                          beneficiosCumplidosNombres =
                          _beneficiosCumplidos
                              .map((b) => b.nombre)
                              .toList();

                          final int diasFaltantesPrimerBeneficio =
                              _diasFaltantesPrimerBeneficio ?? 0;

                          final payload = <String, dynamic>{
                            'nombres': _nombresCtrl.text.trim(),
                            'apellidos': _apellidosCtrl.text.trim(),
                            'tipo_documento':
                            _tipoDocumentoSeleccionado,
                            'numero_documento':
                            _numeroDocCtrl.text.trim(),
                            'td': _tdCtrl.text.trim(),
                            'nui': _nuiCtrl.text.trim(),
                            'numero_proceso': _numeroProcesoCtrl.text.trim(),
                            'centro_reclusion_id': _centroReclusionSeleccionadoId,
                            'centro_reclusion_nombre':
                            _buscarNombreCentroPorId(_centroReclusionSeleccionadoId),
                            'juzgado_ejecucion_id': _juzgadoEjecucionSeleccionadoId,
                            'juzgado_ejecucion_nombre':
                            _buscarNombreJuzgadoEjecucionPorId(_juzgadoEjecucionSeleccionadoId),
                            'juzgado_conocimiento_id': _juzgadoConocimientoSeleccionadoId,
                            'juzgado_conocimiento_nombre':
                            _buscarNombreJuzgadoConocimientoPorId(_juzgadoConocimientoSeleccionadoId),
                            'patio': _patioCtrl.text.trim(),
                            'delito': _nombreDelitoElegido,
                            'delito_excluido_beneficios':
                            _delitoEsExcluido,
                            'total_condena_dias': _totalCondenaDias,
                            'dias_ejecutados': _diasEjecutados,
                            'dias_redimidos': diasRedimidosInt,
                            'dias_cumplidos': _diasCumplidos,
                            'dias_restantes': _diasRestantes,
                            'porcentaje_cumplido':
                            _porcentajeCumplido,
                            'fecha_captura':
                            Timestamp.fromDate(_fechaCaptura!),
                            'fecha_calculo': Timestamp.now(),
                            'permiso72_cumplido': permiso72Cumplido,
                            'domiciliaria_cumplida':
                            domiciliariaCumplida,
                            'libertad_condicional_cumplida':
                            condicionalCumplida,
                            'extincion_pena_cumplida':
                            extincionCumplida,
                            'tiene_beneficio': tieneAlgunBeneficio,
                            'beneficios_cumplidos':
                            beneficiosCumplidosNombres,
                            'dias_faltantes_primer_beneficio':
                            diasFaltantesPrimerBeneficio,
                            'acudiente_nombres': _acudienteNombresCtrl.text.trim(),
                            'acudiente_apellidos': _acudienteApellidosCtrl.text.trim(),
                            'acudiente_parentesco': _acudienteParentescoSeleccionado,
                            'acudiente_tipo_documento': _acudienteTipoDocumentoSeleccionado,
                            'acudiente_numero_documento': _acudienteDocumentoCtrl.text.trim(),
                            'acudiente_celular': _acudienteCelularCtrl.text.trim(),
                          };

                          // Construimos el RESUMEN en meses/días
                          final buffer = StringBuffer();
                          buffer.writeln(
                              'Nombre: ${_nombresCtrl.text.trim()} ${_apellidosCtrl.text.trim()}');
                          buffer.writeln(
                              'Documento: ${_tipoDocumentoSeleccionado ?? '-'} ${_numeroDocCtrl.text.trim()}');
                          buffer.writeln(
                              'TD: ${_tdCtrl.text.trim().isEmpty ? '—' : _tdCtrl.text.trim()} · '
                                  'NUI: ${_nuiCtrl.text.trim().isEmpty ? '—' : _nuiCtrl.text.trim()}');
                          buffer.writeln(
                              'Delito: $_nombreDelitoElegido${_delitoEsExcluido ? ' (excluido de beneficios)' : ''}');
                          buffer.writeln(
                              'Fecha de captura: ${_dateFormat.format(_fechaCaptura!)}');
                          buffer.writeln(
                              'Condena total: ${_formatearMesesDias(_totalCondenaDias!)}');
                          buffer.writeln(
                              'Días ejecutados: ${_formatearMesesDias(_diasEjecutados!)}');
                          buffer.writeln(
                              'Días redimidos: ${_formatearMesesDias(diasRedimidosInt)}');
                          buffer.writeln(
                              'Condena total cumplida: ${_formatearMesesDias(_diasCumplidos!)}');
                          buffer.writeln(
                              'Condena restante: ${_formatearMesesDias(_diasRestantes!)}');
                          buffer.writeln(
                              'Cumplido: ${_porcentajeCumplido!.toStringAsFixed(2)}%');

                          if (_beneficiosCumplidos.isNotEmpty) {
                            buffer.writeln('\nBeneficios cumplidos:');
                            for (final b in _beneficiosCumplidos) {
                              buffer.writeln(
                                  '- ${b.nombre}: desde hace ${_formatearMesesDias(b.diasDesde)}');
                            }
                          } else {
                            buffer.writeln(
                                '\nAún no cumple beneficios. Faltan ${_formatearMesesDias(diasFaltantesPrimerBeneficio)} para el primero (72 horas).');
                          }

                          final resumenTexto = buffer.toString();

                          setState(() => _guardando = true);

                          try {
                            await FirebaseFirestore.instance
                                .collection('analisis_condena_ppl')
                                .add(payload);

                            if (!mounted) return;

                            setState(() {
                              _resumenGuardado = resumenTexto;
                            });
                            _limpiarFormulario();

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Análisis guardado correctamente.'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Error al guardar el análisis: $e'),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _guardando = false);
                            }
                          }
                        },
                        child: _guardando
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                            : const Text('Guardar'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---- Widgets auxiliares ----

class _ResultadoChip extends StatelessWidget {
  final String titulo;
  final String valor;

  const _ResultadoChip({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      backgroundColor: Colors.grey.shade200,
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            valor,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeneficioCard extends StatelessWidget {
  final String titulo;
  final double porcentajeRequerido;
  final double porcentajeActual;
  final int totalCondenaDias;
  final int diasCumplidos;

  const _BeneficioCard({
    required this.titulo,
    required this.porcentajeRequerido,
    required this.porcentajeActual,
    required this.totalCondenaDias,
    required this.diasCumplidos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final int diasUmbral =
    (totalCondenaDias * (porcentajeRequerido / 100)).round();
    final int diferencia = diasCumplidos - diasUmbral;
    final bool cumplido = diferencia >= 0;

    final String mensaje;
    final Color colorFondo;
    final Color colorBorde;
    final Color colorTextoTitulo;

    if (cumplido) {
      mensaje =
      'Ya cumple el requisito desde hace ${_formatearMesesDias(diferencia)}.';
      colorFondo = Colors.green.shade50;
      colorBorde = Colors.green.shade300;
      colorTextoTitulo = Colors.green.shade800;
    } else {
      mensaje =
      'Aún no cumple. Faltan ${_formatearMesesDias(-diferencia)} para alcanzar el requisito.';
      colorFondo = Colors.red.shade50;
      colorBorde = Colors.red.shade300;
      colorTextoTitulo = Colors.red.shade800;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorBorde),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorTextoTitulo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Requiere: ${porcentajeRequerido.toStringAsFixed(2)}% · Actual: ${porcentajeActual.toStringAsFixed(2)}%',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            mensaje,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
