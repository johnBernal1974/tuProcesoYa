import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../helper/descuento_helper.dart';
import '../src/colors/colors.dart';

class CardGestionarDescuento extends StatefulWidget {
  final String uidUsuario;
  final String? uidAdmin; // ahora puede ser null si no se pasa

  const CardGestionarDescuento({
    super.key,
    required this.uidUsuario,
    required this.uidAdmin,
  });

  @override
  State<CardGestionarDescuento> createState() => _CardGestionarDescuentoState();
}

class _CardGestionarDescuentoState extends State<CardGestionarDescuento> {
  int _porcentajeSeleccionado = 10;
  Map<String, dynamic>? _descuentoOtorgado;
  bool _isLoading = true;
  String? _nombreAdmin;
  bool _puedeAsignar = true;


  @override
  void initState() {
    super.initState();
    _cargarDescuento();
  }

  Future<void> _cargarDescuento() async {
    try {
      final descuento = await DescuentoHelper.obtenerDescuentoPersonalizado(widget.uidUsuario);
      final puedeAsignar = await DescuentoHelper.puedeAsignarDescuento(widget.uidUsuario);

      String? nombreAdmin;
      if (descuento != null && descuento["otorgadoPor"] != null) {
        nombreAdmin = await _obtenerNombreAdminSeguro(descuento["otorgadoPor"]);
      }

      setState(() {
        _descuentoOtorgado = descuento;
        _nombreAdmin = nombreAdmin;
        _puedeAsignar = puedeAsignar; // ← actualizar el nuevo estado
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _descuentoOtorgado = null;
        _nombreAdmin = null;
        _puedeAsignar = false; // ← por seguridad, en error asumimos que no se puede
        _isLoading = false;
      });
      debugPrint("Error al cargar el descuento: $e");
    }
  }


  Future<void> _otorgarDescuento() async {
    final uidAdminActual = FirebaseAuth.instance.currentUser?.uid;
    if (uidAdminActual == null) return;

    await DescuentoHelper.otorgarDescuento(
      uidUsuario: widget.uidUsuario,
      porcentaje: _porcentajeSeleccionado,
      uidAdmin: uidAdminActual,
    );
    await _cargarDescuento(); // Recargar para reflejar cambio
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const CircularProgressIndicator();

    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        icon: Icon(_descuentoOtorgado == null ? Icons.discount : Icons.visibility),
        label: Text(
          _descuentoOtorgado == null
              ? "Generar descuento en suscripción"
              : "Ver descuento otorgado en la suscripción",
        ),
        onPressed:
        _descuentoOtorgado == null ? _mostrarDialogoOtorgar : _mostrarDialogoDetalle,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          _descuentoOtorgado == null ? Colors.deepPurple : Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _mostrarDialogoOtorgar() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text("Asignar descuento"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Selecciona el porcentaje de descuento:"),
                  const SizedBox(height: 8),
                  DropdownButton<int>(
                    dropdownColor: blanco,
                    value: _porcentajeSeleccionado,
                    items: [5, 10, 20, 30, 50]
                        .map((p) => DropdownMenuItem(value: p, child: Text("$p%")))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _porcentajeSeleccionado = value;
                        });
                        setStateDialog(() {}); // ← actualiza también el diálogo
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () async {
                Navigator.pop(context);
                await _otorgarDescuento();
              },
            ),
          ],
        );
      },
    );
  }


  void _mostrarDialogoDetalle() {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final fecha = _descuentoOtorgado!["fecha"] as Timestamp?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Descuento otorgado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🎁 Porcentaje: ${_descuentoOtorgado!["porcentaje"]}%"),
            if (fecha != null)
              Text("📅 Fecha: ${formatter.format(fecha.toDate())}"),
            Text("👤 Otorgado por: ${_nombreAdmin ?? 'Desconocido'}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cerrar"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("QUITAR DESCUENTO", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context); // Cierra el detalle
              _mostrarDialogoConfirmarEliminacion();
            },
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoConfirmarEliminacion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("¿Eliminar descuento?"),
        content: const Text("Esta acción eliminará el descuento otorgado. ¿Deseas continuar?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("CONFIRMAR", style: TextStyle(color: blanco)),
            onPressed: () async {
              Navigator.pop(context); // Cierra el diálogo
              await FirebaseFirestore.instance
                  .collection('Ppl')
                  .doc(widget.uidUsuario)
                  .update({"descuento": FieldValue.delete()});

              await _cargarDescuento(); // Recarga estado
            },
          ),
        ],
      ),
    );
  }



  Future<String?> _obtenerNombreAdminSeguro(String uidAdmin) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("admin")
          .doc(uidAdmin) // ← usamos directamente el ID del documento
          .get();

      if (!doc.exists) {
        debugPrint("No existe admin con ID: $uidAdmin");
        return null;
      }

      final data = doc.data();
      final nombre = data?["name"] ?? "";
      final apellidos = data?["apellidos"] ?? "";

      final nombreCompleto = "$nombre $apellidos".trim();
      return nombreCompleto.isNotEmpty ? nombreCompleto : null;
    } catch (e) {
      debugPrint("Error al obtener nombre del admin: $e");
      return null;
    }
  }

}
