import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/Pages/administrador/atender_derecho_peticion_admin/atender_derecho_peticionAdmin_controler.dart';
import 'package:tuprocesoya/providers/ppl_provider.dart';
import '../../../commons/archivoViewerWeb.dart';
import '../../../commons/main_layaout.dart';
import '../../../models/ppl.dart';
import '../../../plantillas/plantilla_derecho_peticion.dart';
import '../../../src/colors/colors.dart';

class AtenderDerechoPeticionPage extends StatefulWidget {
  final String numeroSeguimiento;
  final String categoria;
  final String subcategoria;
  final String fecha;
  final String idUser;
  final List<dynamic> archivos; // Lista de archivos
  final List<String> respuestas; // Lista de respuestas
  final List<String> preguntas; // Lista de respuestas

  const AtenderDerechoPeticionPage({
    super.key,
    required this.numeroSeguimiento,
    required this.categoria,
    required this.subcategoria,
    required this.fecha,
    required this.idUser,
    required this.archivos,
    required this.respuestas,
    required this.preguntas,// Nuevo parámetro agregado
  });

  @override
  State<AtenderDerechoPeticionPage> createState() => _AtenderDerechoPeticionPageState();
}


class _AtenderDerechoPeticionPageState extends State<AtenderDerechoPeticionPage> {
  late PplProvider _pplProvider;
  Ppl? userData;
  bool isLoading = true; // Bandera para controlar la carga
  int diasEjecutado = 0;
  int mesesEjecutado = 0;
  int diasEjecutadoExactos = 0;

  int diasRestante = 0;
  int mesesRestante = 0;
  int diasRestanteExactos = 0;
  double porcentajeEjecutado =0;
  int tiempoCondena =0;

  List<String> archivos = [];

  bool _expandido = false;
  final TextEditingController _textoPrincipalController = TextEditingController();
  final TextEditingController _textoRazonesController = TextEditingController();
  final AtenderDerechoPeticionAdminController _controller = AtenderDerechoPeticionAdminController();
  int _maxLines = 1; // Empieza con 1 línea

