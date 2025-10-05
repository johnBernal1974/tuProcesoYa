import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../../../commons/main_layaout.dart'; // usa tu MainLayout

/// Página unificada para ver TODAS las solicitudes de servicio
class TodasLasSolicitudesAdminPage extends StatefulWidget {
  const TodasLasSolicitudesAdminPage({super.key});

  @override
  State<TodasLasSolicitudesAdminPage> createState() => _TodasLasSolicitudesAdminPageState();
}

class _TodasLasSolicitudesAdminPageState extends State<TodasLasSolicitudesAdminPage> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// Filtro de estado
  String _filtroEstado = 'Solicitado';
  String _filtroServicio = 'Todos';


  /// Configuración de colecciones -> etiqueta y carpeta
  final List<_FuenteColeccion> _fuentes = const [
    _FuenteColeccion(collection: 'domiciliaria_solicitados',         tipoServicio: 'Prisión Domiciliaria',       pathStorage: 'domiciliaria'),
    _FuenteColeccion(collection: 'redenciones_solicitados',          tipoServicio: 'Cómputo de Redención',       pathStorage: 'redenciones'),
    _FuenteColeccion(collection: 'readecuacion_solicitados',         tipoServicio: 'Readecuación de Redención',  pathStorage: 'readecuacion'),
    _FuenteColeccion(collection: 'permiso_solicitados',              tipoServicio: 'Permiso 72 horas',           pathStorage: 'permiso'),
    _FuenteColeccion(collection: 'apelacion_solicitados',            tipoServicio: 'Recurso de apelación',       pathStorage: 'apelacion'),
    _FuenteColeccion(collection: 'desistimiento_apelacion_solicitados', tipoServicio: 'Desistimiento de apelación',       pathStorage: 'desistimientoApelacion'),
    _FuenteColeccion(collection: 'asignacionJEP_solicitados',        tipoServicio: 'Asignación JEP',             pathStorage: 'asignacionJEP'),
    _FuenteColeccion(collection: 'acumulacion_solicitados',          tipoServicio: 'Acumulación de penas',       pathStorage: 'acumulacion'),
    _FuenteColeccion(collection: 'condicional_solicitados',          tipoServicio: 'Libertad condicional',       pathStorage: 'condicional'),
    _FuenteColeccion(collection: 'copiaSentencia_solicitados',       tipoServicio: 'Copia de sentencia',         pathStorage: 'copiaSentencia'),
    _FuenteColeccion(collection: 'derechos_peticion_solicitados',    tipoServicio: 'Derecho de petición',        pathStorage: 'derechos_peticion'),
    _FuenteColeccion(collection: 'trasladoProceso_solicitados',      tipoServicio: 'Traslado de proceso',        pathStorage: 'trasladoProceso'),
  ];

  /// Estados que van a la vista de resultado
  static const Set<String> _estadosResultado = {'Enviado','Concedido','Negado'};

  /// Rutas por colección (ajusta si tus nombres son distintos)
  static const Map<String, Map<String, String>> _rutasPorColeccion = {
    'domiciliaria_solicitados': {
      'atender':  'atender_solicitud_prision_domiciliaria_page',
      'resultado':'solicitudes_prision_domiciliaria_enviadas_por_correo',
    },
    'redenciones_solicitados': {
      'atender':  'atender_redencion_page',
      'resultado':'solicitudes_redencion_enviadas_por_correo',
    },
    'readecuacion_solicitados': {
      'atender':  'atender_readecuacion_page',
      'resultado':'solicitudes_readecuacion_redencion_enviadas_por_correo',
    },
    'permiso_solicitados': {
      'atender':  'atender_solicitud_permiso_72_horas_page',
      'resultado':'solicitudes_permiso_72_horas_enviadas_por_correo',
    },
    'apelacion_solicitados': {
      'atender':  'atender_apelacion_page',
      'resultado':'solicitudes_apelacion_enviadas_por_correo',
    },
    'desistimiento_apelacion_solicitados': {
      'atender':  'atender_desistimiento_apelacion_page',
      'resultado':'desistimiento_enviados_por_correo',
    },
    'asignacionJEP_solicitados': {
      'atender':  'atender_asignacion_jep_page',
      'resultado':'solicitudes_asignacionJEP_por_correo',
    },
    'acumulacion_solicitados': {
      'atender':  'atender_acumulacion_page',
      'resultado':'solicitudes_acumulacion_enviadas_por_correo',
    },
    'condicional_solicitados': {
      'atender':  'atender_solicitud_libertad_condicional_page',
      'resultado':'solicitudes_libertad_condicional_enviadas_por_correo',
    },
    'copiaSentencia_solicitados': {
      'atender':  'atender_copiaSentencia_page',
      'resultado':'solicitudes_copiaSentencia_por_correo',
    },
    'derechos_peticion_solicitados': {
      'atender':  'atender_derecho_peticion_page',
      'resultado':'derechos_peticion_enviados_por_correo',
    },
    'trasladoProceso_solicitados': {
      'atender':  'atender_traslado_proceso_page',
      'resultado':'solicitudes_traslado_proceso_enviadas_por_correo',
    },
  };

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Todas las solicitudes',
      content: SizedBox(
        width: MediaQuery.of(context).size.width >= 800 ? 1000 : double.infinity,
        child: StreamBuilder<List<List<QueryDocumentSnapshot<Map<String, dynamic>>>>>(
          stream: _combinedSnapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final listas = snapshot.data ?? [];
            final todosDocs = listas.expand((l) => l).toList();

            final items = todosDocs
                .map((doc) => _mapDocToItem(doc))
                .where((e) => e != null)
                .cast<SolicitudItem>()
                .toList()
              ..sort((a, b) => b.fecha.compareTo(a.fecha));

            if (items.isEmpty) {
              return const Center(child: Text('No hay solicitudes.'));
            }

            // Conteos por estado (global)
            final counts = <String, int>{
              'Solicitado': 0,'Diligenciado': 0,'Revisado': 0,
              'Enviado': 0,'Concedido': 0,'Negado': 0,
            };
            for (final it in items) {
              counts[it.status] = (counts[it.status] ?? 0) + 1;
            }

            // Servicios y conteos
            final serviciosSet = <String>{'Todos'}..addAll(items.map((e) => e.tipoServicio));
            final servicios = serviciosSet.toList()
              ..sort((a, b) {
                if (a == 'Todos') return -1;
                if (b == 'Todos') return 1;
                return a.toLowerCase().compareTo(b.toLowerCase());
              });

            final countsServicios = <String, int>{};
            for (final it in items) {
              countsServicios[it.tipoServicio] = (countsServicios[it.tipoServicio] ?? 0) + 1;
            }
            countsServicios['Todos'] = items.length;

            // 👉 Mostrar/ocultar filtro de estado según servicio
            final bool showEstado = _filtroServicio == 'Todos';

            // Filtro combinado: si servicio ≠ "Todos", se ignora estado
            final filtrados = items.where((e) {
              final okServicio = _filtroServicio == 'Todos' || e.tipoServicio == _filtroServicio;
              final okEstado = showEstado ? e.status == _filtroEstado : true;
              return okServicio && okEstado;
            }).toList();

            // Orden por días desde fechaEnvio
            int _diasDesdeEnvio(SolicitudItem it) {
              if (it.fechaEnvio == null) return -1;
              return DateTime.now().difference(it.fechaEnvio!).inDays;
            }
            filtrados.sort((a, b) => _diasDesdeEnvio(b).compareTo(_diasDesdeEnvio(a)));

            return Column(
              children: [
                const SizedBox(height: 8),

                // Chips de ESTADO: solo si servicio == "Todos"
                if (showEstado)
                  _EstadoChips(
                    selected: _filtroEstado,
                    counts: counts,
                    onSelected: (estado) => setState(() => _filtroEstado = estado),
                  ),

                const Divider(height: 16),

                // Barra de filtros
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // BOTÓN TIPO SERVICIO
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Colors.deepPurple.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.deepPurple, width: 1),
                        ),
                      ),
                      icon: const Icon(Icons.category, color: Colors.deepPurple),
                      label: const Text(
                        'Tipo servicio',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () async {
                        final seleccionado = await showMenu<String>(
                          context: context,
                          position: const RelativeRect.fromLTRB(100, 100, 100, 100),
                          items: servicios.map((s) {
                            return PopupMenuItem<String>(
                              value: s,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(child: Text(s, overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${countsServicios[s] ?? 0})',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );

                        if (seleccionado != null) {
                          setState(() {
                            _filtroServicio = seleccionado;
                            // Si es un servicio específico, resetea el estado
                            if (seleccionado != 'Todos') _filtroEstado = 'Solicitado';
                          });
                        }
                      },
                    ),

                    // BOTÓN ESTADO (solo si es "Todos")
                    if (_filtroServicio == 'Todos')
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: Colors.deepPurple.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.deepPurple, width: 1),
                          ),
                        ),
                        icon: const Icon(Icons.filter_list, color: Colors.deepPurple),
                        label: const Text(
                          'Estado',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          final seleccionado = await showMenu<String>(
                            context: context,
                            position: const RelativeRect.fromLTRB(100, 100, 100, 100),
                            items: const [
                              PopupMenuItem(value: 'Solicitado', child: Text('Solicitado')),
                              PopupMenuItem(value: 'Diligenciado', child: Text('Diligenciado')),
                              PopupMenuItem(value: 'Revisado', child: Text('Revisado')),
                              PopupMenuItem(value: 'Enviado', child: Text('Enviado')),
                              PopupMenuItem(value: 'Concedido', child: Text('Concedido')),
                              PopupMenuItem(value: 'Negado', child: Text('Negado')),
                            ],
                          );

                          if (seleccionado != null) {
                            setState(() {
                              _filtroEstado = seleccionado;
                            });
                          }
                        },
                      ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) => _SolicitudCard(
                      item: filtrados[i],
                      onTap: () => _navegar(item: filtrados[i]),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Combina en vivo los snapshots de todas las colecciones listadas
  Stream<List<List<QueryDocumentSnapshot<Map<String, dynamic>>>>> _combinedSnapshots() {
    final streams = _fuentes
        .map((f) => _fs
        .collection(f.collection)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs))
        .toList();
    return CombineLatestStream.list(streams);
  }

  SolicitudItem? _mapDocToItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      final fuente = _fuentes.firstWhere((f) => f.collection == doc.reference.parent.id);

      DateTime? _tsToDate(dynamic v) =>
          v is Timestamp ? v.toDate() : null;

      final ts = data['fecha'] as Timestamp?;
      final fecha = ts?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);

      // Acudiente (variantes)
      final nombreAc = (data['nombre_acudiente'] ??
          data['nombreAcudiente'] ??
          data['acudienteNombre'] ??
          '').toString().trim();
      final apellidoAc = (data['apellido_acudiente'] ??
          data['apellidoAcudiente'] ??
          data['acudienteApellido'] ??
          '').toString().trim();
      final acudienteFull = [nombreAc, apellidoAc].where((s) => s.isNotEmpty).join(' ');

      // ⬇️ Campos de flujo (tolerantes a nombres alternativos)
      final fechaDilig = _tsToDate(data['fecha_diligenciamiento'] ?? data['fechaDiligenciamiento']);
      final diligencio = (data['diligencio'] ?? data['diligenciadoPor'] ?? data['diligencio_por'] ?? '').toString().trim();

      final fechaRev = _tsToDate(data['fecha_revision'] ?? data['fechaRevision']);
      final reviso = (data['reviso'] ?? data['revisadoPor'] ?? data['reviso_por'] ?? '').toString().trim();

      final fechaEnv = _tsToDate(data['fechaEnvio'] ?? data['fecha_envio']);
      final envioPor = (data['envió'] ?? data['envio'] ?? data['enviadoPor'] ?? data['envio_por'] ?? '').toString().trim();

      return SolicitudItem(
        idDocumento: doc.id,
        collection: fuente.collection,
        tipoServicio: fuente.tipoServicio,
        status: (data['status'] ?? 'Solicitado') as String,
        fecha: fecha,
        numeroSeguimiento: (data['numero_seguimiento'] ?? data['numeroSeguimiento'] ?? '-') as String,
        idUser: (data['idUser'] ?? '') as String,
        acudienteNombre: acudienteFull,

        fechaDiligenciamiento: fechaDilig,
        diligenciadoPor: diligencio.isEmpty ? null : diligencio,
        fechaRevision: fechaRev,
        revisadoPor: reviso.isEmpty ? null : reviso,
        fechaEnvio: fechaEnv,
        enviadoPor: envioPor.isEmpty ? null : envioPor,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error mapeando doc ${doc.id}: $e');
      return null;
    }
  }


  Future<void> _navegar({required SolicitudItem item}) async {
    final ruta = _rutaAtender(item);
    if (ruta.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta no configurada para este tipo de solicitud.')),
        );
      }
      return;
    }

    if (!mounted) return;
    try {
      Navigator.pushNamed(
        context,
        ruta,
        arguments: {
          'status': item.status,
          'idDocumento': item.idDocumento,
          'numeroSeguimiento': item.numeroSeguimiento,
          'categoria': 'Solicitudes',
          'subcategoria': item.tipoServicio,
          'fecha': item.fecha.toIso8601String(),
          'idUser': item.idUser,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo navegar a $ruta: $e')),
        );
      }
    }
  }

  String _rutaAtender(SolicitudItem item) {
    final rutas = _rutasPorColeccion[item.collection];
    if (rutas == null) return 'atender_generico_page';

    final esResultado = _estadosResultado.contains(item.status);
    return esResultado
        ? (rutas['resultado'] ?? 'atender_generico_page')
        : (rutas['atender']   ?? 'atender_generico_page');
  }
}

