class PrisionDomiciliariaTemplate {
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
  final String direccionDomicilio;
  final String municipio;
  final String departamento;
  final String nombreResponsable;
  final String cedulaResponsable;
  final String celularResponsable;
  final String emailUsuario;
  final String emailAlternativo;
  final String numeroSeguimiento;

  PrisionDomiciliariaTemplate({
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
    required this.direccionDomicilio,
    required this.municipio,
    required this.departamento,
    required this.nombreResponsable,
    required this.cedulaResponsable,
    required this.celularResponsable,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.numeroSeguimiento,
  });

  String generarTextoHtml() {
    return """
    <html>
      <body>
        <b>$dirigido</b><br>
        <b>$entidad</b><br><br>
        Asunto: <b>Solicitud de prisión domiciliaria - $numeroSeguimiento</b>.<br>
        Ref: <b>$referencia</b>.<br><br>
        Me dirijo a ustedes en representación de <b>$nombrePpl $apellidoPpl</b>, con número de identificación <b>$identificacionPpl</b>, actualmente recluido en <b>$centroPenitenciario</b>, para presentar formalmente solicitud de prisión domiciliaria, con base en lo siguiente:<br><br>

        <b>I. Consideraciones</b><br>
        $consideraciones<br><br>

        <b>II. Fundamentos de derecho:</b><br>
        $fundamentosDeDerecho<br><br>

        <b>III. Petición concreta</b><br>
        $peticionConcreta<br><br><br>

        <b>Información del domicilio donde se cumpliría la medida:</b><br>
        Dirección: <b>$direccionDomicilio</b>, <b>$municipio</b> - <b>$departamento</b><br>
        Nombre de la persona responsable: <b>$nombreResponsable</b><br>
        Número de identificación: <b>$cedulaResponsable</b><br>
        Número de celular: <b>$celularResponsable</b><br><br>        

        Agradezco enormemente su colaboración y respuesta rápida y satisfactoria.<br><br>
        
        Por favor enviar las notificaciones a la siguiente dirección electrónica:<br>
        $emailAlternativo<br>
        $emailUsuario<br><br><br>

        Atentamente,<br>
        <div style=\"margin-top: 80px;\">
          <img src=\"https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635\" width=\"150\" height=\"50\"><br>
        </div>
      </body>
    </html>
    """;
  }
}
