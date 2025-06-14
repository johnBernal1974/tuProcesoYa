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
const OpenAI = require("openai");
const puppeteer = require("puppeteer");
const imaps = require("imap-simple");
const { simpleParser } = require("mailparser");
const { onSchedule } = require("firebase-functions/v2/scheduler");

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


// secrets de zoho
const ZOHO_USER = defineSecret("ZOHO_USER");
const ZOHO_PASSWORD = defineSecret("ZOHO_PASSWORD");
const ZOHO_HOST = defineSecret("ZOHO_HOST");
const ZOHO_CLIENT_ID = defineSecret("ZOHO_CLIENT_ID");
const ZOHO_CLIENT_SECRET = defineSecret("ZOHO_CLIENT_SECRET");
const ZOHO_REFRESH_TOKEN = defineSecret("ZOHO_REFRESH_TOKEN");


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

    if (["recarga", "peticion", "condicional", "domiciliaria", "tutela", "permiso", "extincion", "traslado", "redenciones", "acumulacion"].includes(tipoTransaccion) && status === "APPROVED") {
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
    const { to, cc, subject, html, archivos, idDocumento, enviadoPor, tipo = "derechos_peticion" } = req.body;

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

    const openai = new OpenAI({ apiKey: OPENAI_API_KEY.value() });

    const esTutela = (req.body.tipo || '').toLowerCase().trim() === 'tutela';

    let prompt = '';

    if (esTutela) {
      // 🔹 Redactar "Hechos" igual que "Consideraciones"
      prompt = `
Redacta la sección de "Hechos" de una acción de tutela en Colombia para una persona privada de la libertad (PPL).

🔒 Ya existe un encabezado con nombre, documento, centro penitenciario y entidad dirigida. No repitas esos datos.

🧠 Las respuestas fueron dadas por el propio usuario o por un acudiente (familiar, amigo o persona de confianza). Es posible que en las respuestas se use la tercera persona ("mi hermano", "mi padre", etc.).

✒️ Sin embargo, redacta el texto como si lo escribiera directamente la persona privada de la libertad, en **primera persona**: por ejemplo, "me encuentro recluido", "he padecido", "me han vulnerado".

⚠️ Interpreta correctamente que todo lo mencionado en las respuestas se refiere a la persona privada de la libertad, y no al acudiente.

🧠 Usa toda la información proporcionada para construir un bloque de hechos, con redacción jurídica clara, técnica y sin adornos emocionales ni despedidas.

No utilices o coloques el subtitulo de Hechos: al iniciar el texto y no nombres el centro penitenciario en el texto ya que eso ya esta definido en otra parte. No lo incluyas.

Respuestas del usuario:
${respuestasUsuario.map((r, i) => `• ${r}`).join("\n")}
      `.trim();

    } else if (respuestasUsuario.length > 0) {
      // 🔹 Redactar cuerpo completo del derecho de petición
      prompt = `
Redacta el cuerpo de un derecho de petición en Colombia para una persona privada de la libertad (PPL).

🔒 Ya existe un encabezado con nombre, documento y centro penitenciario: **no repitas esos datos**.

🧠 Las respuestas fueron dadas por un acudiente (familiar, amigo o persona de confianza), quien puede referirse al PPL en tercera persona ("mi hermano", "mi padre", etc.). Sin embargo, redacta el texto como si lo escribiera directamente la persona privada de la libertad, en primera persona. Interpreta correctamente que todo lo mencionado se refiere al PPL, y no al acudiente.

🧠 Usa toda la información proporcionada para construir una sección sólida de “Consideraciones”, redactada en primera persona, con lenguaje técnico, claro y sin adornos emocionales.

✒️ Estructura el documento con estos títulos (tal cual):

Consideraciones

Fundamentos de derecho

Petición concreta

📌 Fundamentos de derecho debe incluir:
- Fundamento en la Constitución Política (con número de artículo y descripción).
- Fundamento en la Ley 65 de 1993 o normas penitenciarias pertinentes.
- Jurisprudencia relevante: cita número de sentencia, año y criterio aplicable.

📌 Petición concreta:
- Redacta en primera persona, con precisión y claridad.
- Expón de forma concreta lo que solicito y si se está vulnerando o amenazando otro derecho.

Respuestas dadas por el acudiente:
${respuestasUsuario.map((r, i) => `• ${r}`).join("\n")}
      `.trim();

    } else {
      return res.status(400).json({ error: "Categoría o respuestas no válidas." });
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: "Eres un redactor legal colombiano. Redactas en primera persona, con precisión jurídica, sin adornos personales. Redacción clara, técnica y estructurada."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.6,
      max_tokens: 1200,
    });

    const texto = completion.choices[0].message.content?.trim() ?? '';
    console.log("🧠 respuestasUsuario recibidas:", respuestasUsuario);
    console.log("📝 Texto generado:", texto);

    if (esTutela) {
      return res.status(200).json({ hechos: texto });
    } else {
      const consideraciones = texto.split(/Fundamentos de derecho/i)[0]?.replace(/Consideraciones[:\s]*/i, '')?.trim() ?? '';
      const fundamentos = texto.match(/Fundamentos de derecho(.*?)Petición concreta/is)?.[1]?.trim() ?? '';
      const peticion = texto.split(/Petición concreta/i)[1]?.trim() ?? '';

      return res.status(200).json({
        consideraciones,
        fundamentos,
        peticion,
      });
    }

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