/// Modelo unificado para renderizar tarjetas
class SolicitudItem {
  final String idDocumento;
  final String collection;
  final String tipoServicio;
  final String status;
  final DateTime fecha;
  final String numeroSeguimiento;
  final String idUser;
  final String acudienteNombre;

  // ⬇️ Nuevos (opcionales)
  final DateTime? fechaDiligenciamiento;
  final String? diligenciadoPor;
  final DateTime? fechaRevision;
  final String? revisadoPor;
  final DateTime? fechaEnvio;
  final String? enviadoPor;

  SolicitudItem({
    required this.idDocumento,
    required this.collection,
    required this.tipoServicio,
    required this.status,
    required this.fecha,
    required this.numeroSeguimiento,
    required this.idUser,
    required this.acudienteNombre,
    this.fechaDiligenciamiento,
    this.diligenciadoPor,
    this.fechaRevision,
    this.revisadoPor,
    this.fechaEnvio,
    this.enviadoPor,
  });
}


class _FuenteColeccion {
  final String collection;
  final String tipoServicio;
  final String pathStorage;
  const _FuenteColeccion({
    required this.collection,
    required this.tipoServicio,
    required this.pathStorage,
  });
}

/// Tarjeta UI
class _SolicitudCard extends StatelessWidget {
  final SolicitudItem item;
  final VoidCallback onTap;
  const _SolicitudCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;

