class ExtincionPenaTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String sinopsis;
  final String consideraciones;
  final String fundamentosDeDerecho;
  final String pretenciones;
  final String emailUsuario;
  final String emailAlternativo;
  final String radicado;
  final String delito;
  final String condena;
  final String purgado;
  final String jdc;
  final String numeroSeguimiento;
  final String situacion;

  // Nuevos campos para En Reclusión
  final String nui;
  final String td;
  final String patio;

  ExtincionPenaTemplate({
    required this.dirigido,
    required this.entidad,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.sinopsis,
    required this.consideraciones,
    required this.fundamentosDeDerecho,
    required this.pretenciones,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.radicado,
    required this.delito,
    required this.condena,
    required this.purgado,
    required this.jdc,
    required this.numeroSeguimiento,
    required this.situacion,
    required this.nui,
    required this.td,
    required this.patio,
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
        ? "Actualmente me encuentro en libertad condicional, cumpliendo con las condiciones impuestas por la autoridad judicial y bajo supervisión del Estado, como parte final del proceso de ejecución de la pena.."
        : "actualmente me encuentro recluido en el establecimiento <b>$centroPenitenciario</b>, con el NUI: <b>$nui</b>, TD: <b>$td</b> y ubicado en el Patio No: <b>$patio</b>.";

    buffer.writeln("""
    <html>
      <body>
        <b>$dirigido</b><br>
        <b>$entidad</b><br><br>

        Condenado: <b>$nombrePpl $apellidoPpl</b>.<br>
        Radicado del proceso: <b>$radicado</b>.<br>
        Delito: <b>$delito</b>.<br>
        Asunto: <b>Solicitud de Extinción de la pena - $numeroSeguimiento</b>.<br><br>

        “Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.”<br><br>
        E.S.D<br><br>

        Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con el número de cédula <b>$identificacionPpl</b>, $textoSituacion<br><br>

        <span style="font-size: 16px;"><b>I. SINOPSIS PROCESAL</b></span><br>
        ${convertirParrafos(sinopsis)}<br><br>

        <span style="font-size: 16px;"><b>II. CONSIDERACIONES</b></span><br>
        ${convertirParrafos(consideraciones)}<br><br>

        <span style="font-size: 16px;"><b>III. FUNDAMENTOS DE DERECHO</b></span><br>
        ${convertirParrafos(fundamentosDeDerecho)}<br><br>

        <span style="font-size: 16px;"><b>IV. PRETENSIONES</b></span><br>
        ${convertirParrafos(pretenciones)}<br><br>       

        Agradezco enormemente la atención prestada a la presente.<br><br><br>
        Por favor enviar las notificaciones a la siguiente dirección electrónica:<br>
        $emailAlternativo<br>
        $emailUsuario<br><br><br>

        Atentamente,<br><br><br>
        <b>$nombrePpl $apellidoPpl</b><br>
        CC. $identificacionPpl<br>
        <div style="margin-top: 50px;">
          <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br>
        </div>

        <b>NOTA IMPORTANTE</b><br>
        <p style="font-size: 13px;">
          Este mensaje también será enviado a la Oficina Jurídica del establecimiento <strong>$centroPenitenciario</strong>, con el fin de dejar constancia formal de esta solicitud y facilitar el inicio oportuno de los trámites correspondientes.
        </p>
      </body>
    </html>
    """);

    return buffer.toString();
  }
}
