
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ArchivoViewerWeb extends StatelessWidget {
  final List<String> archivos;

  const ArchivoViewerWeb({super.key, required this.archivos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: archivos.length,
      itemBuilder: (context, index) {
        String archivo = archivos[index];

        bool esImagen(String url) {
          return RegExp(r'\.(jpg|jpeg|png|gif|webp)$', caseSensitive: false)
              .hasMatch(url.split('?').first);
        }
        // Verifica si es PDF
        bool esPDF(String url) {
          return url.split('?').first.toLowerCase().endsWith('.pdf');
        }
        if (esImagen(archivo)) {
          return _buildImageThumbnail(context, archivo);
        } else if (esPDF(archivo)) {
          return _buildPDFButton(context, archivo);
        } else {
          return const ListTile(title: Text('Formato no compatible'));
        }
      },
    );
  }

  /// 🖼️ Miniatura de Imagen que se puede expandir
  Widget _buildImageThumbnail(BuildContext context, String url) {
    String fileName = obtenerNombreArchivo(url);
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: InteractiveViewer(
                  child: CachedNetworkImage(imageUrl: url),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildLoadingPlaceholder(),
              errorWidget: (context, url, error) =>
              const Icon(Icons.error, size: 50, color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          fileName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }


  String obtenerNombreArchivo(String url) {
    // Decodifica la URL para que %2F se convierta en "/"
    String decodedUrl = Uri.decodeFull(url);
    // Separa por "/" y toma la última parte
    List<String> partes = decodedUrl.split('/');
    // El nombre real del archivo es la última parte después de la última "/"
    return partes.last.split('?').first; // Quita cualquier parámetro después de "?"
  }




  /// 📄 Botón para abrir el PDF en el navegador
  Widget _buildPDFButton(BuildContext context, String url) {
    String fileName = obtenerNombreArchivo(url);
    return GestureDetector(
      onTap: () => abrirEnPestana(url),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 50),
            const SizedBox(height: 5),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  /// 🌍 Abre el PDF en el navegador
  void abrirEnPestana(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (kDebugMode) {
        print("❌ No se pudo abrir el archivo.");
      }
    }
  }

  /// 📂 Widget para archivos no soportados
  Widget _buildUnsupportedFile() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, color: Colors.grey, size: 50),
          SizedBox(height: 5),
          Text("Formato no soportado", style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// ⏳ Placeholder de carga
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}


