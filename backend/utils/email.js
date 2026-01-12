const axios = require('axios');

const sendEmail = async (options) => {
  try {
    const response = await axios.post(
      'https://api.brevo.com/v3/smtp/email',
      {
        sender: { 
          name: 'Kood Messenger', 
          email: process.env.EMAIL_USER // This must be verified in Brevo
        },
        to: [{ email: options.email }],
        subject: options.subject,
        textContent: options.message,
        htmlContent: options.html,
      },
      {
        headers: {
          'api-key': process.env.BREVO_API_KEY,
          'Content-Type': 'application/json',
        },
      }
    );

    console.log(`Email sent to: ${options.email}. Status: ${response.status}`);
  } catch (error) {
    console.error('Brevo API error:', error.response ? error.response.data : error.message);
    throw new Error('Email could not be sent');
  }
};

const sendVerificationEmail = async (email, code) => {
  const message = `Your verification code is: ${code}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
      <h2 style="color: #6a1b9a; text-align: center;">Welcome to Kood/Messenger!</h2>
      <p>Thank you for registering. Please use the following code to verify your email address:</p>
      <div style="font-size: 32px; font-weight: bold; text-align: center; color: #6a1b9a; margin: 20px 0; letter-spacing: 5px;">
        ${code}
      </div>
      <p>If you did not request this, please ignore this email.</p>
      <hr style="border: none; border-top: 1px solid #eee;">
      <p style="font-size: 12px; color: #888; text-align: center;">&copy; 2026 Kood/Messenger Team</p>
    </div>
  `;

  await sendEmail({
    email,
    subject: 'Verify your Kood/Messenger Account',
    message,
    html,
  });
};

const sendPasswordResetEmail = async (email, token) => {
  const message = `Your password reset token is: ${token}`;
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
      <h2 style="color: #6a1b9a; text-align: center;">Password Reset Request</h2>
      <p>You requested a password reset. Please use the following token to reset your password:</p>
      <div style="font-size: 24px; font-weight: bold; text-align: center; color: #6a1b9a; margin: 20px 0;">
        ${token}
      </div>
      <p>This token will expire in 1 hour.</p>
      <p>If you did not request this, please ignore this email.</p>
      <hr style="border: none; border-top: 1px solid #eee;">
      <p style="font-size: 12px; color: #888; text-align: center;">&copy; 2026 Kood/Messenger Team</p>
    </div>
  `;

  await sendEmail({
    email,
    subject: 'Password Reset Request - Kood/Messenger',
    message,
    html,
  });
};

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
};
