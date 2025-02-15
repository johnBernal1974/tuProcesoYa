import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/models/ppl.dart';
import 'package:tuprocesoya/providers/auth_provider.dart';

import '../../../commons/main_layaout.dart';
import '../../../providers/ppl_provider.dart';
import '../../../src/colors/colors.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    if (_ppl == null) {
      return Container();
    }
    return MainLayout(
      pageTitle: 'Mis Datos',
      content: SingleChildScrollView(
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
              padding: const EdgeInsets.all(10),
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
                    fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black,height: 1.2
                  )),
                  const SizedBox(height: 20),
                  const Text("Datos del PPL", style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontSize: 20
                  ),),
                  const SizedBox(height: 15),
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nombre:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.nombrePpl, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600 )),
                    ],
                  ),
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Apellido:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.apellidoPpl, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600, color: Colors.black)),
                    ],
                  ),
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tipo Documento:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.tipoDocumentoPpl, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Número Documento:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.numeroDocumentoPpl, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Centro Reclusión:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.centroReclusion, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600, height: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Juzgado Ejecución Penas:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.juzgadoEjecucionPenas, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600, height: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Juzgado Que Condenó:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.juzgadoQueCondeno, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600, height: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delito:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.delito, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Radicado:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.radicado, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Tiempo Condena:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text('${_ppl!.tiempoCondena} meses', style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('TD:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.td, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('NUI:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.nui, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Patio:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.patio, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Fecha Captura:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(
                        DateFormat('yyyy-MM-dd').format(_ppl!.fechaCaptura!),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      )
                      ,
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Fecha Inicio Descuento:  ',
                        style: TextStyle(fontSize: 13, color: negro),
                      ),
                      Text(
                        _ppl!.fechaInicioDescuento != null
                            ? DateFormat('yyyy-MM-dd').format(_ppl!.fechaInicioDescuento!)
                            : 'No disponible', // Muestra un mensaje si es null
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      const Text('Labor Descuento:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.laborDescuento, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
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
                      const Text('Nombre:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.nombreAcudiente, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600 )),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Apellido:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.apellidoAcudiente, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600 )),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Parentesco:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.parentescoRepresentante, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Celular:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.celular, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Email:  ', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.email, style: const TextStyle(fontSize: 16, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 25)
                ],
              ),
            ),
          ),
        ),
      );

  }
}