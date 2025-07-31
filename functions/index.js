const functions = require("firebase-functions");
const admin = require("firebase-admin");
//const cors = require("cors");
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
const WOMPI_PUBLIC_KEY_SANDBOX = defineSecret("WOMPI_PUBLIC_KEY_SANDBOX");
const WOMPI_INTEGRITY_SECRET_SANDBOX = defineSecret("WOMPI_INTEGRITY_SECRET_SANDBOX");
const FormData = require('form-data');
const axios = require("axios");
//Se coloco para probar el enviod e imagens en whatsapp
const fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));
const cors = require("cors")({ origin: true });


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

    if (["recarga", "peticion", "condicional", "domiciliaria", "tutela", "permiso", "extincion", "traslado", "redenciones", "acumulacion", "apelacion", "readecuacion", "trasladoPenitenciaria", "copiaSentencia"].includes(tipoTransaccion) && status === "APPROVED") {
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
  secrets: ["WOMPI_PUBLIC_KEY", "WOMPI_INTEGRITY_SECRET", "WOMPI_PUBLIC_KEY_SANDBOX", "WOMPI_INTEGRITY_SECRET_SANDBOX"],
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

    const moneda = "COP";

    // 🚩 Extraer el userId de la referencia (ej: "apelacion_userId_uuid")
    const referenceParts = referencia.split("_");
    let userId = referenceParts.length >= 2 ? referenceParts[1] : null;

    console.log("✅ userId detectado:", userId);

    // 🚩 Validar que las variables existan
    if (
      !WOMPI_PUBLIC_KEY.value() ||
      !WOMPI_INTEGRITY_SECRET.value() ||
      !WOMPI_PUBLIC_KEY_SANDBOX.value() ||
      !WOMPI_INTEGRITY_SECRET_SANDBOX.value()
    ) {
      return res.status(500).json({ error: "Variables de entorno no configuradas" });
    }

    let publicKey;
    let integritySecret;

    // 🚩 Verifica si es un userId específico que quieres enviar a sandbox
    if (userId === "KT9nShnvD0PztXyoZx6VB3aLtDi1") {
      console.log("🚧 Usando credenciales SANDBOX para este usuario");
      publicKey = WOMPI_PUBLIC_KEY_SANDBOX.value().replace(/"/g, "");
      integritySecret = WOMPI_INTEGRITY_SECRET_SANDBOX.value();
    } else {
      publicKey = WOMPI_PUBLIC_KEY.value().replace(/"/g, "");
      integritySecret = WOMPI_INTEGRITY_SECRET.value();
    }

    const cadena = `${referencia}${monto}${moneda}${integritySecret}`;
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

const VERIFY_TOKEN = "miverificatuproceso";

exports.webhookWhatsapp = functions.https.onRequest(async (req, res) => {
  // 1️⃣ Verificación del webhook
  if (req.method === "GET") {
    const mode = req.query["hub.mode"];
    const token = req.query["hub.verify_token"];
    const challenge = req.query["hub.challenge"];

    if (mode && token) {
      if (mode === "subscribe" && token === VERIFY_TOKEN) {
        console.log("✅ Webhook verificado correctamente");
        return res.status(200).send(challenge);
      } else {
        console.error("❌ Error de verificación.");
        return res.sendStatus(403);
      }
    }
  }

  // 2️⃣ Procesar mensajes entrantes
  if (req.method === "POST") {
    try {
      const body = req.body;

      if (
        body.object &&
        body.entry &&
        body.entry[0].changes &&
        body.entry[0].changes[0].value.messages
      ) {
        const messageData = body.entry[0].changes[0].value.messages[0];
        const from = messageData.from;
        const id = messageData.id;

        // 🟢 Capturar perfil si viene
        const contactProfile = body.entry[0].changes[0].value.contacts?.[0]?.profile;
        const profilePicUrl = contactProfile?.profile_pic_url || null;
        const profileName = contactProfile?.name || null;

        let text = "(sin contenido)";
        let mediaType = null;
        let mediaId = null;
        let fileName = null;

        if (messageData.text) {
          text = messageData.text.body;
        } else if (messageData.image) {
          text = "(Imagen)";
          mediaType = "image";
          mediaId = messageData.image.id;
        } else if (messageData.audio) {
          text = "(Audio)";
          mediaType = "audio";
          mediaId = messageData.audio.id;
        } else if (messageData.document) {
          text = "(Documento)";
          mediaType = "document";
          mediaId = messageData.document.id;
          fileName = messageData.document.filename || "Documento.pdf";
        }

        // 1️⃣ Guardar mensaje individual
        await admin.firestore().collection("whatsapp_messages").add({
          from: from,
          conversationId: from,
          text: text,
          mediaType: mediaType,
          mediaId: mediaId,
          fileName: fileName,
          messageId: id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isRead: false,
        });

        // 2️⃣ Actualizar o crear resumen de conversación con foto y nombre
        await admin.firestore().collection("whatsapp_conversations").doc(from).set(
          {
            conversationId: from,
            lastMessage: text,
            lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
            hasUnread: true,
            profilePicUrl: profilePicUrl,
            profileName: profileName,
          },
          { merge: true }
        );

        console.log(`✅ Mensaje procesado de ${from}: ${text} (${mediaType || "texto"})`);
      }

      return res.sendStatus(200);
    } catch (error) {
      console.error("❌ Error procesando mensaje:", error);
      return res.sendStatus(500);
    }
  }

  // Si no es GET ni POST
  return res.sendStatus(405);
});


exports.getMediaFile = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  const mediaId = req.query.mediaId;
  if (!mediaId) {
    return res.status(400).send("mediaId requerido");
  }

  try {
    // 1. Obtener URL temporal
    const meta = await axios.get(
      `https://graph.facebook.com/v19.0/${mediaId}`,
      {
        headers: {
          Authorization: `Bearer ${ACCESS_TOKEN}`,
        },
      }
    );

    const url = meta.data.url;
    const mime = meta.data.mime_type;

    // 2. Descargar el binario
    const mediaRes = await axios.get(url, {
      headers: {
        Authorization: `Bearer ${ACCESS_TOKEN}`,
      },
      responseType: 'arraybuffer',
    });

    // 3. Devolver el contenido binario
    res.set('Content-Type', mime);
    return res.status(200).send(Buffer.from(mediaRes.data, 'binary'));
  } catch (err) {
    console.error("Error:", err.response?.data || err);
    return res.status(500).send("Error obteniendo media");
  }
});

const ACCESS_TOKEN = "EAAKuB3bxKBcBOxiZBRGZAZCHTE6OVxxbDywdbrIQb9KIYnPS3kAu0XIjxbNBD59B2YZAd2QeXn8QZAldHMoFA0sdFFCWcM4BfqlA019owk5dZBJeLTenkVNjvXdQFa1mxZBled7vL1yKGS2Plu8o3OJPeZCODAoNc5uf9Q0onDb6QWMZCIVvOUOWQKdcDSXrFE5ZAL8AZDZD";
const PHONE_NUMBER_ID = "724376300739509";

exports.sendActivationMessage = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const { to, docId } = req.body;

  if (!to || !docId) {
    return res.status(400).json({ error: "Debe proporcionar 'to' y 'docId'" });
  }

  // 1️⃣ Obtener datos de Firestore
  let acudienteNombre = "";
  let pplNombre = "";

  try {
    const docRef = admin.firestore().collection("Ppl").doc(docId);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(404).json({ error: "Documento no encontrado en Firestore" });
    }

    const data = docSnap.data();
    acudienteNombre = data.nombre_acudiente || "";
    pplNombre = data.nombre_ppl || "";

  } catch (err) {
    console.error("Error leyendo Firestore:", err);
    return res.status(500).json({ error: "Error leyendo Firestore" });
  }

  // 2️⃣ Construir body
  const body = {
    messaging_product: "whatsapp",
    to: to,
    type: "template",
    template: {
      name: "usuario_activado",
      language: { code: "es_CO" },
      components: [
        {
          type: "header",
          parameters: [
            {
              type: "image",
              image: {
                link: "https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635"
              }
            }
          ]
        },
        {
          type: "body",
          parameters: [
            {
              type: "text",
              text: acudienteNombre
            },
            {
              type: "text",
              text: pplNombre
            }
          ]
        }
      ]
    }
  };

  const url = `https://graph.facebook.com/v20.0/${PHONE_NUMBER_ID}/messages`;

  try {
    const response = await fetch(url, {
      method: "POST",
      body: JSON.stringify(body),
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ACCESS_TOKEN}`
      }
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Error de la API:", result);
      return res.status(500).json({ error: "Error al enviar el mensaje", details: result });
    }

    console.log("Mensaje enviado correctamente:", result);
    return res.json({ success: true, result });

  } catch (error) {
    console.error("Error en la función:", error);
    return res.status(500).json({ error: error.message });
  }
});

exports.sendNewRedencionMessage = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const { to, docId } = req.body;

  if (!to || !docId) {
    return res.status(400).json({ error: "Debe proporcionar 'to' y 'docId'" });
  }

  // 🔹 1️⃣ Leer datos de Firestore
  let acudienteNombre = "";
  let pplNombre = "";

  try {
    const docRef = admin.firestore().collection("Ppl").doc(docId);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(404).json({ error: "Documento no encontrado en Firestore" });
    }

    const data = docSnap.data();
    acudienteNombre = data.nombre_acudiente || "";
    pplNombre = data.nombre_ppl || "";

  } catch (err) {
    console.error("Error leyendo Firestore:", err);
    return res.status(500).json({ error: "Error leyendo Firestore" });
  }

  // 🔹 2️⃣ Construir el body del mensaje
  const body = {
    messaging_product: "whatsapp",
    to: to,
    type: "template",
    template: {
      name: "nueva_redencion", // 👈 Nombre exacto de tu plantilla
      language: { code: "es_CO" },
      components: [
        {
          type: "body",
          parameters: [
            {
              type: "text",
              text: acudienteNombre
            },
            {
              type: "text",
              text: pplNombre
            }
          ]
        }
      ]
    }
  };

  const url = `https://graph.facebook.com/v20.0/${PHONE_NUMBER_ID}/messages`;

  try {
    const response = await fetch(url, {
      method: "POST",
      body: JSON.stringify(body),
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ACCESS_TOKEN}`
      }
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Error de la API:", result);
      return res.status(500).json({ error: "Error al enviar el mensaje", details: result });
    }

    console.log("Mensaje de redención enviado correctamente:", result);
    return res.json({ success: true, result });

  } catch (error) {
    console.error("Error en la función:", error);
    return res.status(500).json({ error: error.message });
  }
});

//Funcion para notificar el envio del correo de la solicitud
exports.sendNewSolicitudMessage = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  // Aquí logeas todo lo que llega
  console.log("Datos recibidos:", req.body);

  const { to, docId, servicio, seguimiento } = req.body;

  if (!to || !docId || !servicio || !seguimiento) {
    return res.status(400).json({
      error: "Debe proporcionar 'to', 'docId', 'servicio' y 'seguimiento'",
    });
  }

  // 🔹 Leer datos Firestore
  let acudienteNombre = "";
  let pplNombre = "";

  try {
    const docRef = admin.firestore().collection("Ppl").doc(docId);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      return res.status(404).json({ error: "Documento no encontrado en Firestore" });
    }

    const data = docSnap.data();
    acudienteNombre = data.nombre_acudiente || "";
    pplNombre = data.nombre_ppl || "";

  } catch (err) {
    console.error("Error leyendo Firestore:", err);
    return res.status(500).json({ error: "Error leyendo Firestore" });
  }

  // 🔹 Construir el body del mensaje
  const body = {
    messaging_product: "whatsapp",
    to: to,
    type: "template",
    template: {
      name: "envio_mensaje_correo",
      language: { code: "es_CO" },
      components: [
        {
          type: "header",
          parameters: [
            {
              type: "image",
              image: {
                link: "https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635"
              }
            }
          ]
        },
        {
          type: "body",
          parameters: [
            { type: "text", text: acudienteNombre },
            { type: "text", text: servicio },
            { type: "text", text: seguimiento },
            { type: "text", text: pplNombre }
          ]
        }
      ]
    }
  };

  const url = `https://graph.facebook.com/v20.0/${PHONE_NUMBER_ID}/messages`;

  try {
    const response = await fetch(url, {
      method: "POST",
      body: JSON.stringify(body),
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ACCESS_TOKEN}`
      }
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Error de la API:", result);
      return res.status(500).json({ error: "Error al enviar el mensaje", details: result });
    }

    console.log("Mensaje enviado correctamente:", result);
    return res.json({ success: true, result });

  } catch (error) {
    console.error("Error en la función:", error);
    return res.status(500).json({ error: error.message });
  }
});

//para el envio de mensajes de respuesta a correos
exports.sendRespuestaSolicitudMessage = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") return res.status(204).send("");
  if (req.method !== "POST") return res.status(405).send("Method Not Allowed");

  const { to, docId, tipoSolicitud, numeroSeguimiento, seccionHistorial } = req.body;

  if (!to || !docId || !tipoSolicitud || !numeroSeguimiento || !seccionHistorial) {
    return res.status(400).json({
      error: "Faltan datos. Se requiere: 'to', 'docId', 'tipoSolicitud', 'numeroSeguimiento', 'seccionHistorial'"
    });
  }

  let acudienteNombre = "";

  try {
    // 🔹 Determinar la colección del servicio
    let collectionName = "";
    switch (tipoSolicitud.toLowerCase()) {
      case "readecuación":
        collectionName = "readecuacion_solicitados";
        break;
      case "domiciliaria":
        collectionName = "domiciliaria_solicitados";
        break;

      default:
        return res.status(400).json({ error: `No se reconoce el tipo de solicitud: ${tipoSolicitud}` });
    }

    // 🔹 Obtener documento del servicio (para obtener idUser)
    const docRefServicio = admin.firestore().collection(collectionName).doc(docId);
    const docSnapServicio = await docRefServicio.get();

    if (!docSnapServicio.exists) {
      return res.status(404).json({ error: `Documento no encontrado en ${collectionName}` });
    }

    const dataServicio = docSnapServicio.data();
    const celularResponsable = dataServicio.celularResponsable || to;
    const idUser = dataServicio.idUser;

    if (!idUser) {
      return res.status(400).json({ error: "No se encontró el campo idUser en el documento del servicio" });
    }

    // 🔹 Obtener acudiente desde Ppl usando idUser
    const docRefPpl = admin.firestore().collection("Ppl").doc(idUser);
    const docSnapPpl = await docRefPpl.get();

    if (!docSnapPpl.exists) {
      return res.status(404).json({ error: "Usuario no encontrado en la colección Ppl" });
    }

    const dataPpl = docSnapPpl.data();
    acudienteNombre = dataPpl.nombre_acudiente || "";

    // 🔹 Construir cuerpo del mensaje
    const body = {
      messaging_product: "whatsapp",
      to: celularResponsable.startsWith("57") ? celularResponsable : `57${celularResponsable}`,
      type: "template",
      template: {
        name: "respuesta_correo", // Asegúrate que este sea el nombre exacto de la plantilla en Meta
        language: { code: "es_CO" },
        components: [
          {
            type: "header",
            parameters: [
              {
                type: "image",
                image: {
                  link: "https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635"
                }
              }
            ]
          },
          {
            type: "body",
            parameters: [
              { type: "text", text: acudienteNombre },     // {{1}}
              { type: "text", text: tipoSolicitud },       // {{2}}
              { type: "text", text: numeroSeguimiento },   // {{3}}
              { type: "text", text: seccionHistorial }     // {{4}}
            ]
          }
        ]
      }
    };

    const url = `https://graph.facebook.com/v20.0/${PHONE_NUMBER_ID}/messages`;

    const response = await fetch(url, {
      method: "POST",
      body: JSON.stringify(body),
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ACCESS_TOKEN}`
      }
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Error de la API:", result);
      return res.status(500).json({ error: "Error al enviar el mensaje", details: result });
    }

    console.log("Mensaje de respuesta enviado correctamente:", result);
    return res.json({ success: true, result });

  } catch (error) {
    console.error("Error general:", error);
    return res.status(500).json({ error: "Error interno del servidor", details: error.message });
  }
});

exports.guardarMediaFile = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(204).send('');
  }

  const { mediaId, from } = req.body;

  if (!mediaId || !from) {
    return res.status(400).send("Parámetros requeridos: mediaId y from");
  }

  const bucket = admin.storage().bucket();
  let mime;

  const storagePrefix = `whatsapp_media/usuario_${from}/${mediaId}`;

  try {
    console.log(`🔍 Descargando mediaId=${mediaId} para guardar permanentemente`);

    // 1. Obtener URL temporal
    const meta = await axios.get(
      `https://graph.facebook.com/v19.0/${mediaId}`,
      { headers: { Authorization: `Bearer ${ACCESS_TOKEN}` } }
    );

    const url = meta.data.url;
    mime = meta.data.mime_type;
    const extension = mime.split('/')[1] || 'bin';
    const filePath = `${storagePrefix}.${extension}`;

    console.log(`📥 Descargando binario`);
    const mediaRes = await axios.get(url, {
      headers: { Authorization: `Bearer ${ACCESS_TOKEN}` },
      responseType: 'arraybuffer',
    });

    console.log(`💾 Guardando en Storage: ${filePath}`);
    const file = bucket.file(filePath);
    await file.save(Buffer.from(mediaRes.data, 'binary'), {
      metadata: { contentType: mime },
    });

    await file.makePublic();
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;

    console.log(`✅ Archivo guardado correctamente`);

    return res.status(200).json({ url: publicUrl });

  } catch (err) {
    console.error("❌ Error descargando media:", err.response?.data || err);
    return res.status(500).send("Error guardando media");
  }
});

exports.sendWhatsAppMessage = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  const { to, text } = req.body;

  if (!to || !text) {
    return res.status(400).json({ error: "Debe proporcionar 'to' y 'text'" });
  }

  const url = `https://graph.facebook.com/v20.0/${PHONE_NUMBER_ID}/messages`;

  const body = {
    messaging_product: "whatsapp",
    to: to,
    type: "text",
    text: { body: text }
  };

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ACCESS_TOKEN}`
      },
      body: JSON.stringify(body)
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("Error de la API:", result);
      return res.status(500).json({
        error: "Error al enviar el mensaje",
        details: result
      });
    }

    console.log(`✅ Mensaje enviado correctamente a ${to}: ${text}`);
    return res.json({ success: true, result });

  } catch (error) {
    console.error("Error en la función:", error);
    return res.status(500).json({
      error: error.message || "Error desconocido"
    });
  }
});

exports.uploadAndSendWhatsAppMedia = functions.https.onRequest((req, res) => {
  cors(req, res, async () => {
    if (req.method === "OPTIONS") {
      return res.status(204).send("");
    }

    const { fileUrl, mimeType, to, caption } = req.body;

    if (!fileUrl || !mimeType || !to) {
      return res.status(400).json({
        error: "Faltan parámetros: fileUrl, mimeType y to son obligatorios.",
      });
    }

    try {
      // 1. Descargar el archivo desde Firebase Storage
      const response = await axios.get(fileUrl, { responseType: "stream" });

      // 2. Crear FormData con el archivo
      const form = new FormData();
      form.append("file", response.data, {
        filename: "archivo",
        contentType: mimeType,
      });
      form.append("type", mimeType);
      form.append("messaging_product", "whatsapp");

      // 3. Subir a Meta (WhatsApp)
      const uploadRes = await axios.post(
        `https://graph.facebook.com/v20.0/${PHONE_NUMBER_ID}/media`,
        form,
        {
          headers: {
            ...form.getHeaders(),
            Authorization: `Bearer ${ACCESS_TOKEN}`,
          },
        }
      );

      const mediaId = uploadRes.data.id;
      const tipo = mimeType.startsWith("image") ? "image" : "document";

      // 4. Enviar mensaje con el media ID
      const sendRes = await axios.post(
        `https://graph.facebook.com/v20.0/${PHONE_NUMBER_ID}/messages`,
        {
          messaging_product: "whatsapp",
          to,
          type: tipo,
          [tipo]: {
            id: mediaId,
            caption: caption || (tipo === "image" ? "📷 Imagen" : "📄 Documento"),
          },
        },
        {
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${ACCESS_TOKEN}`,
          },
        }
      );

      return res.status(200).json({
        success: true,
        mediaId,
        response: sendRes.data,
      });
    } catch (err) {
      console.error("❌ Error:", err.response?.data || err.message);
      return res.status(500).json({
        error: "Error general",
        details: err.response?.data || err.message,
      });
    }
  });
});