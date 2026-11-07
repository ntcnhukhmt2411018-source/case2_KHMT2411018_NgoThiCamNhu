
const nodemailer = require('nodemailer');

// Cấu hình gửi email bằng Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// Hàm gửi email
async function guiEmail(nguoiNhan, tieuDe, noiDung) {
  try {
    const info = await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: nguoiNhan,
      subject: tieuDe,
      text: noiDung,
    });

    console.log('Gửi email thành công:', info.messageId);
    return true;
  } catch (error) {
    console.error('Lỗi gửi email:', error.message);
    return false;
  }
}

module.exports = { guiEmail };
