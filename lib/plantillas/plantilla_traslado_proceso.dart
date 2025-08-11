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

  // En Reclusión
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
      
      Asunto: <b>Solicitud de traslado del proceso – $numeroSeguimiento</b><br>
      Radicado del proceso: <b>$radicado</b><br><br>

      Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.<br><br>

      <span style="color:#000;">
        En adición a lo anterior, fundamento esta solicitud en los artículos <b>29</b> y <b>229</b> de la Constitución Política (debido proceso y acceso a la administración de justicia); en los artículos <b>38 y ss.</b> de la <b>Ley 906 de 2004</b> (competencia y remisión al juez de ejecución de penas) y en los artículos <b>79</b> y <b>80</b> de la <b>Ley 65 de 1993</b> (funciones y vigilancia de la ejecución de la pena y beneficios). La Corte Constitucional ha reiterado que la demora injustificada en la remisión del expediente vulnera derechos fundamentales, ver, entre otras, las sentencias <b>T-153 de 2018</b> y <b>T-702 de 2016</b>.
      </span><br><br>

      <!-- 🔹 Síntesis jurisprudencial: explicativo corto -->
      <div style="background:#f7f7f7;border:1px solid #e3e3e3;padding:12px;border-radius:6px;">
        <b>Síntesis jurisprudencial:</b><br>
        La Corte Constitucional ha establecido que (i) la <b>demora injustificada</b> en remitir el expediente al juez competente <b>viola el debido proceso y el acceso a la justicia</b> (T-153 de 2018), y que (ii) tras un traslado, es <b>obligación</b> de las autoridades <b>remitir el proceso</b> al juez de ejecución de penas del nuevo lugar, evitando que la persona quede sin juez natural (T-702 de 2016).
      </div><br><br>

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
      CC: $identificacionPpl<br>
      TD. $td<br>
      NUI. $nui<br>
      PATIO. $patio<br><br>

      <div style="margin-top: 80px;">
        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br><br>

      <div style="margin-top: 40px; color: #444; font-size: 12px;">

        <b style="color: black;">NOTA IMPORTANTE</b><br><br>
        <p style="margin-top: 5px;">
          La presente solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>
          En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido. Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.
        </p>
      </div>
    </body>
  </html>
  """);

    return buffer.toString();
  }

}
