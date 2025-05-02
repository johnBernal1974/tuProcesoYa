import 'package:tuprocesoya/helper/helpersTutela/text_intimidad_tutela.dart';
import 'package:tuprocesoya/helper/helpersTutela/texto_debido_proceso.dart';
import 'package:tuprocesoya/helper/helpersTutela/texto_dignidad_tutela.dart';
import 'package:tuprocesoya/helper/helpersTutela/texto_educacion_tutela.dart';
import 'package:tuprocesoya/helper/helpersTutela/texto_integridad_persona_tutela.dart';
import 'package:tuprocesoya/helper/helpersTutela/texto_salud_tutela.dart';
import 'package:tuprocesoya/helper/helpersTutela/texto_vida_tutela.dart';

// importa los demás textos

class TextoDerechosVulneradosHelper {
  static String obtenerTexto({
    required String categoria,
    required String subcategoria,
  }) {
    final key = '${categoria.toLowerCase()}__${subcategoria.toLowerCase()}';

    switch (categoria.toLowerCase()) {
      case 'salud':
        return TextoSalud.obtenerTexto(subcategoria);

      case 'vida':
        return TextoVida.obtenerTexto(subcategoria);

      case 'integridad personal':
        return TextoIntegridadPersonal.obtenerTexto(subcategoria);

      case 'Dignidad humana':
        return TextoDignidadHumana.obtenerTexto(subcategoria);

      case 'Debido proceso':
        return TextoDebidoProceso.obtenerTexto(subcategoria);

      case 'Intimidad':
        return TextoIntimidad.obtenerTexto(subcategoria);

      case 'Educación':
        return TextoEducacion.obtenerTexto(subcategoria);

      default:
        return 'No se ha definido un texto para esta categoría y subcategoría.';
    }
  }
}
