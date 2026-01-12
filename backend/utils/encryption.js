const crypto = require('crypto');
const algorithm = 'aes-256-cbc';

// Use a stable fallback key for development. In production, ALWAYS set ENCRYPTION_KEY.
const FALLBACK_KEY = '7f8e9d0c1b2a3f4e5d6c7b8a90123456'; 
const SECRET_KEY = process.env.ENCRYPTION_KEY || FALLBACK_KEY;

if (!process.env.ENCRYPTION_KEY) {
  console.warn('WARNING: ENCRYPTION_KEY not found in environment variables. Using a stable fallback key. In production, this is insecure!');
}
const IV_LENGTH = 16;

const encrypt = (text) => {
  if (!text) return text;
  const iv = crypto.randomBytes(IV_LENGTH);
  // Create key buffer from hex string if necessary, or just use it if it's correct length.
  // We'll ensure SECRET_KEY is a 32-byte string or adjust.
  // For simplicity, let's hash the key to ensure 32 bytes
  const key = crypto.createHash('sha256').update(String(SECRET_KEY)).digest();
  
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  let encrypted = cipher.update(text);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
};

const decrypt = (text) => {
  if (!text) return text;
  try {
    const textParts = text.split(':');
    const iv = Buffer.from(textParts.shift(), 'hex');
    const encryptedText = Buffer.from(textParts.join(':'), 'hex');
    const key = crypto.createHash('sha256').update(String(SECRET_KEY)).digest();
    
    const decipher = crypto.createDecipheriv(algorithm, key, iv);
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
  } catch (error) {
    // If decryption fails (e.g. data wasn't encrypted), return original text
    return text;
  }
};

module.exports = { encrypt, decrypt };
