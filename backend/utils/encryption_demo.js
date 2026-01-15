const { encrypt, decrypt } = require('./encryption');

console.log('--- ENCRYPTION DEMONSTRATION ---');
console.log('Algorithm: AES-256-CBC');
console.log('Key Derivation: SHA-256');
console.log('');

const plaintext = 'This is a secret message!';
console.log('1. Plaintext input:');
console.log('   > "' + plaintext + '"');

console.log('\n2. Encrypting...');
const encrypted = encrypt(plaintext);
console.log('   Result (iv:ciphertext):');
console.log('   > ' + encrypted);

const [iv, ciphertext] = encrypted.split(':');
console.log('\n3. Breakdown:');
console.log('   Initial Vector (IV): ' + iv);
console.log('   Ciphertext:          ' + ciphertext);

console.log('\n4. Decrypting...');
const decrypted = decrypt(encrypted);
console.log('   Result:');
console.log('   > "' + decrypted + '"');

console.log('\n5. Demonstration of Random IV:');
const encryptedAgain = encrypt(plaintext);
console.log('   Encrypting same message again:');
console.log('   > ' + encryptedAgain);

console.log('\n--- END OF DEMONSTRATION ---');
