import 'package:flutter/material.dart';

import '../../../src/colors/colors.dart';

class RequisitosPermiso72hPage extends StatelessWidget {
  const RequisitosPermiso72hPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Permiso de 72 horas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Antes de comenzar la solicitud, asegúrate de contar con estos documentos y conoce cómo conseguirlos.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            _buildRequisito(
              icon: Icons.double_arrow_outlined,
              titulo: 'Declaración extrajuicio de la persona responsable',
              descripcion: 'Documento notariado donde la persona que recibirá al Ppl en su domicilio, declara que se compromete a ser responsable durante las 72 horas de permiso. Se consigue en cualquier notaría con la cédula del responsable.',
              costo: 'Costo estimado: \$25.000 - \$35.000 COP',
            ),

            _buildRequisito(
              icon: Icons.double_arrow_outlined,
              titulo: 'Certificado de insolvencia económica',
              descripcion: 'Este documento no es obligatorio, pero contar con él puede fortalecer tu solicitud. El certificado demuestra la incapacidad económica para pagar una indemnización. Puedes obtenerlo en entidades como la Cámara de Comercio o la Secretaría de Tránsito, llevando la fotocopia de la cédula del PPL.',
              costo: 'Costo estimado: \$15.000 - \$35.000 COP',
            ),

            _buildRequisito(
              icon: Icons.double_arrow_outlined,
              titulo: 'Recibo de servicios públicos',
              descripcion: 'Sirve para verificar la dirección donde se estará cumpliendo la condena. Puedes descargarlo de internet o conseguirlo en físico. Preferiblemente a nombre del responsable.',
            ),

            _buildRequisito(
              icon: Icons.double_arrow_outlined,
              titulo: 'Fotocopia de la cédula de la persona responsable',
              descripcion: 'Es indispensable para validar la identidad de quien acogerá al Ppl.',
            ),

            _buildRequisito(
              icon: Icons.double_arrow_outlined,
              titulo: 'Documentos de identidad de los hijos (si vivirán con el Ppl)',
              descripcion: 'Puede ser registro civil o tarjeta de identidad. Esto demuestra el arraigo familiar y que el entorno donde pasará en su tiempo de permiso es adecuado. Esto solo aplica para hijos menores de 18 años',
            ),
            const SizedBox(height: 24),
            const Text(
              'Todos los documentos deben estar en formato PDF, ser completamente legibles y de buena calidad. Esto es fundamental para evitar devoluciones o el rechazo de la solicitud.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            const Text(
              'Es ideal que los archivos que vayas a subir en la solicitud, tengan el nombre de cada documento. Ejemplo: Cédula de ciudadanía, declaración extrajuicio, etc.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                ),
                onPressed: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: blanco,
                      title: const Text("¿Tienes todos los documentos listos?"),
                      content: const Text(
                        "Antes de continuar, asegúrate de tener preparados en formato PDF los documentos requeridos: "
                            "declaración extrajuicio del responsable, certificado de insolvencia, cédula del responsable, "
                            "recibo de servicios públicos y documentos de identidad de los hijos (si aplica).",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                          child: const Text("Sí, continuar", style: TextStyle(color: blanco),),
                        ),
                      ],
                    ),
                  );

                  if(context.mounted){
                    if (confirmar == true) {
                      Navigator.pushReplacementNamed(context, 'solicitud_72h_page');
                    }
                  }
                },
                child: const Text('Comenzar solicitud'),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildRequisito({
    required IconData icon,
    required String titulo,
    required String descripcion,
    String? costo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(descripcion, style: const TextStyle(fontSize: 14)),
                if (costo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(costo, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
