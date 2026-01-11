const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: process.env.EMAIL_PORT == 465, // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

const sendVerificationEmail = async (email, token) => {
  const mailOptions = {
    from: process.env.EMAIL_FROM || `"Kood/Messenger" <${process.env.EMAIL_USER}>`,
    to: email,
    subject: 'Verify your Messenger account',
    text: `Your verification code is: ${token}`,
    html: `
      <div style="font-family: sans-serif; padding: 20px; color: #333;">
        <h2>Welcome to Kood/Messenger!</h2>
        <p>Your 6-digit verification code is:</p>
        <h1 style="color: #6c63ff; letter-spacing: 5px;">${token}</h1>
        <p>Enter this code in the app to activate your account.</p>
      </div>
    `,
  };

  return transporter.sendMail(mailOptions);
};

module.exports = { sendVerificationEmail };
