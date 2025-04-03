class TutelaTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String consideraciones;
  final String fundamentosDeDerecho;
  final String peticionConcreta;
  final String emailUsuario;
  final String emailAlternativo;
  final String nui;
  final String td;
  final String numeroSeguimiento;

  TutelaTemplate({
    required this.entidad,
    required this.dirigido,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.consideraciones,
    required this.fundamentosDeDerecho,
    required this.peticionConcreta,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.nui,
    required this.td,
    required this.numeroSeguimiento,
  });

  String generarTextoHtml() {
    return """
    <html>
      <body style='font-family: Arial, sans-serif; font-size: 14px; line-height: 1.6;'>        
        <p><b>$dirigido</b><br>
        <b>$entidad</b></p>

        <p>Asunto: <b>ACCIÓN DE TUTELA - $numeroSeguimiento</b><br>
        Referencia: <b>$referencia</b></p>

        <p>Me dirijo a usted en representación de <b>$nombrePpl $apellidoPpl</b>, con número de identificación <b>$identificacionPpl</b>, NUI: <b>$nui</b>, TD: <b>$td</b>, actualmente recluido en <b>$centroPenitenciario</b>, actuando en ejercicio de la <b>acción de tutela</b> consagrada en el artículo 86 de la Constitución Política, el Decreto 2591 de 1991 y demás normas concordantes, de manera respetuosa elevo a ustedes lo siguiente:</p>

        <p><b>I. Consideraciones</b><br>$consideraciones</p>

        <p><b>II. Fundamentos de derecho</b><br>$fundamentosDeDerecho</p>

        <p><b>III. Petición concreta</b><br>$peticionConcreta</p>

        <p>Por favor enviar las notificaciones a las siguientes direcciones electrónicas:<br>
        $emailAlternativo<br>
        $emailUsuario</p>

        <p>Agradezco enormemente su colaboración y respuesta rápida y satisfactoria.</p>

        <p>Atentamente,</p><br>

        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br>
        <a href='https://www.tuprocesoya.com'>www.tuprocesoya.com</a>

      </body>
    </html>
    """;
  }
}
