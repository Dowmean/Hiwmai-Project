const express = require('express');
const mysql = require('mysql2');  // เปลี่ยนเป็น mysql2
const bodyParser = require('body-parser');
const multer = require('multer'); // ใช้ multer สำหรับการจัดการการอัปโหลดไฟล์
require('dotenv').config();       // ใช้ .env สำหรับตัวแปรสภาพแวดล้อม

const app = express(); // เริ่มต้น Express app
app.use(bodyParser.json()); // ใช้ body-parser เพื่ออ่าน request body

// ตั้งค่า multer สำหรับอัปโหลดไฟล์
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// เชื่อมต่อกับฐานข้อมูล MySQL
const connection = await mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'Dowmean',
  password: process.env.DB_PASS || 'Dowmean.1006', // ต้องมีรหัสผ่านที่ถูกต้อง
  database: process.env.DB_NAME || 'hiwmai'
});
console.log("DB_USER: ", process.env.DB_USER);
console.log("DB_PASS: ", process.env.DB_PASS);

connection.connect(err => {
  if (err) {
    console.error('Error connecting to MySQL: ', err);
    return;
  }
  console.log('Connected to MySQL');
});

// API สำหรับสร้างโพสต์ใหม่ พร้อมรูปภาพ
app.post('/createpost', upload.single('image'), async (req, res) => {
  const { userName, userId, category, productName, productDescription, price } = req.body;
  
  if (!userName || !userId || !category || !productName || !productDescription || !price || !req.file) {
    return res.status(400).send('Missing required fields');
  }

  const postedDate = new Date();
  const imageBuffer = req.file.buffer;  // เก็บข้อมูลรูปภาพในรูปแบบ buffer
  
  try {
    const sql = 'INSERT INTO product (userName, userId, category, productName, productDescription, price, image, postedDate) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
    await connection.promise().query(sql, [userName, userId, category, productName, productDescription, price, imageBuffer, postedDate]);
    res.send('Post created successfully');
  } catch (err) {
    console.error('Error occurred during query: ', err);
    res.status(500).send('Internal Server Error: ' + err.message);
  }
});

// กำหนด port ของเซิร์ฟเวอร์
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
