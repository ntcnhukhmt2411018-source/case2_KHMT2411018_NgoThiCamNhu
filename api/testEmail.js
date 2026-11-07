
require('dotenv').config();

const { guiEmail } = require('./services/emailService');

async function testEmail() {
  const ketQua = await guiEmail(
    process.env.EMAIL_USER,
    'Kiểm tra gửi email Task Manager',
    'Xin chào! Đây là email kiểm tra từ ứng dụng Task Manager.'
  );

  if (ketQua) {
    console.log('TEST THÀNH CÔNG: Đã gửi email!');
  } else {
    console.log('TEST THẤT BẠI: Không gửi được email.');
  }
}

testEmail();
