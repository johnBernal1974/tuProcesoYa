class DerechoPeticionTemplate {
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
  final String patio;
  final String numeroSeguimiento;
  final String nombreAcudiente;

  DerechoPeticionTemplate({
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
    required this.patio,
    required this.numeroSeguimiento,
    required this.nombreAcudiente,
  });

  String generarTextoHtml() {
    return """
    <html>
      <body>        
        <b>$dirigido</b><br>
        <b>$entidad</b><br><br>
        Asunto: <b>Derecho de petición - $numeroSeguimiento</b>.<br>
        Ref: <b>$referencia</b>.<br><br>
        Yo, <b>$nombrePpl $apellidoPpl</b>, con número de identificación <b>$identificacionPpl</b>, NUI : <b>$nui</b>, TD : <b>$td</b> , PATIO : <b>$patio</b>, actualmente recluido en <b>$centroPenitenciario</b>, actuando en ejercicio del derecho de petición consagrado en el artículo 85 de la Constitución Política y la Ley 1755 de 2015, de manera respetuosa elevo a ustedes lo siguiente:<br><br>
        <b>I. Consideraciones</b><br>
        $consideraciones<br><br>
        <b>II. Fundamentos de derecho:</b><br>
        $fundamentosDeDerecho<br><br>
        <b>III. Petición concreta</b><br>
        $peticionConcreta<br><br><br>       
        Agradezco enormemente su colaboración y respuesta rápida y satisfactoria.<br><br><br><br>
        Atentamente,<br><br><br>
        <b>$nombrePpl $apellidoPpl</b><br>
        CC.$identificacionPpl<br>
        TD.$td<br>
        NUI.$nui<br>
        PATIO.$patio<br><br><br>
                
        Por favor enviar las notificaciones a la siguiente dirección electrónica:<br>
        $emailAlternativo<br>
        $emailUsuario<br>

        <div style="margin-top: 80px;">
          <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br><br>

          <b>NOTA IMPORTANTE:</b><br>
          <p style="font-size: 13px;">
            Esta solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>

            En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido.<br><br>

            Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.
          </p>
        </div>

      </body>
    </html>
    """;
  }
}
