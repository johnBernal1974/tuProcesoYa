class TrasladoProcesoTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String emailUsuario;
  final String emailAlternativo;
  final String radicado;
  final String jdc;
  final String numeroSeguimiento;
  final String situacion;
  final String fechaTraslado;
  final String centroOrigen;
  final String centroDestino;
  final String ciudadDestino;

  // Nuevos campos para En Reclusión
  final String nui;
  final String td;
  final String patio;

  TrasladoProcesoTemplate({
    required this.dirigido,
    required this.entidad,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.radicado,
    required this.jdc,
    required this.numeroSeguimiento,
    required this.situacion,
    required this.nui,
    required this.td,
    required this.patio,
    required this.fechaTraslado,
    required this.centroOrigen,
    required this.centroDestino,
    required this.ciudadDestino,
  });

  String convertirParrafos(String texto) {
    return texto
        .split('\n\n')
        .map((p) => '<p>${p.replaceAll('\n', '<br>')}</p>')
        .join();
  }

  String generarTextoHtml() {
    final buffer = StringBuffer();

    final textoSituacion = situacion == "En libertad condicional"
        ? "Actualmente me encuentro en libertad condicional, cumpliendo con las condiciones impuestas por la autoridad judicial y bajo supervisión del Estado."
        : "Actualmente me encuentro privado de la libertad en el establecimiento <b>$centroPenitenciario</b>, con NUI: <b>$nui</b>, TD: <b>$td</b>, y ubicado en el Patio No. <b>$patio</b>.";

    buffer.writeln("""
  <html>
    <body style="font-family: Arial, sans-serif;">
      <b>$dirigido</b><br>
      <b>$entidad</b><br><br>

      Referencia: <b>Derecho de petición</b><br>      
      Radicado del proceso: <b>$radicado</b><br>  
      Asunto: <b>Solicitud de traslado del proceso – $numeroSeguimiento</b><br><br>

      Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.<br><br>

      E.S.D.<br><br>

      Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, $textoSituacion, me permito formular la siguiente solicitud, previa exposición de los siguientes:

      <br><br><span style="font-size: 16px;"><b>I. HECHOS</b></span><br><br>     

      1. El día $fechaTraslado, fui trasladado del establecimiento penitenciario <b>$centroOrigen</b>, al establecimiento <b>$centroPenitenciario</b>, ubicado en la ciudad de <b>$ciudadDestino</b>.<br><br>

      2. A la fecha, mi proceso judicial no ha sido remitido al juzgado de ejecución de penas y medidas de seguridad competente en la ciudad de $ciudadDestino.<br><br>

      3. Esta situación ha generado una afectación a mi derecho al debido proceso y acceso a la administración de justicia, dado que carezco de un juez que vigile y tramite mis solicitudes relacionadas con la ejecución de la pena.<br><br>

      4. La falta de traslado del proceso impide que pueda acceder a beneficios administrativos y judiciales establecidos en la ley, como redenciones, permisos o solicitudes de libertad condicional.<br><br>

      <span style="font-size: 16px;"><b>II. PETICIÓN</b></span><br><br> 

      Solicito respetuosamente que se remita mi proceso de ejecución de la pena a los juzgados de ejecución de penas y medidas de seguridad de la ciudad de <b>$ciudadDestino</b>, correspondiente a mi actual lugar de reclusión: <b>$centroPenitenciario</b>.<br><br><br>

      Agradezco de antemano la atención prestada a la presente solicitud.<br><br><br>

      Para efectos de notificación, indico las siguientes direcciones electrónicas:<br>
      $emailAlternativo<br>
      $emailUsuario<br><br><br>

      Atentamente,<br><br><br>
      <b>$nombrePpl $apellidoPpl</b><br>
      CC: $identificacionPpl<br><br>

      <div style="margin-top: 40px;">
        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="160" height="50"/>

      </div>
    </body>
  </html>
  """);

    return buffer.toString();
  }

}
