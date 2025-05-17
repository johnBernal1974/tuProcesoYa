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
      pageTitle: 'Tus Datos',
      content: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width >= 1000 ? 500 : double.infinity,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nombre:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.nombrePpl, style: const TextStyle(fontSize: 15, fontWeight:FontWeight.w900 )),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Apellido:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.apellidoPpl, style: const TextStyle(fontSize: 15, fontWeight:FontWeight.w900)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Tipo Documento:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.tipoDocumentoPpl, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Número Documento:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.numeroDocumentoPpl, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Sitación actual:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.situacion, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600, height: 1.1)),
                    ],
                  ),
                  if(_ppl!.situacion != "En Reclusión")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Dirección registrada para cumplir la situación actual:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(
                        "${_ppl!.direccion}, ${_ppl!.municipio} - ${_ppl!.departamento}",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if(_ppl!.situacion == "En Reclusión")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Centro Reclusión:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.centroReclusion, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600, height: 1.1)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Juzgado Ejecución Penas:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.juzgadoEjecucionPenas, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600, height: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Juzgado Que Condenó:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.juzgadoQueCondeno, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600, height: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Categoría del delito:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.categoriaDelDelito, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Delito:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.delito, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Radicado:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.radicado, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Tiempo Condena:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(
                        '${_ppl!.mesesCondena} meses, ${_ppl!.diasCondena} días',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if(_ppl!.situacion == "En Reclusión")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('TD (tarjeta decadactilar No):', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.td, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  if(_ppl!.situacion == "En Reclusión")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('NUI (Número único de identificación):', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.nui, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  if(_ppl!.situacion == "En Reclusión")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Patio:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.patio, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Fecha Captura:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(
                        DateFormat("d 'de' MMMM 'de' yyyy", 'es_ES').format(_ppl!.fechaCaptura!),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Divider(color: Colors.grey),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Text("Datos del Acudiente", style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    fontSize: 20
                  )),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nombre:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.nombreAcudiente, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600 )),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Apellido:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.apellidoAcudiente, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600 )),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Parentesco:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.parentescoRepresentante, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Celular:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.celular, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      const Text('Email:', style: TextStyle(fontSize: 13, color: negro)),
                      Text(_ppl!.email, style: const TextStyle(fontSize: 13, fontWeight:FontWeight.w600)),
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