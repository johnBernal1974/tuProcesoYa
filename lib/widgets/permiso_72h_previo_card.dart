import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Permiso72hPrevioCard extends StatefulWidget {
  final String pplId;

  const Permiso72hPrevioCard({
    super.key,
    required this.pplId,
  });

  @override
  State<Permiso72hPrevioCard> createState() => _Permiso72hPrevioCardState();
}

class _Permiso72hPrevioCardState extends State<Permiso72hPrevioCard> {
  bool _cargando = true;
  bool _editando = false;

  bool _permiso72hPrevio = false;      // valor actual
  bool _permiso72hPrevioTmp = false;   // valor mientras edita

  // ✅ Ajusta la colección si tu admin vive en otra (admins / Usuarios / etc.)
  Future<String> _obtenerNombreAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return "Admin desconocido";

    final snap = await FirebaseFirestore.instance
        .collection("admins") // ⚠️ cambia si aplica
        .doc(uid)
        .get();

    final data = snap.data();
    if (data == null) return "Admin desconocido";

    final nombre = (data["nombre"] ?? "").toString();
    final apellido = (data["apellido"] ?? "").toString();
    final full = "$nombre $apellido".trim();

    return full.isEmpty ? "Admin desconocido" : full;
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    final doc = await FirebaseFirestore.instance
        .collection("Ppl")
        .doc(widget.pplId)
        .get();

    final data = doc.data() as Map<String, dynamic>?;
    final val = data?["permiso72hPrevio"] == true;

    setState(() {
      _permiso72hPrevio = val;
      _permiso72hPrevioTmp = val;
      _cargando = false;
    });
  }

  Future<void> _guardar() async {
    try {
      final pplRef =
      FirebaseFirestore.instance.collection("Ppl").doc(widget.pplId);

      final snap = await pplRef.get();
      final data = snap.data() as Map<String, dynamic>?;
      final antes = data?["permiso72hPrevio"] == true;

      final despues = _permiso72hPrevioTmp;

      // Si no cambió, solo salimos de edición
      if (antes == despues) {
        setState(() {
          _editando = false;
          _permiso72hPrevio = despues;
        });
        return;
      }

      final adminNombre = await _obtenerNombreAdmin();

      await pplRef.update({
        "permiso72hPrevio": despues,
      });

      // ✅ Log en la misma subcolección que ya usas
      await pplRef.collection("beneficios_historial").add({
        "beneficio": "Permiso de 72h previo",
        "accion": despues ? "marcado_si" : "marcado_no",
        "fecha": FieldValue.serverTimestamp(),
        "origen": "plataforma",
        "adminNombre": adminNombre,
      });

      if (!mounted) return;

      setState(() {
        _permiso72hPrevio = despues;
        _editando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permiso de 72h previo actualizado.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar el permiso previo.")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    final textoEstado = _permiso72hPrevio
        ? "Con permiso de 72 horas previo"
        : "Sin permiso de 72 horas previo";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado discreto + lápiz
            Row(
              children: [
                Expanded(
                  child: Text(
                    textoEstado,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _editando ? "Cancelar" : "Editar",
                  icon: Icon(_editando ? Icons.close : Icons.edit, size: 20),
                  onPressed: () {
                    setState(() {
                      _editando = !_editando;
                      _permiso72hPrevioTmp = _permiso72hPrevio;
                    });
                  },
                ),
              ],
            ),

            // Modo edición: Sí/No
            if (_editando) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text("Sí", style: TextStyle(fontSize: 13)),
                      value: true,
                      groupValue: _permiso72hPrevioTmp,
                      onChanged: (v) => setState(() => _permiso72hPrevioTmp = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text("No", style: TextStyle(fontSize: 13)),
                      value: false,
                      groupValue: _permiso72hPrevioTmp,
                      onChanged: (v) => setState(() => _permiso72hPrevioTmp = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _guardar,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text("Guardar", style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
