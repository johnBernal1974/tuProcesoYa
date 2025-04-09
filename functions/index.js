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

    if (!event || !event.type || !event.data) {
      return res.status(400).json({ error: "Evento inválido" });
    }

    const { type, data } = event;
    const messageId = data?.message?.id;
    const recipient = data?.recipient?.email;
    const timestamp = new Date();

    // Solo procesar eventos relevantes
    const eventosPermitidos = ["email.sent", "email.delivered", "email.bounced"];
    if (!eventosPermitidos.includes(type)) {
      console.log(`⚠️ Evento ignorado: ${type}`);
      return res.status(200).json({ ignored: true });
    }

    if (!messageId || !recipient) {
      return res.status(400).json({ error: "Faltan datos del mensaje o destinatario" });
    }

    // Buscar en cualquier subcolección "log_correos" por messageId
    const logsSnapshot = await db
      .collectionGroup("log_correos")
      .where("messageId", "==", messageId)
      .get();

    if (logsSnapshot.empty) {
      console.warn(`⚠️ No se encontró log de correo con messageId: ${messageId}`);
    } else {
      for (const doc of logsSnapshot.docs) {
        // Actualizar el estado principal
        await doc.ref.update({
          estado: type,
          actualizado: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Guardar historial del evento
        await doc.ref.collection("eventos_resend").add({
          tipo: type,
          data,
          recibidoEn: timestamp,
        });
      }
    }

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

exports.sendEmailWithResend = onRequest({
  secrets: ["RESEND_API_KEY"],
}, async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  try {
    const { to, cc, subject, html, archivos, idDocumento, enviadoPor } = req.body;

    if (!to || !subject || !html || !idDocumento || !enviadoPor) {
      return res.status(400).json({ error: "Faltan campos obligatorios: to, subject, html, idDocumento, enviadoPor" });
    }

    const normalizeEmails = (field) => Array.isArray(field) ? field : field ? [field] : [];
    const toAddresses = normalizeEmails(to);
    const ccAddresses = normalizeEmails(cc);

    const attachments = (archivos || []).map((archivo) => ({
      content: archivo.base64,
      filename: archivo.nombre,
      type: archivo.tipo || "application/octet-stream", // Puedes ajustar el tipo si sabes el MIME
    }));

    const payload = {
      from: "Tu Proceso Ya <peticiones@tuprocesoya.com>",
      to: toAddresses,
      cc: ccAddresses.length > 0 ? ccAddresses : undefined,
      subject,
      html,
      attachments,
    };

    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const rawText = await response.text();

    if (!response.ok) {
      console.error("❌ Resend API error:", rawText);
      return res.status(500).json({ error: rawText });
    }

    let responseData = {};
    if (rawText?.trim()) {
      try {
        responseData = JSON.parse(rawText);
      } catch (parseErr) {
        console.warn("⚠️ Respuesta no JSON:", rawText);
      }
    }

    const firestore = getFirestore();
    const bucket = admin.storage().bucket();
    const timestamp = new Date().toISOString();
    const htmlPath = `derechos_peticion/${idDocumento}/correos_enviados/correo-${timestamp}.html`;

    await bucket.file(htmlPath).save(Buffer.from(html, "utf-8"), {
      metadata: { contentType: "text/html; charset=utf-8" },
    });

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${htmlPath}`;

    await firestore
      .collection("derechos_peticion_solicitados")
      .doc(idDocumento)
      .collection("log_correos")
      .add({
        to: toAddresses,
        cc: ccAddresses,
        subject,
        html,
        htmlUrl: publicUrl,
        archivos: archivos?.map(a => ({ nombre: a.nombre })),
        enviadoPor,
        messageId: responseData.id || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("❌ Error enviando correo Resend:", error);
    return res.status(500).json({ error: "Error enviando correo Resend" });
  }
});


exports.generarTextoIAExtendido = onRequest({
  cors: true,
  secrets: [OPENAI_API_KEY],
}, async (req, res) => {
  try {
    const { categoria, subcategoria, respuestasUsuario } = req.body;

    if (
      typeof categoria !== 'string' || categoria.trim() === '' ||
      typeof subcategoria !== 'string' || subcategoria.trim() === '' ||
      !Array.isArray(respuestasUsuario) || respuestasUsuario.length === 0
    ) {
      return res.status(400).json({ error: "Faltan campos requeridos" });
    }

    const prompt = `
Redacta el cuerpo de un derecho de petición en Colombia para una persona privada de la libertad.

🔒 Ya existe un encabezado con nombre, documento y centro penitenciario: **no repitas esos datos**.

🧠 El relato fue escrito por un acudiente (familiar, amigo o persona de confianza), quien describe la situación del PPL en primera persona ("mi hermano", "mi padre", etc.). Interpreta correctamente el texto: **todo lo que se menciona se refiere exclusivamente a la persona privada de la libertad, no al acudiente.** Es decir, si el acudiente escribe "mi primo tiene dolor", debes redactar: "La persona privada de la libertad presenta dolor", **no**: "El primo de la persona privada de la libertad".

🧠 Usa toda la información proporcionada para construir una sección sólida de “Consideraciones”, redactada en tercera persona, con lenguaje técnico, claro y sin adornos personales.

✒️ Estructura el documento con estos títulos (tal cual):

Consideraciones
Fundamentos de derecho
Petición concreta

📌 Fundamentos de derecho debe incluir:
- Fundamento en la Constitución Política (con número de artículo y descripción).
- Fundamento en la Ley 65 de 1993 o normas penitenciarias pertinentes.
- Otras normas que respalden el caso.
- Jurisprudencia relevante: cita número de sentencia, año y criterio aplicable.

📌 En la Petición concreta:
- Redacta con precisión y claridad.
- Incluye si hay otro derecho que también esté en riesgo o se vulnera.

Respuestas dadas por el acudiente (relatan lo que vive la persona privada de la libertad):
${respuestasUsuario.map((r, i) => `• ${r}`).join("\n")}
    `.trim();

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

    // 🔍 Separar en partes
    const seccion = (label, source) => {
      const regex = new RegExp(`${label}[:\\s]*`, 'i');
      return source.split(regex)[1]?.split(/\n(?=\w)/)?.[0]?.trim() ?? '';
    };

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



exports.consultarProcesosPorCedula = functions.https.onRequest(async (req, res) => {
  const cedula = req.body.cedula;

  if (!cedula) {
    return res.status(400).json({ error: "Debes enviar una cédula" });
  }

  try {
    const puppeteer = require("puppeteer");

    const browser = await puppeteer.launch({
      headless: true,
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
    });

    const page = await browser.newPage();
    await page.goto("https://consultaprocesos.ramajudicial.gov.co/", {
      waitUntil: "networkidle2",
    });

    // Aquí aún falta adaptar el selector correcto para cédula
    const contenido = await page.evaluate(() => {
      return document.body.innerText;
    });

    await browser.close();

    return res.status(200).json({ textoExtraido: contenido });

  } catch (error) {
    console.error("❌ Error:", error);
    return res.status(500).json({ error: "Error al consultar", detalle: error.message });
  }
});