  String textoPrincipal = "";
  String razonesPeticion = "";
  bool _mostrarVistaPrevia = false;
  bool _mostrarBotonVistaPrevia = false;





  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pplProvider = PplProvider();
    archivos = List<String>.from(widget.archivos); // Copia los archivos una vez
    fetchUserData();
    calcularTiempo(widget.idUser);
    _textoPrincipalController.addListener(_actualizarAltura);
    _textoRazonesController.addListener(_actualizarAltura);
  }

  void _actualizarAltura() {
    int lineas = '\n'.allMatches(_textoPrincipalController.text).length + 1;
    setState(() {
      _maxLines = lineas > 5 ? 5 : lineas; // Limita el crecimiento a 5 líneas
    });
  }

  void _guardarDatosEnVariables() {
    if (_textoPrincipalController.text.isEmpty || _textoRazonesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Todos los campos deben estar llenos."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      _mostrarBotonVistaPrevia = false;
      _mostrarVistaPrevia = false;
      return; // Detiene la ejecución si hay campos vacíos
    }

    setState(() {
      textoPrincipal = _textoPrincipalController.text;
      razonesPeticion = _textoRazonesController.text;
    });
    _mostrarBotonVistaPrevia = true;

    print("📌 Texto principal: $textoPrincipal");
    print("📌 Razones de petición: $razonesPeticion");
  }


  @override
  void dispose() {
    _textoPrincipalController.removeListener(_actualizarAltura);
    _textoRazonesController.removeListener(_actualizarAltura);
    _textoPrincipalController.dispose();
    _textoRazonesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Atender derecho de petición',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? 1500 : double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800; // Si es PC/tablet grande

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                      // 🖥️ En PC: Mostrar en fila
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildMainContent()),
                            const SizedBox(width: 50),
                            Expanded(flex: 2, child: _buildExtraWidget()),
                          ],
                        )
                      else
                      // 📱 En móvil: Mostrar en columna
                        Column(
                          children: [
                            _buildMainContent(),
                            const SizedBox(height: 20),
                            _buildExtraWidget(),
                            const SizedBox(height: 20),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🖥️📱 Widget de contenido principal (sección izquierda en PC)
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFechaHoy(),
        const SizedBox(height: 10),
        const Text("Derecho de petición", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
        _buildSolicitanteInfo(),
        const SizedBox(height: 15),
        _buildDetallesSolicitud(),
        const SizedBox(height: 20),
        _buildSolicitudTexto(),
        const SizedBox(height: 30),
        const Row(
          children: [
            Icon(Icons.attach_file),
            Text("Archivos adjuntos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 30),

        /// 📂 **Mostramos los archivos aquí**
        archivos != null && archivos.isNotEmpty
            ? ArchivoViewerWeb(archivos: archivos)
            : const Text(
          "El usuario no compartió ningún archivo",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red),
        ),
        const SizedBox(height: 30),
        const Divider(color: gris),
        const Text("Espacio de diligenciamiento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
        const SizedBox(height: 30),
        ingresarAnotaciones(),
        const SizedBox(height: 30),
        ingresarRazones(),
        const SizedBox(height: 30),
        Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
                backgroundColor: Colors.white, // Fondo blanco
                foregroundColor: Colors.black, // Letra en negro
              ),
              onPressed: () {
                setState(() {
                  _guardarDatosEnVariables();
                });

              },
              child: const Text("Guardar datos"),
            ),
            const SizedBox(width: 50),
            if(_mostrarBotonVistaPrevia)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                side: BorderSide(width: 1, color: Theme.of(context).primaryColor), // Borde con color primario
                backgroundColor: Colors.white, // Fondo blanco
                foregroundColor: Colors.black, // Letra en negro
              ),
              onPressed: () {
                setState(() {
                  _mostrarVistaPrevia = !_mostrarVistaPrevia; // Alterna visibilidad
                });

              },
              child: const Text("Vista previa"),
            ),
          ],
        ),
        const SizedBox(height: 50),
        // ✅ Solo muestra la vista previa si _mostrarVistaPrevia es true
        if (_mostrarVistaPrevia)
          vistaPreviaDerechoPeticion(userData, textoPrincipal, razonesPeticion),


      ],
    );
  }

  /// 📅 Muestra la fecha de hoy en formato adecuado
  Widget _buildFechaHoy() {
    return Text(
      'Hoy es: ${DateFormat('d \'de\' MMMM \'de\' y', 'es').format(DateTime.now())}',
      style: const TextStyle(fontSize: 12),
    );
  }

  /// 👤 Muestra el nombre del solicitante
  Widget _buildSolicitanteInfo() {
    return Row(
      children: [
        Text(
          "Solicitado por: ${userData?.nombreAcudiente ?? "Sin información"} ${userData?.apellidoAcudiente ?? "Sin información"}",
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  /// 📌 Muestra detalles de la solicitud (seguimiento, categoría, fecha, subcategoría)
  Widget _buildDetallesSolicitud() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Número de seguimiento", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.numeroSeguimiento ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Categoría", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.categoria ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Fecha de solicitud", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              _formatFecha(widget.fecha),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Subcategoría", style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(widget.subcategoria ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  /// 📝 Muestra la descripción de la solicitud en un contenedor estilizado
  Widget _buildSolicitudTexto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: gris),
        const Text(
          "Comentarios hechos por el usuario",
          style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: widget.preguntas.isNotEmpty && widget.respuestas.isNotEmpty
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              widget.preguntas.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.preguntas[index],
                      style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      index < widget.respuestas.length ? widget.respuestas[index] : 'No hay respuesta',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    const Divider(), // Separador entre preguntas
                  ],
                ),
              ),
            ),
          )
              : const Text(
            "No hay preguntas ni respuestas registradas.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  /// 📆 Función para manejar errores en la conversión de fechas
  String _formatFecha(String? fecha) {
    try {
      return fecha != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(fecha))
          : "Sin fecha";
    } catch (e) {
      return "Fecha inválida";
    }
  }

  /// 🎉 Nuevo Widget (Columna extra en PC, o debajo en móvil)
  Widget _buildExtraWidget() {
    if (userData == null) {
      return const Center(child: CircularProgressIndicator()); // 🔹 Muestra un loader mientras `userData` se carga
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1), // 🔹 Marco gris
        borderRadius: BorderRadius.circular(10), // 🔹 Bordes redondeados
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Datos generales del PPL", style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 24
          ),),
          const SizedBox(height: 25),
          Row(
            children: [
              const Text('Nombre:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.nombrePpl ?? "", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Apellido:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.apellidoPpl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
            ],
          ),
          Row(
            children: [
              const Text('Tipo Documento:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.tipoDocumentoPpl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Número Documento:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.numeroDocumentoPpl, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Centro Reclusión:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.centroReclusion, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.1)),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Juzgado Ejecución Penas:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.juzgadoEjecucionPenas, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.1)),
            ],
          ),
          Text(
            "Correo: ${userData!.juzgadoEjecucionPenasEmail}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.1),
          ),

          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Juzgado Que Condenó:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.juzgadoQueCondeno, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.1)),
            ],
          ),
          Text(
            "Correo: ${userData!.juzgadoQueCondenoEmail}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.1),
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delito:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.delito, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Radicado:', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.radicado, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Tiempo Condena:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text('${userData!.tiempoCondena} meses', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('TD:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.td, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('NUI:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.nui, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Patio:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.patio, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Fecha Captura:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(
                DateFormat('yyyy-MM-dd').format(userData!.fechaCaptura!),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Fecha Inicio Descuento:  ',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
              Text(
                userData!.fechaInicioDescuento != null
                    ? DateFormat('yyyy-MM-dd').format(userData!.fechaInicioDescuento!)
                    : 'No disponible',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              const Text('Labor Descuento:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.laborDescuento, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          const Text("Datos del Acudiente", style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black
          )),
          const SizedBox(height: 5),
          Row(
            children: [
              const Text('Nombre:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.nombreAcudiente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Apellido:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.apellidoAcudiente, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Parentesco:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.parentescoRepresentante, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Celular:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.celular, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              const Text('Email:  ', style: TextStyle(fontSize: 12, color: Colors.black)),
              Text(userData!.email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 15),
          infocondena()

        ],
      ),
    );
  }

  /// 🔹 Construye un par de columnas para información general
  Widget _buildInfoRow(String title1, String value1, String title2, String value2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoColumn(title1, value1),
        _buildInfoColumn(title2, value2),
      ],
    );
  }

  /// 🔹 Construye una columna de información con título y valor
  Widget _buildInfoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: gris)),
        Text(value, style: const TextStyle(fontSize: 16, color: negro, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void fetchUserData() async {
    Ppl? fetchedData = await _pplProvider.getById(widget.idUser);
    setState(() {
      userData = fetchedData;
      isLoading = false; // Se detiene la carga cuando los datos llegan
    });
  }

  Future<void> calcularTiempo(String id) async {
    final pplData = await _pplProvider.getById(id);
    if (pplData != null) {
      final fechaCaptura = pplData.fechaCaptura;
      tiempoCondena = pplData.tiempoCondena;
      final fechaActual = DateTime.now();
      final fechaFinCondena = fechaCaptura?.add(Duration(days: tiempoCondena * 30));

      final diferenciaRestante = fechaFinCondena?.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura!);

      setState(() {
        mesesRestante = (diferenciaRestante!.inDays ~/ 30)!;
        diasRestanteExactos = diferenciaRestante.inDays % 30;

        mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
        diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;
      });

      // Validaciones para beneficios
      porcentajeEjecutado = (diferenciaEjecutado.inDays / (tiempoCondena * 30)) * 100;
      print("Porcentaje de condena ejecutado: $porcentajeEjecutado%");

      if (porcentajeEjecutado >= 33.33) {
        print("Se aplica el beneficio de permiso administrativo de 72 horas");
      } else {
        print("No se aplica el beneficio de permiso administrativo de 72 horas");
      }

      if (porcentajeEjecutado >= 50) {
        print("Se aplica el beneficio de prisión domiciliaria");
      } else {
        print("No se aplica el beneficio de prisión domiciliaria");
      }

      if (porcentajeEjecutado >= 60) {
        print("Se aplica el beneficio de libertad condicional");
      } else {
        print("No se aplica el beneficio de libertad condicional");
      }

      if (porcentajeEjecutado >= 100) {
        print("Se aplica el beneficio de extinción de la pena");
      } else {
        print("No se aplica el beneficio de extinción de la pena");
      }

      print("Tiempo restante: $mesesRestante meses y $diasRestanteExactos días");
      print("Tiempo ejecutado: $mesesEjecutado meses y $diasEjecutadoExactos días");
    } else {
      print("No hay datos");
    }
  }

  Widget infocondena(){
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: primary, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Condena\ntranscurrido',
                        style: TextStyle(fontSize: screenWidth > 600 ? 12 : 11, fontWeight: FontWeight.bold,
                            color: negroLetras,
                            height: 1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mesesEjecutado == 1
                            ? diasEjecutadoExactos == 1
                            ? '$mesesEjecutado mes : $diasEjecutadoExactos día'
                            : '$mesesEjecutado mes : $diasEjecutadoExactos días'
                            : diasEjecutadoExactos == 1
                            ? '$mesesEjecutado meses : $diasEjecutadoExactos día'
                            : '$mesesEjecutado meses : $diasEjecutadoExactos días',
                        style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: primary, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Condena\nrestante',
                        style: TextStyle(fontSize: screenWidth > 600 ? 12 : 11, fontWeight: FontWeight.bold,
                            color: negroLetras,
                            height: 1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mesesRestante == 1
                            ? diasRestanteExactos == 1
                            ? '$mesesRestante mes : $diasRestanteExactos día'
                            : '$mesesRestante mes : $diasRestanteExactos días'
                            : mesesRestante > 0
                            ? diasRestanteExactos == 1
                            ? '$mesesRestante meses : $diasRestanteExactos día'
                            : '$mesesRestante meses : $diasRestanteExactos días'
                            : diasRestanteExactos == 1
                            ? '$diasRestanteExactos día'
                            : '$diasRestanteExactos días',
                        style: TextStyle(fontSize: screenWidth > 600 ? 14 : 12, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Porcentaje de condena ejecutado: ${porcentajeEjecutado.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),

        Column(
          children: [
            _buildBenefitCard(
              title: 'Permiso Administrativo de 72 horas',
              condition: porcentajeEjecutado >= 33.33,
              remainingTime: ((33.33 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
            ),
            _buildBenefitCard(
              title: 'Prisión Domiciliaria',
              condition: porcentajeEjecutado >= 50,
              remainingTime: ((50 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
            ),
            _buildBenefitCard(
              title: 'Libertad Condicional',
              condition: porcentajeEjecutado >= 60,
              remainingTime: ((60 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
            ),
            _buildBenefitCard(
              title: 'Extinción de la Pena',
              condition: porcentajeEjecutado >= 100,
              remainingTime: ((100 - porcentajeEjecutado) / 100 * tiempoCondena * 30).ceil(),
            ),
          ],
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildBenefitCard({required String title, required bool condition, required int remainingTime}) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: condition ? Colors.green : Colors.red, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      elevation: 3,
      color: condition ? Colors.green : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              condition ? Icons.notifications : Icons.access_time, // Cambia a reloj si la tarjeta es roja
              color: condition ? Colors.white : Colors.black, // Negro si la tarjeta es roja
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: condition
                          ? 'Se ha completado el tiempo establecido para acceder al beneficio de '
                          : 'Aún no se puede acceder a ',
                      style: TextStyle(
                        fontSize: 12,
                        color: condition ? Colors.white : Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: title, // Texto en negrilla
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold, // Negrilla
                        color: condition ? Colors.white : Colors.black,
                      ),
                    ),
                    if (!condition) // Solo agregar este texto si la condición es falsa
                      TextSpan(
                        text: '. Faltan $remainingTime días para completar el tiempo establecido.',
                        style: TextStyle(
                          fontSize: 12,
                          color: condition ? Colors.white : Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget ingresarAnotaciones(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingresar las peticiones",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Animación suave
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _expandido ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _expandido = !_expandido;
                      });
                    },
                  ),
                ],
              ),
              if (_expandido) // Solo muestra el campo si está expandido
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _textoPrincipalController,
                    minLines: 3,
                    maxLines: 20,
                    decoration: const InputDecoration(
                      hintText: "Escribe aquí...",
                      border: InputBorder.none, // Sin borde interno
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget ingresarRazones(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingresar razones de la peticion",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Animación suave
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      _expandido ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _expandido = !_expandido;
                      });
                    },
                  ),
                ],
              ),
              if (_expandido) // Solo muestra el campo si está expandido
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: _textoRazonesController,
                    minLines: 3,
                    maxLines: 20,
                    decoration: const InputDecoration(
                      hintText: "Escribe aquí...",
                      border: InputBorder.none, // Sin borde interno
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget vistaPreviaDerechoPeticion(userData, String textoPrincipal, String razonesPeticion) {
    var derechoPeticion = DerechoPeticionTemplate(
      entidad: userData?.centroReclusion ?? "",
      nombrePpl: userData?.nombrePpl?.trim() ?? "",
      apellidoPpl: userData?.apellidoPpl?.trim() ?? "",
      identificacionPpl: userData?.numeroDocumentoPpl ?? "",
      centroPenitenciario: userData?.centroReclusion ?? "",
      textoPrincipal: textoPrincipal,
      razonesPeticion: razonesPeticion,
      emailUsuario: userData?.email?.trim() ?? "",
      td: userData?.td?.trim() ?? "",
      nui: userData?.nui?.trim() ?? "",
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vista previa del derecho de petición",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText.rich(
            derechoPeticion.generarTexto(),
          ),
        ),
      ],
    );
  }

}