    final tieneEnvio = item.fechaEnvio != null;
    final int dias = tieneEnvio ? DateTime.now().difference(item.fechaEnvio!).inDays : 0;
    final Color colorDias = _colorPorDias(dias);
    final String txtDias = !tieneEnvio ? '' : (dias == 0 ? 'Hoy' : 'Hace $dias día${dias == 1 ? '' : 's'}');

    final fechaEnvioChip = tieneEnvio
        ? _chipDato('Fecha envío', _fmt(item.fechaEnvio), bg: Colors.green.withOpacity(.08))
        : const SizedBox();

    final diasChip = tieneEnvio
        ? Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: colorDias, borderRadius: BorderRadius.circular(10)),
      child: Text(
        txtDias,
        style: TextStyle(
          fontSize: isMobile ? 14 : 16,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    )
        : const SizedBox();

    final envioPorChip = (item.enviadoPor ?? '').isNotEmpty
        ? _chipDato('Envió', item.enviadoPor!, bg: Colors.grey.shade200)
        : const SizedBox();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 4,
        surfaceTintColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isMobile ? _buildMobile(fechaEnvioChip, diasChip, envioPorChip) : _buildDesktop(fechaEnvioChip, diasChip, envioPorChip),
        ),
      ),
    );
  }

  // ====================== DESKTOP/TABLET ======================
  Widget _buildDesktop(Widget fechaEnvioChip, Widget diasChip, Widget envioPorChip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Servicio | Fecha envío | Status
        Row(
          children: [
            _pill(item.tipoServicio, Colors.grey.shade200, Colors.black87),
            const Spacer(),
            fechaEnvioChip,
            const Spacer(),
            _pill(item.status, _estadoColor(item.status).withOpacity(.15), _estadoColor(item.status)),
          ],
        ),
        const SizedBox(height: 12),

        // Cuerpo: Izq datos / Der días + Envió
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _datosPplAcudiente()),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (diasChip is! SizedBox) diasChip,
                const SizedBox(height: 8),
                if (envioPorChip is! SizedBox) envioPorChip,
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ====================== MÓVIL ======================
  Widget _buildMobile(Widget fechaEnvioChip, Widget diasChip, Widget envioPorChip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header móvil: Servicio | Status (misma fila) y debajo Fecha envío
        Row(
          children: [
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _pill(_tipoServicioTexto, Colors.grey.shade200, Colors.black87))),
            const SizedBox(width: 8),
            FittedBox(fit: BoxFit.scaleDown, child: _pill(_statusTexto, _estadoColor(_statusTexto).withOpacity(.15), _estadoColor(_statusTexto))),
          ],
        ),
        const SizedBox(height: 6),
        if (fechaEnvioChip is! SizedBox) FittedBox(fit: BoxFit.scaleDown, child: fechaEnvioChip),

        const SizedBox(height: 10),

        // Cuerpo móvil: datos en bloque + fila con días y "Envió"
        _datosPplAcudiente(isMobile: true),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (diasChip is! SizedBox) diasChip,
            if (envioPorChip is! SizedBox) envioPorChip,
          ],
        ),
      ],
    );
  }

  // --------- Datos PPL / Acudiente (con fallback) ----------
  Widget _datosPplAcudiente({bool isMobile = false}) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('Ppl').doc(_idUser).get(),
      builder: (context, snap) {
        String ppl = '—';
        String acud = _acudienteNombre.isEmpty ? '—' : _acudienteNombre;

        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data();
          final nP = (d?['nombre_ppl'] ?? '').toString().trim();
          final aP = (d?['apellido_ppl'] ?? '').toString().trim();
          final pplFull = [nP, aP].where((s) => s.isNotEmpty).join(' ');
          if (pplFull.isNotEmpty) ppl = pplFull;

          if (acud == '—') {
            final nA = (d?['nombre_acudiente'] ?? d?['nombreAcudiente'] ?? '').toString().trim();
            final aA = (d?['apellido_acudiente'] ?? d?['apellidoAcudiente'] ?? '').toString().trim();
            final acFull = [nA, aA].where((s) => s.isNotEmpty).join(' ');
            if (acFull.isNotEmpty) acud = acFull;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('PPL', ppl, isBold: true, small: isMobile),
            const SizedBox(height: 6),
            _row('Acudiente', acud, small: isMobile),
            const SizedBox(height: 6),
            _row('No. Seguimiento', _numeroSeguimiento, isBold: true, small: isMobile),
            const SizedBox(height: 6),
            _row('Fecha solicitud', _fmt(_fecha), small: isMobile),
          ],
        );
      },
    );
  }

  // ====== helpers / estilos =====================================================

  // Estos getters te permiten usar los campos del item sin ensuciar el layout:
  String get _tipoServicioTexto => item.tipoServicio;
  String get _statusTexto => item.status;
  String get _numeroSeguimiento => item.numeroSeguimiento;
  String get _acudienteNombre => item.acudienteNombre;
  String get _idUser => item.idUser;
  DateTime get _fecha => item.fecha;

  Color _estadoColor(String s) {
    switch (s) {
      case 'Solicitado':   return Colors.brown;
      case 'Diligenciado': return Colors.amber.shade800;
      case 'Revisado':     return Colors.deepPurple;
      case 'Enviado':      return Colors.blue;
      case 'Concedido':    return Colors.green;
      case 'Negado':       return Colors.red;
      default:             return Colors.grey;
    }
  }

  Color _colorPorDias(int dias) {
    if (dias <= 8)  return Colors.green.withOpacity(.85);
    if (dias <= 17) return Colors.amber.withOpacity(.95);
    if (dias <= 26) return Colors.orange.withOpacity(.90);
    return Colors.red.withOpacity(.95);
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return DateFormat("dd 'de' MMMM 'de' yyyy - hh:mm a", 'es').format(d);
  }

  Widget _row(String label, String value, {bool isBold = false, bool small = false}) {
    final fsLabel = small ? 10.0 : 12.0;
    final fsValue = small ? 12.0 : 13.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: small ? 105 : 120,
          child: Text('$label:', style: TextStyle(fontSize: fsLabel, fontWeight: FontWeight.w600, height: .9)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: fsValue, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400, height: .9),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _chipDato(String titulo, String valor, {Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: (bg ?? Colors.grey.shade100), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$titulo: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          Text(valor.isEmpty ? '—' : valor, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}


/// Chips de conteo por estado
class _EstadoChips extends StatelessWidget {
  final Map<String, int> counts;
  final String selected;
  final ValueChanged<String> onSelected;
  const _EstadoChips({required this.counts, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final estados = ['Solicitado','Diligenciado','Revisado','Enviado','Concedido','Negado'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: estados.map((e){
          final sel = selected == e;
          final color = _estadoColor(e);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: sel,
              onSelected: (_)=> onSelected(e),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: sel ? Colors.white : color.withOpacity(.15),
                    child: Text('${counts[e] ?? 0}', style: TextStyle(fontSize: 11, color: sel ? Colors.black : color)),
                  )
                ],
              ),
              selectedColor: color.withOpacity(.25),
              backgroundColor: Colors.grey.shade100,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              shape: StadiumBorder(side: BorderSide(color: sel ? color : Colors.grey.shade300)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _estadoColor(String s) {
    switch (s) {
      case 'Solicitado':   return Colors.brown;
      case 'Diligenciado': return Colors.amber.shade800;
      case 'Revisado':     return Colors.deepPurple;
      case 'Enviado':      return Colors.blue;
      case 'Concedido':    return Colors.green;
      case 'Negado':       return Colors.red;
      default:             return Colors.grey;
    }
  }
}
