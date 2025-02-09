import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/models/ppl.dart';
import 'package:tuprocesoya/providers/auth_provider.dart';
import '../../commons/main_layaout.dart';
import '../../providers/ppl_provider.dart';
import '../../src/colors/colors.dart';

class MisDatosPage extends StatefulWidget {
  const MisDatosPage({super.key});

  @override
  State<MisDatosPage> createState() => _MisDatosPageState();
}

class _MisDatosPageState extends State<MisDatosPage> {
  late MyAuthProvider _myAuthProvider;
  late String _uid;
  Ppl? _ppl;

  @override
  void initState() {
    super.initState();
    _myAuthProvider = MyAuthProvider();
    _loadUid();
  }

  Future<void> _loadUid() async {
    final user = _myAuthProvider.getUser();
    if (user != null) {
      setState(() {
        _uid = user.uid;
      });
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    final pplProvider = PplProvider();
    final pplData = await pplProvider.getById(_uid);
    setState(() {
      _ppl = pplData;
    });
    print('Datos de PPL:');
    print('id: ${_ppl?.id} (${_ppl?.id.runtimeType})');
    print('nombreAcudiente: ${_ppl?.nombreAcudiente} (${_ppl?.nombreAcudiente.runtimeType})');
    print('apellidoAcudiente: ${_ppl?.apellidoAcudiente} (${_ppl?.apellidoAcudiente.runtimeType})');
    print('parentescoRepresentante: ${_ppl?.parentescoRepresentante} (${_ppl?.parentescoRepresentante.runtimeType})');
    print('celular: ${_ppl?.celular} (${_ppl?.celular.runtimeType})');
    print('email: ${_ppl?.email} (${_ppl?.email.runtimeType})');
    print('nombrePpl: ${_ppl?.nombrePpl} (${_ppl?.nombrePpl.runtimeType})');
    print('apellidoPpl: ${_ppl?.apellidoPpl} (${_ppl?.apellidoPpl.runtimeType})');
    print('tipoDocumentoPpl: ${_ppl?.tipoDocumentoPpl} (${_ppl?.tipoDocumentoPpl.runtimeType})');
    print('numeroDocumentoPpl: ${_ppl?.numeroDocumentoPpl} (${_ppl?.numeroDocumentoPpl.runtimeType})');
    print('centroReclusion: ${_ppl?.centroReclusion} (${_ppl?.centroReclusion.runtimeType})');
    print('juzgadoEjecucionPenas: ${_ppl?.juzgadoEjecucionPenas} (${_ppl?.juzgadoEjecucionPenas.runtimeType})');
    print('juzgadoQueCondeno: ${_ppl?.juzgadoQueCondeno} (${_ppl?.juzgadoQueCondeno.runtimeType})');
    print('delito: ${_ppl?.delito} (${_ppl?.delito.runtimeType})');
    print('radicado: ${_ppl?.radicado} (${_ppl?.radicado.runtimeType})');
    print('tiempoCondena: ${_ppl?.tiempoCondena} (${_ppl?.tiempoCondena.runtimeType})');
    print('td: ${_ppl?.td} (${_ppl?.td.runtimeType})');
    print('nui: ${_ppl?.nui} (${_ppl?.nui.runtimeType})');
    print('patio: ${_ppl?.patio} (${_ppl?.patio.runtimeType})');
    print('fechaCaptura: ${_ppl?.fechaCaptura} (${_ppl?.fechaCaptura.runtimeType})');
    print('fechaInicioDescuento: ${_ppl?.fechaInicioDescuento} (${_ppl?.fechaInicioDescuento.runtimeType})');
    print('laborDescuento: ${_ppl?.laborDescuento} (${_ppl?.laborDescuento.runtimeType})');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = MediaQuery.of(context).size.width < 800;
    return MainLayout(
      pageTitle: 'Mis Datos',
      content: _ppl != null
          ? Padding(
        padding: screenWidth > 800 // Si es pantalla grande (desktop)
            ? const EdgeInsets.symmetric(horizontal: 100) // Margen de 100px
            : const EdgeInsets.symmetric(horizontal: 10), // Si es pantalla pequeña (móvil)
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset('assets/images/logo_tu_proceso_ya_transparente.png', height: 40),
                ],
              ),
              const SizedBox(height: 20),// Logo
              const Text("En ésta sección encontrarás la información guardada en el momento del registro. Por favor "
                  "verifica que los datos sean correctos y esten completos.", style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black
              )),
              const SizedBox(height: 20),
              const Text("Datos del PPL", style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.black
              ),),
              const SizedBox(height: 15),
              Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Nombre:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.nombrePpl, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600 )),
                ],
              ),
              Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Apellido:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.apellidoPpl, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600, color: Colors.black)),
                ],
              ),
              Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tipo Documento:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.tipoDocumentoPpl, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              Row(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Número Documento:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.numeroDocumentoPpl, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Centro Reclusión:', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.centroReclusion, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Juzgado Ejecución Penas:', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.juzgadoEjecucionPenas, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Juzgado Que Condenó:', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.juzgadoQueCondeno, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Delito:', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.delito, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Radicado:', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.radicado, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Tiempo Condena:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text('${_ppl!.tiempoCondena} meses', style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  const Text('TD:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.td, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  const Text('NUI:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.nui, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  const Text('Patio:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.patio, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  const Text('Fecha Captura:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(
                    DateFormat('yyyy-MM-dd').format(_ppl!.fechaCaptura!),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  )
                  ,
                ],
              ),
              Row(
                children: [
                  const Text('Fecha Inicio Descuento:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(
                    DateFormat('yyyy-MM-dd').format(_ppl!.fechaInicioDescuento!),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  )
                ],
              ),
              Row(
                children: [
                  const Text('Labor Descuento:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.laborDescuento, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 15),
              const Text("Datos del Acudiente", style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black
              ),),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Text('Nombre:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.nombreAcudiente, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600 )),
                ],
              ),
              Row(
                children: [
                  const Text('Apellido:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.apellidoAcudiente, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600 )),
                ],
              ),
              Row(
                children: [
                  const Text('Parentesco:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.parentescoRepresentante, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  const Text('Celular:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.celular, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              Row(
                children: [
                  const Text('Email:  ', style: TextStyle(fontSize: 12, color: negroLetras)),
                  Text(_ppl!.email, style: const TextStyle(fontSize: 12, fontWeight:FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 25)
            ],
          ),
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}