import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ArchivoViewerWeb2 extends StatelessWidget {
  final List<String> archivos;

  const ArchivoViewerWeb2({super.key, required this.archivos});

  @override
  Widget build(BuildContext context) {
    // Detectamos el ancho de la pantalla
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 6; // Default para PC

    if (screenWidth < 1200) {
      crossAxisCount = 4; // Tablets grandes
    }
    if (screenWidth < 800) {
      crossAxisCount = 3; // Tablets pequeñas
    }
    if (screenWidth < 500) {
      crossAxisCount = 2; // Móviles
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount, // Se ajusta dinámicamente
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

        bool esPDF(String url) {
          return url.split('?').first.toLowerCase().endsWith('.pdf');
        }

        if (esImagen(archivo)) {
          return _buildImageThumbnail(context, archivo);
        } else if (esPDF(archivo)) {
          return _buildPDFButton(context, archivo);
        } else {
          return _buildUnsupportedFile();
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
    String decodedUrl = Uri.decodeFull(url);
    List<String> partes = decodedUrl.split('/');
    return partes.last.split('?').first;
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
