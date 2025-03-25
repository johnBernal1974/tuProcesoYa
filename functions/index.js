const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const cors = require("cors");
const express = require("express");
const { defineSecret } = require("firebase-functions/params");
const { onRequest } = require("firebase-functions/v2/https");

admin.initializeApp();
const db = admin.firestore();

// 🔐 Secret config variables
const FIREBASE_API_KEY = defineSecret("FB_API_KEY");
const FIREBASE_AUTH_DOMAIN = defineSecret("FB_AUTH_DOMAIN");
const FIREBASE_PROJECT_ID = defineSecret("FB_PROJECT_ID");
const FIREBASE_STORAGE_BUCKET = defineSecret("FB_STORAGE_BUCKET");
const FIREBASE_APP_ID = defineSecret("FB_APP_ID");
const FIREBASE_MESSAGING_SENDER_ID = defineSecret("FB_MESSAGING_SENDER_ID");

let cachedConfig = null;
let lastFetchTime = 0;
const CACHE_DURATION_MS = 5 * 60 * 1000;

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

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.post("/enviarCorreo", async (req, res) => {
  try {
    const { destinatario, asunto, mensaje, archivos } = req.body;

    let transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "johnnever.bernal@gmail.com",
        pass: "yqfo mify fcso edam",
      },
    });

    let adjuntos = archivos?.map((archivo) => ({
      filename: archivo.nombre,
      content: archivo.base64,
      encoding: "base64",
    })) || [];

    let mailOptions = {
      from: "johnnever.bernal@gmail.com",
      to: destinatario,
      subject: asunto,
      html: mensaje,
      attachments: adjuntos.length ? adjuntos : undefined,
    };

    let info = await transporter.sendMail(mailOptions);
    res.status(200).json({ message: "Correo enviado con éxito", response: info.response });
  } catch (error) {
    console.error("🚨 Error al enviar correo:", error);
    res.status(500).json({ error: "Error al enviar el correo", details: error.message });
  }
});

exports.enviarCorreo = functions.https.onRequest(app);

exports.wompiWebhook = functions.https.onRequest(async (req, res) => {
  try {
    const event = req.body;

    if (!event || !event.event || !event.data || !event.data.transaction) {
      console.error("⚠️ Evento inválido recibido:", event);
      return res.status(400).json({ error: "Evento inválido recibido" });
    }

    console.log("📩 Evento recibido de Wompi:", JSON.stringify(event, null, 2));

    const transaction = event.data.transaction;
    const transactionId = transaction.id;
    const status = transaction.status;
    const reference = transaction.reference;
    const amount = transaction.amount_in_cents / 100;
    const paymentMethod = transaction.payment_method_type;
    const createdAt = transaction.created_at;

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

    const recargaRef = db.collection("recargas").doc(transactionId);
    await recargaRef.set({
      userId,
      amount,
      status,
      paymentMethod,
      transactionId,
      reference,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(createdAt)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Transacción guardada en "recargas": ${transactionId}`);

    const saldoActual = userDoc.data().saldo || 0;
    const nuevoSaldo = saldoActual + amount;

    if (tipoTransaccion === "suscripcion" && status === "APPROVED") {
      await userRef.update({ isPaid: true });
      console.log(`✅ Suscripción aprobada para ${userId}`);
    }

    if (["recarga", "peticion"].includes(tipoTransaccion) && status === "APPROVED") {
      await userRef.update({ saldo: nuevoSaldo });
      console.log(`✅ ${tipoTransaccion} aprobada para ${userId}: nuevo saldo ${nuevoSaldo}`);
    }

    return res.status(200).json({ message: "Estado de pago actualizado con éxito y guardado en recargas" });
  } catch (error) {
    console.error("🚨 Error en el webhook de Wompi:", error);
    return res.status(500).json({ error: "Error procesando el webhook", details: error.message });
  }
});
