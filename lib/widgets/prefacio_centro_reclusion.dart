String generarPrefacioCentroReclusionPorAcudiente({
  // Datos del centro / asunto (igual que tu base)
  required String centroPenitenciario,
  required String nombrePpl,
  required String apellidoPpl,
  required String identificacionPpl,
  required String nui,
  required String td,
  required String patio,
  required String beneficioPenitenciario,

  // 🔹 Datos del acudiente (de tu BD)
  required String parentescoAcudiente,   // parentesco_representante
  required String nombreAcudiente,       // nombre_acudiente
  required String apellidoAcudiente,     // apellido_acudiente
  required String celularAcudiente,      // celular
  required String whatsappAcudiente,     // celularWhatsapp
}) {
  return """
<div style="font-family: Arial, sans-serif; font-size: 15px;">

  <p><strong>Respetados Señores<br>
  Oficina Jurídica<br>
  $centroPenitenciario</strong></p>

  <p><b>Asunto:</b> Solicitud de documentación</p>

  <p>
    Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.
  </p>

  <p>
    Quien suscribe, <b>$nombreAcudiente $apellidoAcudiente</b>, en calidad de <b>$parentescoAcudiente</b> del privado de la libertad
    <b>$nombrePpl $apellidoPpl</b> (CC <b>$identificacionPpl</b>, NUI <b>$nui</b>, TD <b>$td</b>), recluido en <b>$centroPenitenciario</b>,
    Patio No. <b>$patio</b>, presento respetuosamente la siguiente solicitud:
  </p>

  <p>
    Me permito informar que el día de hoy ha sido presentada ante el Juzgado de Ejecución de Penas que vigila mi condena, la solicitud de <b>$beneficioPenitenciario</b>.
    Con el fin de que dicho despacho pueda resolver adecuadamente, respetuosamente solicito que se remitan con carácter urgente los siguientes documentos <b>ACTUALIZADOS</b>:
  </p><br>

  <ol>
    <li><b>Cartilla biográfica actualizada:</b> incluyendo datos personales, judiciales, penitenciarios, conducta y redenciones acumuladas.</li>
    <li><b>Certificación de tiempo redimido:</b> con detalle de días, tipo de actividad, fechas y modalidad.</li>
    <li><b>Certificado de buena conducta:</b> conforme al artículo 147 de la Ley 65 de 1993.</li>
    <li><b>Concepto del Consejo de Evaluación y Tratamiento:</b> sobre la solicitud y el proceso de resocialización.</li>
  </ol><br><br>

  <p>
    Agradezco de antemano la atención prestada a esta solicitud.
  </p>

  <p>Cordialmente,</p><br><br>

  <p>
    <b>$nombreAcudiente $apellidoAcudiente</b><br>
    <i>$parentescoAcudiente del interno $nombrePpl $apellidoPpl</i><br>
    Tel: $celularAcudiente<br>
    WhatsApp: $whatsappAcudiente
  </p><br><br>

  <div style="margin-top: 40px; color: #444; font-size: 12px;">
  <b style="color: black;">NOTA IMPORTANTE</b><br>
  <p style="margin-top: 5px;">
    
    La presente solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>

    En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido.  Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.<br><br>
  
  </p>

  <div style="margin-top: 30px;">
    <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="160" height="60" style="display: block;">
    <hr style="margin-top: 10px;">
    <p style="margin-top: 10px;"><i>Cito la solicitud realizada</i></p>
    <br><br>
  </div>

</div>
""";
}