exports.leerCorreosZoho = onSchedule(
  {
    schedule: "every 10 minutes",
    secrets: [
      ZOHO_USER,
      ZOHO_PASSWORD,
      ZOHO_HOST,
      ZOHO_CLIENT_ID,
      ZOHO_CLIENT_SECRET,
      ZOHO_REFRESH_TOKEN,
    ],
    region: "us-central1",
  },
  async (event) => {
    const config = {
      imap: {
        user: ZOHO_USER.value(),
        password: ZOHO_PASSWORD.value(),
        host: ZOHO_HOST.value(),
        port: 993,
        tls: true,
        authTimeout: 3000,
      },
    };

    function limpiarHtml(html) {
      return html
        .replace(/<\s*html[^>]*>/gi, "")
        .replace(/<\s*\/\s*html\s*>/gi, "")
        .replace(/<\s*head[^>]*>.*?<\s*\/\s*head\s*>/gis, "")
        .replace(/<\s*body[^>]*>/gi, "")
        .replace(/<\s*\/\s*body\s*>/gi, "")
        .trim();
    }

    try {
      const connection = await imaps.connect(config);
      await connection.openBox("INBOX");

      const searchCriteria = ["UNSEEN"];
      const fetchOptions = {
        bodies: ["HEADER.FIELDS (FROM TO SUBJECT DATE)", "TEXT", ""],
        markSeen: true,
      };

      const results = await connection.search(searchCriteria, fetchOptions);

      for (const item of results) {
        const headerPart = item.parts.find(p => p.which.startsWith("HEADER"));
        const fullPart = item.parts.find(p => p.which === "");

        if (!fullPart || !fullPart.body) continue;

        const parsed = await simpleParser(fullPart.body);
        const headers = headerPart?.body || {};

        const remitente = parsed.from?.text || headers.from || "";
        const destinatario = parsed.to?.text || headers.to || "";
        const asunto = parsed.subject || headers.subject || "";
        const cuerpoHtml = parsed.html ? limpiarHtml(parsed.html) : "";
        const cuerpo = parsed.text?.trim() || "";
        const timestamp = new Date();
        const messageId = parsed.messageId || "";

        // ⚠️ Si no hay messageId, no guardar (opcional)
        if (!messageId) {
          console.warn("❌ Correo sin messageId, se omite.");
          continue;
        }

        // ✅ Verificar si ya existe
        const yaExiste = await db.collection("respuestas_correos")
          .where("messageId", "==", messageId)
          .limit(1)
          .get();

        if (!yaExiste.empty) {
          console.log("⚠️ Correo ya registrado:", messageId);
          continue;
        }

        // 1. Guardar en colección general
        await db.collection("respuestas_correos").add({
          remitente,
          destinatario,
          asunto,
          cuerpo,
          cuerpoHtml,
          recibidoEn: timestamp.toISOString(),
          messageId, // 🔒 Para evitar duplicados en el futuro
        });

        // 2. Buscar código de seguimiento en el asunto
        const regexCodigo = asunto.match(/-\s?(\d{6,})/);
        const codigoSeguimiento = regexCodigo ? regexCodigo[1] : null;

        if (codigoSeguimiento) {
          const posibles = await db.collectionGroup("log_correos").get();

          const coincidencias = posibles.docs.filter(doc =>
            typeof doc.data().subject === "string" &&
            doc.data().subject.includes(codigoSeguimiento)
          );

          if (coincidencias.length > 0) {
            const correoOriginal = coincidencias[0];
            const pathSolicitud = correoOriginal.ref.parent.parent;

            if (pathSolicitud) {
              await pathSolicitud.collection("log_correos").add({
                subject: "📩 Respuesta: " + asunto,
                remitente,
                destinatario,
                cuerpoHtml,
                timestamp,
                esRespuesta: true,
                messageId, // 🔒 También lo puedes registrar aquí
              });

              console.log(`✅ Respuesta archivada en log_correos de: ${pathSolicitud.id}`);
            } else {
              console.warn("❌ No se pudo obtener pathSolicitud para:", codigoSeguimiento);
            }
          } else {
            console.warn("❌ No se encontró coincidencia para el código:", codigoSeguimiento);
          }
        } else {
          console.warn("❌ No se encontró código de seguimiento en el asunto:", asunto);
        }
      }

      connection.end();
      console.log("✅ Correos procesados exitosamente.");
    } catch (error) {
      console.error("❌ Error leyendo correos Zoho:", error);
    }
  }
);









