const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const cors = require("cors");
const express = require("express");

const app = express();
app.use(cors({ origin: true })); // Habilita CORS
app.use(express.json()); // Habilita JSON en el body

app.post("/enviarCorreo", async (req, res) => {
  try {
    const { destinatario, asunto, mensaje } = req.body;

    let transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "johnnever.bernal@gmail.com",
        pass: "yqfo mify fcso edam",
      },
    });

    let mailOptions = {
      from: "johnnever.bernal@gmail.com",
      to: destinatario,
      subject: asunto,
      html: mensaje, // Cambia esto para que acepte el mensaje en formato HTML
    };

    let info = await transporter.sendMail(mailOptions);
    res.status(200).json({ message: "Correo enviado con éxito", response: info.response });
  } catch (error) {
    res.status(500).json({ error: "Error al enviar el correo", details: error.message });
  }
});

// Firebase function
exports.enviarCorreo = functions.https.onRequest(app);
