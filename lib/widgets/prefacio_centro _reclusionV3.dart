String generarPrefacioCentroReclusionV3({
  required String centroPenitenciario,
  required String nombrePpl,
  required String apellidoPpl,
  required String identificacionPpl,
  required String nui,
  required String td,
  required String patio,
  required String beneficioPenitenciario,
  required String juzgadoEp,

  // 👇 Nuevos datos del acudiente
  required String parentescoAcudiente,
  required String nombreAcudiente,
  required String apellidoAcudiente,
  required String identificacionAcudiente,
  String? celularAcudiente,
  String? celularWhatsapp,
}) {
  // Extraer solo la parte después del guion si existe
  String juzgadoLimpio = juzgadoEp.contains('-')
      ? juzgadoEp.split('-')[1].trim()
      : juzgadoEp.trim();

  return """
<div style="font-family: Arial, sans-serif; font-size: 15px;">

  <p style="margin:0;">
    <span style="font-size: 10pt; font-weight: normal;">Respetados Señores</span><br>
    <span style="font-size: 12pt; font-weight: 500;">Oficina Jurídica</span><br>
    <span style="font-size: 14pt; font-weight: bold; color: #000000;">$centroPenitenciario</span>
  </p>

  <p>
    <span style="color: #555555; font-weight: bold;">Asunto:</span><br>
    <span style="font-weight: bold; font-size: 14pt;">Solicitud de documentación para $beneficioPenitenciario</span>
  </p>

  <p>
    Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.
  </p>

  <!-- 🔁 Antes decía: "Yo, [PPL] ... actualmente recluido ..." -->
  <p>
    Yo, <b>$nombreAcudiente $apellidoAcudiente</b>, en calidad de <b>$parentescoAcudiente</b> de 
    <b>$nombrePpl $apellidoPpl</b> (C.C. <b>$identificacionPpl</b>), actualmente recluido en la 
    <b>$centroPenitenciario</b>, con NUI: <b>$nui</b>, TD: <b>$td</b>, ubicado en el Patio No: <b>$patio</b>, 
    me permito realizar la presente solicitud.
  </p><br><br>

  <p>
    Me permito informar que, ha sido presentada ante el <b>$juzgadoLimpio</b>, la solicitud de <b>$beneficioPenitenciario</b>. 
    Con el fin de que dicho despacho pueda resolver de manera oportuna y conforme a derecho, solicito respetuosamente que se remitan, con carácter urgente, directamente a esa autoridad judicial, los siguientes documentos:
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

  <!-- 🔁 Firma del acudiente -->
  <p>
    <b>$nombreAcudiente $apellidoAcudiente</b><br>
    C.C. $identificacionAcudiente<br>
    Parentesco: $parentescoAcudiente<br>
    ${ (celularAcudiente != null && celularAcudiente.isNotEmpty) ? "Celular: $celularAcudiente<br>" : "" }
    ${ (celularWhatsapp != null && celularWhatsapp.isNotEmpty) ? "WhatsApp: $celularWhatsapp<br>" : "" }
    <span style="color:#555;">Solicito en nombre de:</span><br>
    $nombrePpl $apellidoPpl – C.C. $identificacionPpl – TD: $td – NUI: $nui – Patio: $patio
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

</div>
""";
}
