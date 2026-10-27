require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Node.js API dang hoat dong!');
});

async function startServer() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Da ket noi MongoDB thanh cong!');

    app.listen(PORT, () => {
      console.log(`Server dang chay tai http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Loi ket noi MongoDB:', error.message);
  }
}

startServer();