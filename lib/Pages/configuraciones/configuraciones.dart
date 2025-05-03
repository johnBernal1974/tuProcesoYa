import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class ConfiguracionesPage extends StatefulWidget {
  @override
  _ConfiguracionesPageState createState() => _ConfiguracionesPageState();
}

class _ConfiguracionesPageState extends State<ConfiguracionesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> _controllers = {
    "tiempoDePrueba": TextEditingController(),
    "valor_derecho_peticion": TextEditingController(),
    "valor_subscripcion": TextEditingController(),
    "valor_tutela": TextEditingController(),
    "valor_72h": TextEditingController(),
    "valor_domiciliaria": TextEditingController(),
    "valor_condicional": TextEditingController(),
    "valor_extincion": TextEditingController(),
  };

  bool _loading = true;
  String? _documentId; // Guardará el ID dinámico del documento


  @override
  void initState() {
    super.initState();
    _loadConfigurations(); // Carga los valores al abrir la página
  }

  Future<void> _loadConfigurations() async {
    try {
      QuerySnapshot configCollection = await _firestore.collection("configuraciones").get();

      if (configCollection.docs.isNotEmpty) {
        DocumentSnapshot configDoc = configCollection.docs.first; // Obtiene el primer documento disponible

        setState(() {
          _documentId = configDoc.id; // Guarda el ID dinámico del documento

          _controllers.forEach((key, controller) {
            if (configDoc.data() != null && (configDoc.data() as Map<String, dynamic>).containsKey(key)) {
              controller.text = configDoc[key].toString();
            }
          });

          _loading = false;
        });
      } else {
        print("⚠️ No se encontraron documentos en la colección 'configuraciones'");
      }
    } catch (e) {
      print("❌ Error al cargar configuraciones: $e");
    }
  }

  Future<void> _updateValue(String key) async {
    if (_documentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No se encontró el documento de configuración.")),
      );
      return;
    }

    try {
      int newValue = int.tryParse(_controllers[key]!.text) ?? 0;
      await _firestore.collection("configuraciones").doc(_documentId).update({
        key: newValue,
      });
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Valor actualizado con éxito.")),
        );
      }

    } catch (e) {
      if (kDebugMode) {
        print("Error al actualizar $key: $e");
      }
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar el valor.")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: "Configuraciones",
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Configuraciones Generales",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildConfigField("Tiempo de Prueba", "tiempoDePrueba"),
                _buildConfigField("Valor Derecho de Petición", "valor_derecho_peticion"),
                _buildConfigField("Valor Suscripción", "valor_subscripcion"),
                _buildConfigField("Valor Tutela", "valor_tutela"),
                _buildConfigField("Valor Permiso de 72 horas", "valor_72h"),
                _buildConfigField("Valor Prisión domiciliaria", "valor_domiciliaria"),
                _buildConfigField("Valor Libertad condicional", "valor_condicional"),
                _buildConfigField("Valor Extinción de la pena", "valor_extincion"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigField(String label, String key) {
    return SingleChildScrollView(
      child: SizedBox(
        width: MediaQuery.of(context).size.width >= 1000 ? 500 : double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controllers[key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey), // 🔹 Borde gris por defecto
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey), // 🔹 Borde gris cuando NO está enfocado
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue, width: 2), // 🔹 Borde azul cuando está enfocado
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _updateValue(key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
