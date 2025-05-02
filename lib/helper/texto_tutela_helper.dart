import 'helpersTutela/text_intimidad_tutela.dart';
import 'helpersTutela/texto_debido_proceso.dart';
import 'helpersTutela/texto_dignidad_tutela.dart';
import 'helpersTutela/texto_educacion_tutela.dart';
import 'helpersTutela/texto_integridad_persona_tutela.dart';
import 'helpersTutela/texto_salud_tutela.dart';
import 'helpersTutela/texto_vida_tutela.dart';
// importa los demás

class TextoFundamentacionTutelaHelper {
  static Map<String, String> obtenerFundamentacion({
    required String categoria,
    required String subcategoria,
  }) {
    final lowerCategoria = categoria.toLowerCase();

    String derechosVulnerados = '';
    String normasAplicables = '';
    String pretensiones = '';
    String pruebas = 'Adjunto documentos que demuestran la vulneración del derecho.';
    String juramento = 'Declaro bajo juramento que no he presentado otra tutela por los mismos hechos.';

    switch (lowerCategoria) {
      case 'salud':
        derechosVulnerados = TextoSalud.obtenerTexto(subcategoria);
        normasAplicables = TextoSalud.obtenerNormasAplicables(subcategoria);
        pretensiones = TextoSalud.obtenerPretensiones(subcategoria);
        break;
      case 'vida':
        derechosVulnerados = TextoVida.obtenerTexto(subcategoria);
        normasAplicables = TextoVida.obtenerNormasVida(subcategoria);
        pretensiones = TextoVida.obtenerPretensionesVida(subcategoria);
        break;
      case 'integridad personal':
        derechosVulnerados = TextoIntegridadPersonal.obtenerTexto(subcategoria);
        normasAplicables = TextoIntegridadPersonal.obtenerNormasIntegridadPersonal(subcategoria);
        pretensiones = TextoIntegridadPersonal.obtenerPretensionesIntegridadPersonal(subcategoria);
        break;
      case 'dignidad humana':
        derechosVulnerados = TextoDignidadHumana.obtenerTexto(subcategoria);
        normasAplicables = TextoDignidadHumana.obtenerNormasDignidadHumana(subcategoria);
        pretensiones = TextoDignidadHumana.obtenerPretensionesDignidadHumana(subcategoria);
        break;
      case 'debido proceso':
        derechosVulnerados = TextoDebidoProceso.obtenerTexto(subcategoria);
        normasAplicables = TextoDebidoProceso.obtenerNormasDebidoProceso(subcategoria);
        pretensiones = TextoDebidoProceso.obtenerPretensionesDebidoProceso(subcategoria);
        break;
      case 'intimidad':
        derechosVulnerados = TextoIntimidad.obtenerTexto(subcategoria);
        normasAplicables = TextoIntimidad.obtenerNormasIntimidad(subcategoria);
        pretensiones = TextoIntimidad.obtenerPretensionesIntimidad(subcategoria);
        break;
      case 'educacion':
        derechosVulnerados = TextoEducacion.obtenerTexto(subcategoria);
        normasAplicables = TextoEducacion.obtenerNormasEducacion(subcategoria);
        pretensiones = TextoEducacion.obtenerPretensionesEducacion(subcategoria);
        break;

    // Agrega aquí los demás casos: integridad personal, dignidad humana, etc.
      default:
        derechosVulnerados = 'Se ha vulnerado el derecho fundamental a $categoria.';
        normasAplicables = 'Normas constitucionales relacionadas con $categoria.';
        pretensiones = 'Solicito el amparo del derecho a $categoria.';
        break;
    }

    return {
      'derechos_vulnerados': derechosVulnerados,
      'normas_aplicables': normasAplicables,
      'pretensiones': pretensiones,
      'pruebas': pruebas,
      'juramento': juramento,
    };
  }
}
