const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors");
const express = require("express");
const crypto = require("crypto");
const { defineSecret } = require("firebase-functions/params");
const { onRequest } = require("firebase-functions/v2/https");
const AWS = require("aws-sdk");
const { Buffer } = require("buffer");
const { getFirestore } = require("firebase-admin/firestore");
const OPENAI_API_KEY = defineSecret("OPENAI_API_KEY");
const puppeteer = require("puppeteer");


const WOMPI_PUBLIC_KEY = defineSecret("WOMPI_PUBLIC_KEY");
const WOMPI_INTEGRITY_SECRET = defineSecret("WOMPI_INTEGRITY_SECRET");

admin.initializeApp();
const db = admin.firestore();

// Firebase config secrets
const FIREBASE_API_KEY = defineSecret("FB_API_KEY");
const FIREBASE_AUTH_DOMAIN = defineSecret("FB_AUTH_DOMAIN");
const FIREBASE_PROJECT_ID = defineSecret("FB_PROJECT_ID");
const FIREBASE_STORAGE_BUCKET = defineSecret("FB_STORAGE_BUCKET");
const FIREBASE_APP_ID = defineSecret("FB_APP_ID");
const FIREBASE_MESSAGING_SENDER_ID = defineSecret("FB_MESSAGING_SENDER_ID");

let cachedConfig = null;
let lastFetchTime = 0;
const CACHE_DURATION_MS = 5 * 60 * 1000;

const app = express();
app.use(express.json());

