import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';

class AtenderTutelaPage extends StatefulWidget {
  const AtenderTutelaPage({super.key});

  @override
  State<AtenderTutelaPage> createState() => _AtenderTutelaPageState();
}

class _AtenderTutelaPageState extends State<AtenderTutelaPage> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Editar Tutela',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? 1500 : double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800;

                  return isWide
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildMainContent()),
                      const SizedBox(width: 50),
                      Expanded(flex: 2, child: _buildRightPanel()),
                    ],
                  )
                      : Column(
                    children: [
                      _buildMainContent(),
                      const SizedBox(height: 20),
                      _buildRightPanel(),
                      const SizedBox(height: 20),
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

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("📝 Contenido principal aquí", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        // Aquí puedes agregar tu lógica de edición de tutelas
      ],
    );
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text("📌 Panel derecho / auxiliar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        // Aquí puedes poner datos del PPL, correos, etc.
      ],
    );
  }
}
