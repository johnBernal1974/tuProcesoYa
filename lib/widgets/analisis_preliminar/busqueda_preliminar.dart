
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../src/colors/colors.dart';

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
  final greyHint = Colors.grey.shade700;

  return InputDecoration(
    labelText: label,

    // 🔹 Color normal del label
    labelStyle: TextStyle(color: greyFocused),

    // 🔹 Color del label cuando flota (focus)
    floatingLabelStyle: MaterialStateTextStyle.resolveWith(
          (states) {
        if (states.contains(MaterialState.error)) {
          return const TextStyle(color: Colors.red);
        }
        if (states.contains(MaterialState.focused)) {
          return TextStyle(color: greyFocused);
        }
        return TextStyle(color: greyFocused);
      },
    ),

    // 🔹 Hint SIEMPRE gris oscuro
    hintStyle: TextStyle(color: greyHint),

    // 🔹 Texto del error en rojo
    errorStyle: const TextStyle(color: Colors.red),

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
  required DateTime fechaInicioEstadias,
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
  final List<EstadiaLocal> _estadias = []; // ✅ estadías en memoria (antes de guardar)


  // ---- Resultados ----
  int? _diasEjecutados;
  int? _totalCondenaDias;
  int? _diasCumplidos;
  int? _diasRestantes;
  double? _porcentajeCumplido;
  int? _diasFaltantesPrimerBeneficio;

  // // ---- Datos del acudiente ----
  final TextEditingController _acudienteNombresCtrl = TextEditingController();
  final TextEditingController _acudienteApellidosCtrl = TextEditingController();
  final TextEditingController _acudienteDocumentoCtrl = TextEditingController();
  final TextEditingController _acudienteCelularCtrl = TextEditingController();

  String? _acudienteParentescoSeleccionado;
  String? _acudienteTipoDocumentoSeleccionado;


  DateTime? _fechaInicioEstadias; // la más antigua
  int _diasEjecutadosPorEstadias = 0;


  final TextEditingController _centroCtrl = TextEditingController();
  final FocusNode _centroFocus = FocusNode();

// opcional: cache del centro seleccionado completo
  Map<String, dynamic>? _centroSeleccionado;




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
  List<Map<String, dynamic>> centrosReclusionTodos = [];
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

  //ESTO SE USABA CON LA BD ANTIGUA
  // Future<void> _calcularDesdeEstadias(String pplId) async {
  //   final snap = await FirebaseFirestore.instance
  //       .collection('Ppl')
  //       .doc(pplId)
  //       .collection('estadias')
  //       .get();
  //
  //   if (snap.docs.isEmpty) {
  //     setState(() {
  //       _fechaInicioEstadias = null;
  //       _diasEjecutadosPorEstadias = 0;
  //     });
  //     return;
  //   }
  //
  //   DateTime? fechaMasAntigua;
  //   int totalDias = 0;
  //   final ahora = DateTime.now();
  //
  //   for (final doc in snap.docs) {
  //     final data = doc.data();
  //     final inicio = (data['fecha_ingreso'] as Timestamp).toDate();
  //     final fin = data['fecha_salida'] != null
  //         ? (data['fecha_salida'] as Timestamp).toDate()
  //         : ahora;
  //
  //     // fecha más antigua
  //     if (fechaMasAntigua == null || inicio.isBefore(fechaMasAntigua)) {
  //       fechaMasAntigua = inicio;
  //     }
  //
  //     final dias = fin.difference(inicio).inDays;
  //     if (dias > 0) totalDias += dias;
  //   }
  //
  //   setState(() {
  //     _fechaInicioEstadias = fechaMasAntigua;
  //     _diasEjecutadosPorEstadias = totalDias;
  //   });
  // }
  //


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
    setState(() => _isLoadingCentros = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('centros_reclusion')
          .where('activo', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> fetched = [];

      for (final doc in querySnapshot.docs) {
        final raw = doc.data();
        final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
        if (data.isEmpty) continue;

        // ✅ En tu BD nueva NO es "nombre", es nombreCorto / nombreLargo
        final nombreCorto = (data['nombreCorto'] ?? '').toString().trim();
        final nombreLargo = (data['nombreLargo'] ?? '').toString().trim();

        final nombre = nombreCorto.isNotEmpty
            ? nombreCorto
            : (nombreLargo.isNotEmpty ? nombreLargo : '');

        if (nombre.isEmpty) {
          debugPrint("⚠️ Centro ${doc.id} sin nombreCorto/nombreLargo (se omite). Path: ${doc.reference.path}");
          continue;
        }

        // ✅ regional (en tu CatalogItem existe regionalNombre)
        final regional = (data['regionalNombre'] ?? data['regional'] ?? '').toString().trim();

        // ✅ correos seguros (tu BD nueva puede traer "correos" como map)
        Map<String, dynamic> correos = {};
        final rawCorreos = data['correos'];
        if (rawCorreos is Map) {
          correos = rawCorreos.map((k, v) => MapEntry(k.toString(), v));
        } else {
          correos = {
            'correo_direccion': (data['correo_direccion'] ?? '').toString(),
            'correo_juridica': (data['correo_juridica'] ?? '').toString(),
            'correo_principal': (data['correo_principal'] ?? '').toString(),
            'correo_sanidad': (data['correo_sanidad'] ?? '').toString(),
          };
        }

        fetched.add({
          'id': doc.id,
          'nombre': nombre,            // ✅ lo que usa tu Autocomplete hoy
          'nombreCorto': nombreCorto,  // opcional
          'nombreLargo': nombreLargo,  // opcional
          'regional': regional,        // ✅ lo que usas para mostrar y filtrar
          'correos': {
            'correo_direccion': (correos['correo_direccion'] ?? '').toString(),
            'correo_juridica': (correos['correo_juridica'] ?? '').toString(),
            'correo_principal': (correos['correo_principal'] ?? '').toString(),
            'correo_sanidad': (correos['correo_sanidad'] ?? '').toString(),
          },
        });
      }

      fetched.sort((a, b) {
        final aN = (a['nombre'] ?? '').toString().toLowerCase();
        final bN = (b['nombre'] ?? '').toString().toLowerCase();
        return aN.compareTo(bN);
      });

      if (!mounted) return;
      setState(() => centrosReclusionTodos = fetched);

      debugPrint("✅ Centros cargados (root centros_reclusion): ${centrosReclusionTodos.length}");
    } catch (e) {
      debugPrint("❌ Error al obtener centros de reclusión: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCentros = false);
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

    setState(() => _isLoadingConocimiento = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('juzgados')
          .get();

      final List<Map<String, String>> fetchedJuzgados = [];

      for (final doc in querySnapshot.docs) {
        // ✅ En Web: proteger doc.data()
        final raw = doc.data();
        final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

        // ✅ Si viene vacío o no trae 'nombre', lo saltamos
        final nombre = (data['nombre'] ?? '').toString().trim();
        if (nombre.isEmpty) continue;

        final ciudadId = doc.reference.parent.parent?.id ?? "";

        fetchedJuzgados.add({
          'id': doc.id,
          'nombre': nombre,
          'correo': (data['correo'] ?? '').toString().trim(),
          'ciudad': ciudadId,
        });
      }

      // ✅ ORDEN POR CIUDAD y luego por NOMBRE
      fetchedJuzgados.sort((a, b) {
        final ciudadA = (a['ciudad'] ?? '').toLowerCase().trim();
        final ciudadB = (b['ciudad'] ?? '').toLowerCase().trim();

        final cmpCiudad = ciudadA.compareTo(ciudadB);
        if (cmpCiudad != 0) return cmpCiudad;

        final nombreA = (a['nombre'] ?? '').toLowerCase().trim();
        final nombreB = (b['nombre'] ?? '').toLowerCase().trim();
        return nombreA.compareTo(nombreB);
      });

      if (!mounted) return;
      setState(() => juzgadosConocimiento = fetchedJuzgados);

      debugPrint("✅ Juzgados de conocimiento cargados correctamente.");
    } catch (e) {
      debugPrint("❌ Error al obtener los juzgados de conocimiento: $e");
    } finally {
      if (mounted) setState(() => _isLoadingConocimiento = false);
    }
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
    _centroCtrl.dispose();
    _centroFocus.dispose();
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
    _estadias.clear();

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

    if (_estadias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor registra al menos una estadía')),
      );
      return;
    }

    // ✅ Ahora es "fecha inicio estadías" (antes le decías fecha captura)
    final fechaInicioEstadias = _fechaCapturaDesdeEstadias();
    if (fechaInicioEstadias == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular la fecha de inicio desde estadías')),
      );
      return;
    }

    final int meses = int.tryParse(_mesesCtrl.text.trim()) ?? 0;
    final int diasCondena = int.tryParse(_diasCtrl.text.trim()) ?? 0;
    final int diasRedimidos = int.tryParse(_diasRedimidosCtrl.text.trim()) ?? 0;

    final int totalCondenaDias = (meses * 30) + diasCondena;

    int diasEjecutados = _diasEjecutadosDesdeEstadias();
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
        beneficiosCumplidosTemp.add(_BeneficioResumen(nombre, diferencia));
      }
    }

    evaluarBeneficio('Permiso administrativo de hasta 72 horas', 33.33);
    evaluarBeneficio('Prisión domiciliaria', 50.0);
    evaluarBeneficio('Libertad condicional', 60.0);
    evaluarBeneficio('Extinción de la pena', 100.0);

    int? diasFaltantesPrimerBeneficio;
    if (beneficiosCumplidosTemp.isEmpty && totalCondenaDias > 0) {
      final int diasUmbralPrimer = (totalCondenaDias * (33.33 / 100)).round();
      int faltan = diasUmbralPrimer - diasCumplidos;
      if (faltan < 0) faltan = 0;
      diasFaltantesPrimerBeneficio = faltan;
    }

    setState(() {
      // ✅ Guardamos estos dos para que luego "Guardar" no falle
      _fechaInicioEstadias = fechaInicioEstadias;
      _diasEjecutadosPorEstadias = diasEjecutados;

      _diasEjecutados = diasEjecutados;
      _totalCondenaDias = totalCondenaDias;
      _diasCumplidos = diasCumplidos;
      _diasRestantes = diasRestantes;
      _porcentajeCumplido = porcentajeCumplido;

      _beneficiosCumplidos = beneficiosCumplidosTemp;
      _diasFaltantesPrimerBeneficio = diasFaltantesPrimerBeneficio;
    });

    // ✅ Callback seguro (ya no usamos _fechaCaptura)
    if (widget.onValidated != null) {
      widget.onValidated!(
        totalCondenaDias: totalCondenaDias,
        diasEjecutados: diasEjecutados,
        diasRedimidos: diasRedimidos,
        diasCumplidos: diasCumplidos,
        diasRestantes: diasRestantes,
        porcentajeCumplido: porcentajeCumplido,
        fechaInicioEstadias: fechaInicioEstadias, // ✅ el local, no el state
      );
    }
  }

  Widget _autocompleteCentroReclusion() {
    return Autocomplete<Map<String, dynamic>>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<Map<String, dynamic>>.empty();

        return centrosReclusionTodos.where((c) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final regional = (c['regional'] ?? '').toString().toLowerCase();
          return nombre.contains(q) || regional.contains(q);
        });
      },

      displayStringForOption: (c) {
        final nombre = (c['nombre'] ?? '').toString();
        final regional = (c['regional'] ?? '').toString();
        return '$nombre ($regional)';
      },

      onSelected: (c) {
        setState(() {
          _centroSeleccionado = c;
          _centroReclusionSeleccionadoId = (c['id'] ?? '').toString();
        });
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // ✅ Si ya había uno seleccionado, muestra el texto en el input
        if (_centroSeleccionado != null && textController.text.isEmpty) {
          textController.text = '${_centroSeleccionado!['nombre']} (${_centroSeleccionado!['regional']})';
        }

        return TextFormField(
          controller: textController,     // ✅ CLAVE
          focusNode: focusNode,           // ✅ CLAVE
          decoration: _inputDecoration('Centro de reclusión')
              .copyWith(hintText: 'Escribe para buscar...'),

          onChanged: (_) {
            // ✅ Si el usuario cambia el texto manualmente, invalidamos selección previa
            if (_centroReclusionSeleccionadoId != null) {
              setState(() {
                _centroReclusionSeleccionadoId = null;
                _centroSeleccionado = null;
              });
            }
          },

          validator: (_) {
            if (_centroReclusionSeleccionadoId == null ||
                _centroReclusionSeleccionadoId!.isEmpty) {
              return 'Selecciona un centro de reclusión';
            }
            return null;
          },
        );
      },

      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 650),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final c = options.elementAt(index);
                  final nombre = (c['nombre'] ?? '').toString();
                  final regional = (c['regional'] ?? '').toString();

                  return ListTile(
                    dense: true,
                    title: Text(nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(regional, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => onSelected(c),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }


  void _resetResultados() {
    setState(() {
      _diasEjecutados = null;
      _totalCondenaDias = null;
      _diasCumplidos = null;
      _diasRestantes = null;
      _porcentajeCumplido = null;
      _diasFaltantesPrimerBeneficio = null;
      _beneficiosCumplidos = [];
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool hayResultados = _diasEjecutados != null &&
        _totalCondenaDias != null &&
        _diasCumplidos != null &&
        _diasRestantes != null &&
        _porcentajeCumplido != null;

    return Column(
      children: [
        Card(
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
                          _resetResultados();
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
                          onChanged: (_) => _resetResultados(),
                          validator: (_) {
                            if (_delitoSeleccionado?.nombre == 'Otro (escribir)' &&
                                _otroDelitoCtrl.text.trim().isEmpty) {
                              return 'Escribe el nombre del delito';
                            }
                            return null;
                          },
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
                              onChanged: (_) => _resetResultados(),
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
                              onChanged: (_) => _resetResultados(),
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

                      // ✅ ESTADÍAS (para piloto)
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.table_chart_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text('Estadías (Piloto)',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _agregarEstadiaDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar'),
                                ),
                              ],
                            ),

                            if (_estadias.isEmpty)
                              const Text('No hay estadías. Agrega al menos una para calcular.'),
                            if (_estadias.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 18,
                                  columns: const [
                                    DataColumn(label: Text('Tipo')),
                                    DataColumn(label: Text('Inicio')),
                                    DataColumn(label: Text('Terminación')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: List.generate(_estadias.length, (i) {
                                    final e = _estadias[i];
                                    final ingresoTxt = DateFormat('dd/MM/yyyy').format(e.ingreso);
                                    final salidaTxt = e.salida == null
                                        ? 'Actual'
                                        : DateFormat('dd/MM/yyyy').format(e.salida!);

                                    return DataRow(cells: [
                                      DataCell(Text(e.tipo)),
                                      DataCell(Text(ingresoTxt)),
                                      DataCell(Text(salidaTxt)),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                          onPressed: () => _eliminarEstadiaLocal(i),
                                        ),
                                      ),
                                    ]);
                                  }),
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Fecha captura (calculada): ${DateFormat('dd/MM/yyyy').format(_fechaCapturaDesdeEstadias()!)}',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ---- DÍAS REDIMIDOS ----
                      TextFormField(
                        controller: _diasRedimidosCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Días redimidos'),
                        onChanged: (_) => _resetResultados(),
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
                          dropdownColor: Colors.white,
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
                        _autocompleteCentroReclusion(),
                        const SizedBox(height: 12),



                        TextFormField(
                          controller: _tdCtrl,
                          decoration: _inputDecoration('TD'),
                          validator: (_) => null,

                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nuiCtrl,
                          decoration: _inputDecoration('NUI'),
                          validator: (_) => null,
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


                        // 🔹 Juzgado de ejecución de penas (DROP)
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
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
                          dropdownColor: Colors.white,
                          decoration: _inputDecoration('Juzgado de conocimiento'),
                          value: _juzgadoConocimientoSeleccionadoId,
                          isExpanded: true,
                          items: juzgadosConocimiento.map((j) {
                            final ciudad = j['ciudad'] ?? '';
                            final nombre = j['nombre'] ?? '';
                            return DropdownMenuItem<String>(
                              value: j['id'],
                              child: Text(
                                '${_capitalizar(ciudad)} - $nombre',
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
                              if (!_validarMinimosPreRegistro()) return;

                              if (_totalCondenaDias == null ||
                                  _diasCumplidos == null ||
                                  _porcentajeCumplido == null ||
                                  _fechaInicioEstadias == null ||
                                  _diasEjecutadosPorEstadias == 0 ||
                                  _diasRestantes == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Debes registrar al menos una estadía antes de guardar.'),
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
                                    backgroundColor: Colors.white,
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

                              final fechaInicio = _fechaInicioEstadias; // ya calculada en _calcular()
                              final estadiasMap = _estadiasToMap();

                              final payload = <String, dynamic>{
                                // ─── Identificación PPL ───
                                'nombres': _nombresCtrl.text.trim(),
                                'apellidos': _apellidosCtrl.text.trim(),
                                'tipo_documento': _tipoDocumentoSeleccionado,
                                'numero_documento': _numeroDocCtrl.text.trim(),

                                // ─── Datos penitenciarios ───
                                'td': _tdCtrl.text.trim(),
                                'nui': _nuiCtrl.text.trim(),
                                'patio': _patioCtrl.text.trim(),
                                'numero_proceso': _numeroProcesoCtrl.text.trim(),

                                // ─── Centro / juzgados (como antes) ───
                                'centro_reclusion_id': _centroReclusionSeleccionadoId,
                                'centro_reclusion_nombre': _buscarNombreCentroPorId(_centroReclusionSeleccionadoId),

                                'juzgado_ejecucion_id': _juzgadoEjecucionSeleccionadoId,
                                'juzgado_ejecucion_nombre': _buscarNombreJuzgadoEjecucionPorId(_juzgadoEjecucionSeleccionadoId),

                                'juzgado_conocimiento_id': _juzgadoConocimientoSeleccionadoId,
                                'juzgado_conocimiento_nombre': _buscarNombreJuzgadoConocimientoPorId(_juzgadoConocimientoSeleccionadoId),

                                // ─── Delito ───
                                'delito': _nombreDelitoElegido,
                                'delito_excluido_beneficios': _delitoEsExcluido,

                                // ✅ Condena total en plano (como el reporte lo espera)
                                'total_condena_dias': _totalCondenaDias,

                                // ✅ fecha_captura (calculada desde estadías pero guardada con el nombre viejo)
                                'fecha_captura': fechaInicio == null
                                    ? null
                                    : Timestamp.fromDate(_soloFecha(fechaInicio)),

                                // (Opcional) puedes guardar estadías para trazabilidad, sin afectar el reporte
                                'estadias': _estadiasToMap(),

                                // Contexto
                                'es_piloto': true,

                                // ─── Auditoría ───
                                'created_at': FieldValue.serverTimestamp(),
                                'updated_at': FieldValue.serverTimestamp(),
                              };

                              // Construimos el RESUMEN en meses/días
                              final buffer = StringBuffer();
                              buffer.writeln(
                                'Nombre: ${_nombresCtrl.text.trim()} ${_apellidosCtrl.text.trim()}',
                              );
                              buffer.writeln(
                                'Documento: ${_tipoDocumentoSeleccionado ?? '-'} ${_numeroDocCtrl.text.trim()}',
                              );
                              buffer.writeln(
                                'TD: ${_tdCtrl.text.trim().isEmpty ? '—' : _tdCtrl.text.trim()} · '
                                    'NUI: ${_nuiCtrl.text.trim().isEmpty ? '—' : _nuiCtrl.text.trim()}',
                              );
                              buffer.writeln(
                                'Delito: $_nombreDelitoElegido${_delitoEsExcluido ? ' (excluido de beneficios)' : ''}',
                              );

                              // ✅ Reemplazo de “fecha de captura”
                              buffer.writeln(
                                'Inicio de estadías: ${_fechaInicioEstadias == null
                                    ? '—'
                                    : _dateFormat.format(_fechaInicioEstadias!)}',
                              );

                              buffer.writeln(
                                'Días ejecutados (estadías): ${_formatearMesesDias(_diasEjecutadosPorEstadias)}',
                              );


                              buffer.writeln(
                                'Condena total: ${_formatearMesesDias(_totalCondenaDias!)}',
                              );
                              buffer.writeln(
                                'Días ejecutados (estadías): ${_formatearMesesDias(_diasEjecutados!)}',
                              );
                              buffer.writeln(
                                'Días redimidos: ${_formatearMesesDias(diasRedimidosInt)}',
                              );
                              buffer.writeln(
                                'Condena total cumplida: ${_formatearMesesDias(_diasCumplidos!)}',
                              );
                              buffer.writeln(
                                'Condena restante: ${_formatearMesesDias(_diasRestantes!)}',
                              );
                              buffer.writeln(
                                'Cumplido: ${_porcentajeCumplido!.toStringAsFixed(2)}%',
                              );


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
                                // await FirebaseFirestore.instance
                                //     .collection('analisis_condena_ppl')
                                //     .add(payload); para piloto

                                final firestore = FirebaseFirestore.instance;

                                // ✅ Un ID único para enlazar análisis + pre-registro
                                final String docId = firestore.collection('analisis_condena_ppl').doc().id;

                                // ✅ Doc refs
                                final analisisRef = firestore.collection('analisis_condena_ppl').doc(docId);
                                final preRegistroRef = firestore.collection('pre_registro_ppl').doc(docId);

                                if (_centroReclusionSeleccionadoId == null || _centroReclusionSeleccionadoId!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Selecciona el centro de reclusión.')),
                                  );
                                  return;
                                }
                                // ✅ Pre-registro payload (nuevo)
                                final preRegistroPayload = <String, dynamic>{
                                  'pre_registro_id': docId,

                                  // ===============================
                                  // PPL (mínimo necesario)
                                  // ===============================
                                  'ppl': {
                                    'nombres': _nombresCtrl.text.trim(),
                                    'apellidos': _apellidosCtrl.text.trim(),
                                    'tipo_documento': _tipoDocumentoSeleccionado,
                                    'numero_documento': _numeroDocCtrl.text.trim(),

                                    'td': _tdCtrl.text.trim(),
                                    'nui': _nuiCtrl.text.trim(),
                                    'patio': _patioCtrl.text.trim(),
                                    'numero_proceso': _numeroProcesoCtrl.text.trim(),

                                    'condena': {
                                      'meses': int.tryParse(_mesesCtrl.text.trim()) ?? 0,
                                      'dias': int.tryParse(_diasCtrl.text.trim()) ?? 0,
                                      'total_dias': _totalCondenaDias,
                                    },

                                    'delito': _nombreDelitoElegido,
                                    'delito_excluido_beneficios': _delitoEsExcluido,
                                  },

                                  // ===============================
                                  // Selecciones (Piloto)
                                  // ===============================
                                  'selecciones': {
                                    // ─── Centro de reclusión ───
                                    'centro_reclusion_id': _centroReclusionSeleccionadoId,
                                    'centro_reclusion_nombre':
                                    _buscarNombreCentroPorId(_centroReclusionSeleccionadoId),

                                    // ✅ MUY IMPORTANTE
                                    'centro_reclusion_regional':
                                    _buscarRegionalCentroPorId(_centroReclusionSeleccionadoId),

                                    // ✅ Correos del centro (para envíos)
                                    'centro_reclusion_correos':
                                    _buscarCorreosCentroPorId(_centroReclusionSeleccionadoId),

                                    // ─── Juzgado de ejecución ───
                                    'juzgado_ejecucion_id': _juzgadoEjecucionSeleccionadoId,
                                    'juzgado_ejecucion_nombre':
                                    _buscarNombreJuzgadoEjecucionPorId(_juzgadoEjecucionSeleccionadoId),

                                    // ─── Juzgado de conocimiento ───
                                    'juzgado_conocimiento_id': _juzgadoConocimientoSeleccionadoId,
                                    'juzgado_conocimiento_nombre':
                                    _buscarNombreJuzgadoConocimientoPorId(_juzgadoConocimientoSeleccionadoId),
                                  },


                                  // ✅ estadías también en pre-registro (para poder validar/mostrar sin ir al análisis)
                                  'estadias': _estadiasToMap(),
                                  'fecha_inicio_estadias': _fechaInicioEstadias == null
                                      ? null
                                      : Timestamp.fromDate(_soloFecha(_fechaInicioEstadias!)),

                                  // ===============================
                                  // Acudiente (OTP)
                                  // ===============================
                                  'acudiente': {
                                    'nombres': _acudienteNombresCtrl.text.trim(),
                                    'apellidos': _acudienteApellidosCtrl.text.trim(),
                                    'parentesco': _acudienteParentescoSeleccionado,
                                    'tipo_documento': _acudienteTipoDocumentoSeleccionado,
                                    'numero_documento': _acudienteDocumentoCtrl.text.trim(),
                                    'celular': _normalizarCelular(_acudienteCelularCtrl.text),
                                    'celular_raw': _acudienteCelularCtrl.text.trim(),
                                  },

                                  // ===============================
                                  // OTP
                                  // ===============================
                                  'otp': {
                                    'estado': 'pendiente',
                                    'verificado_en': null,
                                  },

                                  // ===============================
                                  // Relación con análisis
                                  // ===============================
                                  'analisis_condena_id': docId,

                                  // Contexto piloto
                                  'es_piloto': true,
                                  'fuente_calculo': 'estadias_piloto',

                                  // Auditoría
                                  'created_at': FieldValue.serverTimestamp(),
                                  'updated_at': FieldValue.serverTimestamp(),
                                };

                                try {
                                  final batch = firestore.batch();

                                  // ✅ 1) Guardar análisis (igual que antes, pero con docId fijo)
                                  batch.set(analisisRef, payload);

                                  // ✅ 2) Guardar pre-registro
                                  batch.set(preRegistroRef, preRegistroPayload);

                                  await batch.commit();

                                  if (!mounted) return;

                                  setState(() {
                                    _resumenGuardado = resumenTexto;
                                  });
                                  _limpiarFormulario();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Análisis y pre-registro guardados correctamente.')),
                                  );

                                  // ✅ (Opcional) Navegar a pantalla OTP y pasar docId + celular normalizado
                                  // Navigator.pushNamed(context, 'otp_page', arguments: {
                                  //   'pre_registro_id': docId,
                                  //   'celular': _normalizarCelular(_acudienteCelularCtrl.text),
                                  // });

                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al guardar: $e')),
                                  );
                                }


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
        ),
      ],
    );
  }


  bool _validarMinimosPreRegistro() {
    final nombres = _nombresCtrl.text.trim();
    final apellidos = _apellidosCtrl.text.trim();
    final tipoDoc = (_tipoDocumentoSeleccionado ?? '').trim();
    final numDoc = _numeroDocCtrl.text.trim();
    final centroId = (_centroReclusionSeleccionadoId ?? '').trim();

    if (nombres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombres es obligatorio.')),
      );
      return false;
    }

    if (apellidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apellidos es obligatorio.')),
      );
      return false;
    }

    if (tipoDoc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de documento.')),
      );
      return false;
    }

    if (numDoc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de documento es obligatorio.')),
      );
      return false;
    }

    if (centroId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el centro de reclusión.')),
      );
      return false;
    }

    return true;
  }


  List<Map<String, dynamic>> _estadiasToMap() {
    return _estadias.map((e) {
      return {
        'tipo': e.tipo, // Reclusión | Domiciliaria | Condicional
        'fecha_ingreso': Timestamp.fromDate(_soloFecha(e.ingreso)),
        'fecha_salida': e.salida == null ? null : Timestamp.fromDate(_soloFecha(e.salida!)),
        'es_actual': e.salida == null,
      };
    }).toList();
  }



  Future<void> _agregarEstadiaDialog() async {
    String tipo = 'Reclusión';
    DateTime? ingreso;
    DateTime? salida;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Agregar estadía'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tipo,
                    items: const ['Reclusión', 'Domiciliaria', 'Condicional']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setStateSB(() => tipo = v ?? 'Reclusión'),
                    decoration: _inputDecoration('Tipo'),
                  ),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: ingreso ?? DateTime.now(),
                        firstDate: DateTime(1990),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setStateSB(() => ingreso = _soloFecha(picked));
                    },
                    child: Text(
                      ingreso == null
                          ? 'Seleccionar ingreso'
                          : 'Ingreso: ${DateFormat('dd/MM/yyyy').format(ingreso!)}',
                    ),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: ingreso == null
                        ? null
                        : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: salida ?? ingreso!,
                        firstDate: ingreso!,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setStateSB(() => salida = _soloFecha(picked));
                    },
                    child: Text(
                      salida == null
                          ? 'Salida: Actual'
                          : 'Salida: ${DateFormat('dd/MM/yyyy').format(salida!)}',
                    ),
                  ),

                  if (salida != null) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => setStateSB(() => salida = null),
                      icon: const Icon(Icons.clear, size: 18, color: Colors.red),
                      label: const Text('Quitar salida (dejar Actual)',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ingreso == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La fecha de ingreso es obligatoria')),
                  );
                  return;
                }

                // Validación: salida no antes que ingreso
                if (salida != null && salida!.isBefore(ingreso!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La salida no puede ser anterior al ingreso')),
                  );
                  return;
                }

                // Validación: solapes contra lo ya agregado
                final nuevoIni = ingreso!;
                final nuevoFin = salida ?? DateTime.now();

                for (final e in _estadias) {
                  final eIni = e.ingreso;
                  final eFin = e.salida ?? DateTime.now();
                  if (_seSolapan(nuevoIni, nuevoFin, eIni, eFin)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Esta estadía se cruza con otra entre '
                              '${DateFormat('dd/MM/yyyy').format(eIni)} y ${DateFormat('dd/MM/yyyy').format(eFin)}',
                        ),
                      ),
                    );
                    return;
                  }
                }

                setState(() {
                  _estadias.add(EstadiaLocal(tipo: tipo, ingreso: ingreso!, salida: salida));
                  // Ordenar desc por ingreso para tabla bonita
                  _estadias.sort((a, b) => b.ingreso.compareTo(a.ingreso));
                });

                _resetResultados();
                Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarEstadiaLocal(int index) {
    setState(() {
      _estadias.removeAt(index);
    });
    _resetResultados();
  }

  DateTime? _fechaCapturaDesdeEstadias() {
    if (_estadias.isEmpty) return null;
    final minIngreso = _estadias.map((e) => e.ingreso).reduce((a, b) => a.isBefore(b) ? a : b);
    return _soloFecha(minIngreso);
  }

  int _diasEjecutadosDesdeEstadias() {
    if (_estadias.isEmpty) return 0;
    final now = DateTime.now();

    int total = 0;
    for (final e in _estadias) {
      final ini = _soloFecha(e.ingreso);
      final fin = _soloFecha(e.salida ?? now);

      final d = fin.difference(ini).inDays;
      if (d > 0) total += d;
    }
    return total;
  }

  // nuevo para prueba piloto base datos
  String _normalizarCelular(String raw) {
    var s = raw.trim();

    // deja solo dígitos
    s = s.replaceAll(RegExp(r'[^0-9]'), '');

    // si viene con 57 (ej: 573001112233) lo quitamos
    if (s.startsWith('57') && s.length >= 12) {
      s = s.substring(2);
    }

    // te queda 10 dígitos en Colombia
    return s;
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1).toLowerCase();
  }

  //******************

  Map<String, dynamic>? _buscarCentroPorId(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return centrosReclusionTodos.firstWhere((c) => (c['id'] ?? '').toString() == id);
    } catch (_) {
      return null;
    }
  }

  String? _buscarNombreCentroPorId(String? id) {
    final c = _buscarCentroPorId(id);
    return c == null ? null : (c['nombre'] ?? '').toString();
  }

  String? _buscarRegionalCentroPorId(String? id) {
    final c = _buscarCentroPorId(id);
    return c == null ? null : (c['regional'] ?? '').toString();
  }

  Map<String, dynamic> _buscarCorreosCentroPorId(String? id) {
    final c = _buscarCentroPorId(id);
    final correos = c == null ? null : c['correos'];
    if (correos is Map<String, dynamic>) return correos;
    if (correos is Map) return correos.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  /////***********************

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

class EstadiaLocal {
  String tipo; // Reclusión | Domiciliaria | Condicional
  DateTime ingreso;
  DateTime? salida;

  EstadiaLocal({
    required this.tipo,
    required this.ingreso,
    this.salida,
  });
}

bool _seSolapan(DateTime aIni, DateTime aFin, DateTime bIni, DateTime bFin) {
  return aIni.isBefore(bFin) && aFin.isAfter(bIni);
}

DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);