app.post("/", async (req, res) => {
  try {
    const event = req.body;

    console.log("📩 Evento recibido de Resend:");
    console.log(JSON.stringify(event, null, 2));

    if (!event || !event.type || !event.data) {
      console.warn("❌ Evento inválido: falta type o data");
      return res.status(400).json({ error: "Evento inválido" });
    }

    const { type, data } = event;
    const timestamp = new Date();

    const messageId = data?.email_id || null;
    const recipient = Array.isArray(data?.to) ? data.to[0] : null;

    console.log(`📌 Tipo: ${type} | MessageID: ${messageId} | Destinatario: ${recipient}`);

    const eventosPermitidos = ["email.sent", "email.delivered", "email.bounced"];
    if (!eventosPermitidos.includes(type)) {
      console.log(`⚠️ Evento ignorado por tipo no permitido: ${type}`);
      return res.status(200).json({ ignored: true });
    }

    await db.collection("resend_eventos_basico").add({
      type,
      messageId,
      email: recipient,
      timestamp,
      tipo: "to",
    });

    console.log("📦 Evento guardado en 'resend_eventos_basico'");

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("❌ Error procesando webhook Resend:", error);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

exports.resendWebhook = functions.https.onRequest(app);

exports.getFirestoreConfig = onRequest({
  cors: true,
  secrets: [
    FIREBASE_API_KEY,
    FIREBASE_AUTH_DOMAIN,
    FIREBASE_PROJECT_ID,
    FIREBASE_STORAGE_BUCKET,
    FIREBASE_APP_ID,
    FIREBASE_MESSAGING_SENDER_ID,
  ],
}, async (req, res) => {
  try {
    const now = Date.now();
    if (!cachedConfig || now - lastFetchTime > CACHE_DURATION_MS) {
      cachedConfig = {
        apiKey: FIREBASE_API_KEY.value(),
        authDomain: FIREBASE_AUTH_DOMAIN.value(),
        projectId: FIREBASE_PROJECT_ID.value(),
        storageBucket: FIREBASE_STORAGE_BUCKET.value(),
        appId: FIREBASE_APP_ID.value(),
        messagingSenderId: FIREBASE_MESSAGING_SENDER_ID.value(),
      };
      lastFetchTime = now;
    }
    return res.status(200).json(cachedConfig);
  } catch (error) {
    return res.status(500).json({ error: "Error interno del servidor", details: error.message });
  }
});

exports.wompiWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const event = req.body;
    if (!event?.event || !event?.data?.transaction) {
      console.error("⚠️ Evento inválido recibido:", event);
      return res.status(400).json({ error: "Evento inválido recibido" });
    }

    const transaction = event.data.transaction;
    const { id: transactionId, status, reference, amount_in_cents, payment_method_type, created_at } = transaction;

    const referenceParts = reference.split("_");
    if (referenceParts.length < 3) {
      console.error("⚠️ Referencia inválida:", reference);
      return res.status(400).json({ error: "Referencia inválida" });
    }

    const tipoTransaccion = referenceParts[0];
    const userId = referenceParts[1];
    const userRef = db.collection("Ppl").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.error("⚠️ No se encontró el usuario con ID:", userId);
      return res.status(404).json({ error: "Usuario no encontrado en Firestore" });
    }

    const amount = amount_in_cents / 100;
    const recargaRef = db.collection("recargas").doc(transactionId);
    await recargaRef.set({
      userId,
      amount,
      status,
      paymentMethod: payment_method_type,
      transactionId,
      reference,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(created_at)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const saldoActual = userDoc.data().saldo || 0;
    const nuevoSaldo = saldoActual + amount;

    if (tipoTransaccion === "suscripcion" && status === "APPROVED") {
      await userRef.update({ isPaid: true });
    }

    if (["recarga", "peticion"].includes(tipoTransaccion) && status === "APPROVED") {
      await userRef.update({ saldo: nuevoSaldo });
    }

    return res.status(200).json({ message: "Estado de pago actualizado con éxito y guardado en recargas" });
  } catch (error) {
    console.error("🚨 Error en el webhook de Wompi:", error);
    return res.status(500).json({ error: "Error procesando el webhook", details: error.message });
  }
});

exports.wompiCheckoutUrl = onRequest({
  cors: true,
  secrets: ["WOMPI_PUBLIC_KEY", "WOMPI_INTEGRITY_SECRET"],
}, async (req, res) => {
  try {
    console.log("📥 Headers:", req.headers);
    console.log("📥 Body (raw):", JSON.stringify(req.body));

    if (!req.body || typeof req.body !== "object") {
      return res.status(400).json({ error: "Cuerpo de solicitud inválido" });
    }

    const { referencia, monto } = req.body;

    console.log("📥 Datos recibidos:", req.body);

    if (!referencia || typeof referencia !== "string") {
      return res.status(400).json({ error: "Referencia faltante o inválida" });
    }

    if (typeof monto !== "number" || monto % 1 !== 0) {
      return res.status(400).json({ error: "El monto debe ser un número entero en centavos" });
    }

    if (!WOMPI_PUBLIC_KEY.value() || !WOMPI_INTEGRITY_SECRET.value()) {
      return res.status(500).json({ error: "Variables de entorno no configuradas" });
    }

    const moneda = "COP";
    const publicKey = WOMPI_PUBLIC_KEY.value().replace(/"/g, "");
    const cadena = `${referencia}${monto}${moneda}${WOMPI_INTEGRITY_SECRET.value()}`;
    const firma = crypto.createHash("sha256").update(cadena).digest("hex");

    const queryParams = new URLSearchParams({
      currency: moneda,
      "amount-in-cents": monto.toString(),
      reference: referencia,
      "public-key": publicKey,
      "signature:integrity": firma,
    });

    const url = `https://checkout.wompi.co/p/?${queryParams.toString()}`;

    console.log("✅ URL generada:", url);

    return res.status(200).json({ url });
  } catch (error) {
    console.error("❌ Error generando URL de Wompi:", error);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

const pdf = require("html-pdf-node");

exports.sendEmailWithResend = onRequest({
  secrets: ["RESEND_API_KEY"],
  runtime: "nodejs22",
  memory: "512MiB",
  timeoutSeconds: 60,
}, async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") return res.status(204).send("");

  try {
    const { to, cc, subject, html, archivos, idDocumento, enviadoPor, tipo = "derecho_peticion" } = req.body;

    if (!to || !subject || !html || !idDocumento || !enviadoPor) {
      return res.status(400).json({ error: "Faltan campos obligatorios" });
    }

    const normalize = val => Array.isArray(val) ? val : val ? [val] : [];
    const toList = normalize(to);
    const ccList = normalize(cc);

    const attachments = (archivos || []).map(a => ({
      content: a.base64,
      filename: a.nombre,
      type: a.tipo || "application/octet-stream"
    }));

    const payload = {
      from: "Tu Proceso Ya <peticiones@tuprocesoya.com>",
      to: toList,
      cc: ccList.length ? ccList : undefined,
      subject,
      html,
      attachments
    };

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const raw = await response.text();
    if (!response.ok) return res.status(500).json({ error: raw });

    let result = {};
    try { result = JSON.parse(raw); } catch {}

    const bucket = admin.storage().bucket();
    const timestamp = new Date().toISOString();

    const htmlPath = `${tipo}/${idDocumento}/correos_enviados/correo-${timestamp}.html`;
    await bucket.file(htmlPath).save(Buffer.from(html, "utf-8"), {
      metadata: { contentType: "text/html; charset=utf-8" }
    });
    await bucket.file(htmlPath).makePublic();
    const htmlUrl = `https://storage.googleapis.com/${bucket.name}/${htmlPath}`;

    let pdfUrl = null;
    try {
      const fechaEnvioTexto = new Date().toLocaleString('es-CO', { timeZone: 'America/Bogota', day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
      const listaAdjuntos = archivos?.length
        ? `<div class="adjuntos"><b>Archivos adjuntos:</b><ul>${archivos.map(a => `<li>${a.nombre}</li>`).join('')}</ul></div>`
        : "";

      const styledHtml = `
        <html>
        <head>
          <meta charset="utf-8" />
          <style>
            @page {
              margin: 100px 100px 120px 100px;
            }
            body {
              font-family: Arial, sans-serif;
              font-size: 13px;
              color: #333;
              line-height: 1.6;
              padding-top: 20px;
            }
            .header {
              margin-bottom: 30px;
            }
            .dato {
              font-size: 12px;
              font-weight: bold;
              margin-bottom: 4px;
            }
            .dato span {
              font-weight: normal;
            }
            .asunto {
              font-size: 15px;
              font-weight: bold;
              margin: 6px 0;
            }
            .fecha {
              color: #444;
              font-size: 12px;
            }
            .divider {
              border-bottom: 1px solid #ccc;
              margin: 15px 0;
            }
            .adjuntos {
              margin-top: 10px;
              font-size: 13px;
            }
            .adjuntos ul {
              padding-left: 20px;
              margin-top: 4px;
            }
            footer {
              font-size: 11px;
              color: #666;
              text-align: center;
              position: fixed;
              bottom: 30px;
              left: 60px;
              right: 60px;
            }
          </style>
        </head>
        <body>
          <div class="header">
            <div class="dato">De: <span>Tu Proceso Ya &lt;peticiones@tuprocesoya.com&gt;</span></div>
            <div class="dato">Para: <span>${toList.join(', ')}</span></div>
            ${ccList.length ? `<div class="dato">CC: <span>${ccList.join(', ')}</span></div>` : ""}
            <div class="asunto">${subject}</div>
            <div class="fecha">Fecha de envío: ${fechaEnvioTexto}</div>
            <div class="divider"></div>
          </div>
          ${html}
          ${listaAdjuntos}
          <footer>www.tuprocesoya.com • Documento generado por Tu Proceso Ya</footer>
        </body>
        </html>
      `;

      const pdfBuffer = await pdf.generatePdf({ content: styledHtml }, { format: 'Legal' });
      const pdfPath = `${tipo}/${idDocumento}/correos_enviados/correo-${timestamp}.pdf`;
      await bucket.file(pdfPath).save(pdfBuffer, { metadata: { contentType: "application/pdf" } });
      await bucket.file(pdfPath).makePublic();
      pdfUrl = `https://storage.googleapis.com/${bucket.name}/${pdfPath}`;
    } catch (err) {
      console.warn("⚠️ PDF error:", err);
    }

    await db
      .collection(`${tipo}_solicitados`)
      .doc(idDocumento)
      .collection("log_correos")
      .add({
        to: toList,
        cc: ccList,
        subject,
        html,
        htmlUrl,
        pdfUrl,
        archivos: archivos?.map(a => ({ nombre: a.nombre })),
        enviadoPor,
        messageId: result.id || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

    return res.status(200).json({ success: true });
  } catch (err) {
    console.error("❌ Error:", err);
    return res.status(500).json({ error: "Error enviando correo" });
  }
});



exports.generarTextoIAExtendido = onRequest({
  cors: true,
  secrets: [OPENAI_API_KEY],
}, async (req, res) => {
  try {
    const { categoria, subcategoria, respuestasUsuario = [] } = req.body;

    if (typeof categoria !== 'string' || categoria.trim() === '' ||
        typeof subcategoria !== 'string' || subcategoria.trim() === '') {
      return res.status(400).json({ error: "Faltan campos requeridos" });
    }

    let prompt = '';

    if (respuestasUsuario.length > 0) {
      // 🔹 Prompt tradicional para derechos de petición con narrativa del acudiente
      prompt = `
Redacta el cuerpo de un derecho de petición en Colombia para una persona privada de la libertad.

🔒 Ya existe un encabezado con nombre, documento y centro penitenciario: **no repitas esos datos**.

🧠 El relato fue escrito por un acudiente (familiar, amigo o persona de confianza), quien describe la situación del PPL en primera persona ("mi hermano", "mi padre", etc.). Interpreta correctamente el texto: **todo lo que se menciona se refiere exclusivamente a la persona privada de la libertad, no al acudiente.**

🧠 Usa toda la información proporcionada para construir una sección sólida de “Consideraciones”, redactada en tercera persona, con lenguaje técnico, claro y sin adornos personales.

✒️ Estructura el documento con estos títulos (tal cual):

Consideraciones
Fundamentos de derecho
Petición concreta

📌 Fundamentos de derecho debe incluir:
- Fundamento en la Constitución Política (con número de artículo y descripción).
- Fundamento en la Ley 65 de 1993 o normas penitenciarias pertinentes.
- Jurisprudencia relevante: cita número de sentencia, año y criterio aplicable.

📌 En la Petición concreta:
- Redacta con precisión y claridad.
- Incluye si hay otro derecho que también esté en riesgo o se vulnera.

Respuestas dadas por el acudiente:
${respuestasUsuario.map((r, i) => `• ${r}`).join("\n")}
      `.trim();
    } else {
      // 🔹 Prompt adaptado según subcategoría sin respuestas
      switch (subcategoria.toLowerCase()) {
        case 'prisión domiciliaria':
          // Prompt dentro del Cloud Function:
          prompt = `
          Redacta un documento jurídico en Colombia que respalde una solicitud de prisión domiciliaria para una persona privada de la libertad (PPL), exclusivamente por **cumplimiento del tiempo de condena** como requisito legal.

          🔒 Ya existe un encabezado con los datos del solicitante: no repitas nombre, número de documento ni centro de reclusión.

          ✒️ Estructura el texto legal con los siguientes títulos, escritos tal cual y separados con una línea en blanco entre secciones:

          Consideraciones

          Fundamentos de derecho

          Petición concreta

          📌 Consideraciones:
          - Señala que el PPL ha cumplido con más del 50% de la condena impuesta, requisito exigido por la legislación para acceder a este beneficio.
          - Indica que el delito por el cual fue condenado **no se encuentra excluido** de los beneficios establecidos en el artículo 38G del Código Penal u otras normas restrictivas.
          - Expón que el PPL cuenta con un lugar de residencia fijo y un entorno familiar que respalda su proceso de resocialización y compromiso con la justicia.
          - Señala que se adjuntan los documentos de soporte que acreditan la viabilidad de la medida, tales como:
            - Dirección exacta del domicilio donde cumpliría la medida,
            - Nombre y documento de identidad de la persona responsable en el hogar,
            - Declaración juramentada que acredita su voluntad de asumir dicha responsabilidad.
          - Usa un lenguaje técnico, claro y en tercera persona, sin adornos ni elementos personales.

          📌 Fundamentos de derecho:
          - Incluye fundamentos en la Constitución Política de Colombia (artículos relevantes).
          - Incluye la Ley 65 de 1993 (Código Penitenciario y Carcelario) y sus reglamentos aplicables.
          - Cita jurisprudencia de la Corte Constitucional y Corte Suprema relacionada con prisión domiciliaria y sustitución de la pena.
          - Si aplica, incluye normas internacionales o tratados ratificados por Colombia que respalden el respeto por los derechos del PPL.

          📌 Petición concreta:
          - Solicita expresamente la sustitución de la pena privativa de la libertad por prisión domiciliaria, de forma clara, precisa y técnica.
          - No incluyas despedidas, agradecimientos, firmas, nombres ni frases como "en espera de respuesta" o "atentamente".

          🔎 No incluyas asteriscos (*), saltos de página, adornos innecesarios ni repitas datos ya conocidos del solicitante.
          `.trim();

          break;

        case 'libertad condicional':
          prompt = `
Redacta un documento jurídico en Colombia para una **solicitud de libertad condicional** para una persona privada de la libertad (PPL), conforme a los requisitos legales y penitenciarios.

Estructura el contenido con los siguientes apartados:

Consideraciones
Fundamentos de derecho
Petición concreta

📌 Consideraciones:
- Argumenta por qué el PPL ha cumplido con los requisitos de tiempo, conducta y resocialización.

📌 Fundamentos de derecho:
- Constitución Política, Ley 65 de 1993 y otras normas penitenciarias aplicables.
- Jurisprudencia que respalde la concesión de este beneficio.

📌 Petición concreta:
- Solicita formalmente la libertad condicional indicando el cumplimiento de requisitos legales.
          `.trim();
          break;

        case 'permiso de 72 horas':
          prompt = `
Redacta un documento jurídico en Colombia que sustente una **solicitud de permiso de 72 horas** para una persona privada de la libertad (PPL).

🔒 No repitas encabezado ni datos básicos del solicitante.

Estructura el texto con estos apartados:

Consideraciones
Fundamentos de derecho
Petición concreta

📌 Consideraciones:
- Expón los motivos humanitarios, familiares o médicos que justifican el permiso.
- Usa lenguaje técnico y claro.

📌 Fundamentos de derecho:
- Cita la Ley 65 de 1993, reglamentos y sentencias que permitan este permiso.

📌 Petición concreta:
- Solicita de forma clara la autorización del permiso de 72 horas y su duración.
          `.trim();
          break;

        default:
          return res.status(400).json({ error: "Subcategoría no soportada" });
      }
    }

    const OpenAI = require("openai");
    const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        { role: "system", content: "Eres un redactor legal colombiano. Redactas en tercera persona, con precisión jurídica, sin adornos personales. Redacción clara, técnica y estructurada." },
        { role: "user", content: prompt }
      ],
      temperature: 0.6,
      max_tokens: 1200,
    });

    const texto = completion.choices[0].message.content ?? '';

    const consideraciones = texto.split(/Fundamentos de derecho/i)[0]
      ?.replace(/Consideraciones[:\s]*/i, '')
      ?.trim() ?? '';

    const fundamentos = texto.match(/Fundamentos de derecho(.*?)Petición concreta/is)?.[1]?.trim() ?? '';
    const peticion = texto.split(/Petición concreta/i)[1]?.trim() ?? '';

    return res.status(200).json({
      consideraciones,
      fundamentos,
      peticion,
    });

  } catch (error) {
    console.error("❌ Error en generarTextoIAExtendido:", error);
    return res.status(500).json({
      error: "Error generando texto IA extendido",
      message: error.message,
      stack: error.stack,
    });
  }
});

exports.eliminarUsuarioAuthHttp = functions.https.onRequest(async (req, res) => {
  const { uid, token } = req.body;

  // 🔐 Protege con un token secreto (muy simple pero útil)
  const TOKEN_SECRETO = "clave-super-secreta-123"; // cámbialo por una más segura
  if (token !== TOKEN_SECRETO) {
    return res.status(403).json({ error: "No autorizado" });
  }

  if (!uid) {
    return res.status(400).json({ error: "Falta el UID" });
  }

  try {
    await admin.auth().deleteUser(uid);
    console.log(`✅ Usuario eliminado correctamente (HTTP): ${uid}`);
    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("❌ Error al eliminar usuario:", error);
    return res.status(500).json({ error: "Error al eliminar usuario" });
  }
});



