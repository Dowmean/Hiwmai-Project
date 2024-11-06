const express = require('express');
const mysql = require('mysql2/promise');  // ใช้ mysql2 ที่รองรับ promises
const bodyParser = require('body-parser');
require('dotenv').config();  // ใช้ dotenv เพื่อดึงตัวแปรสภาพแวดล้อมจากไฟล์ .env

const app = express();

// กำหนด limit ของ body parser เพื่อรองรับข้อมูลขนาดใหญ่ เช่น รูปภาพ
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));

// เชื่อมต่อกับฐานข้อมูล MySQL
async function getConnection() {
  return await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'Dowmean',
    password: process.env.DB_PASS || 'Dowmean.1006',
    database: process.env.DB_NAME || 'hiwmai'
  });
}

// เส้นทาง GET สำหรับ root URL
app.get('/', (req, res) => {
  res.send('Welcome to the API');
});

// API สำหรับสร้างโพสต์ใหม่
app.post('/createpost', async (req, res) => {
  const { userName, userId, category, productName, productDescription, price } = req.body;
  const imageBlob = req.body.imageUrl ? Buffer.from(req.body.imageUrl, 'base64') : null; // Convert Base64 to binary (BLOB)

  // ตรวจสอบว่ามีฟิลด์ที่จำเป็นครบหรือไม่
  if (!userName || !userId || !category || !productName || !productDescription || !price || !imageBlob) {
    return res.status(400).send('Missing required fields');
  }

  const postedDate = new Date();

  try {
    const connection = await getConnection();
    console.log("Database connected successfully");

    // Log ข้อมูลที่กำลังจะถูกบันทึก
    console.log("Executing query with data: ", [userName, userId, category, productName, productDescription, price, imageBlob, postedDate]);

    const sql = 'INSERT INTO product (userName, userId, category, productName, productDescription, price, imageUrl, postedDate) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
    await connection.query(sql, [userName, userId, category, productName, productDescription, price, imageBlob, postedDate]);

    await connection.end();  // ปิดการเชื่อมต่อหลังจาก query เสร็จ

    res.send('Post created');
  } catch (err) {
    console.error('Error occurred during query: ', err);
    res.status(500).send('Internal Server Error: ' + err.message);
  }
});

// API สำหรับแก้ไขโพสต์
app.put('/editpost/:id', async (req, res) => {
  const { id } = req.params;
  const { productName, productDescription, price, category, imageUrl } = req.body;

  if (!productName || !productDescription || !price || !category) {
    return res.status(400).send('Missing required fields');
  }

  try {
    const connection = await getConnection();
    const sql = 'UPDATE product SET productName = ?, productDescription = ?, price = ?, category = ?, imageUrl = ? WHERE id = ?';
    await connection.query(sql, [productName, productDescription, price, category, imageUrl, id]);
    await connection.end();
    res.send('Post updated successfully');
  } catch (err) {
    console.error('Error updating post:', err);
    res.status(500).send('Internal Server Error: ' + err.message);
  }
});


// API สำหรับลบโพสต์
app.delete('/deletepost/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const connection = await getConnection();
    const sql = 'DELETE FROM product WHERE id = ?';
    await connection.query(sql, [id]);
    await connection.end();
    res.send('Post deleted successfully');
  } catch (err) {
    console.error('Error deleting post:', err);
    res.status(500).send('Internal Server Error: ' + err.message);
  }
});


// Get products route
app.get('/getproduct', async (req, res) => {
  try {
    const connection = await getConnection(); // Establish connection to the database
    const [rows] = await connection.query('SELECT * FROM product');

    const formattedProducts = rows.map(row => {
      return {
        ...row,
        imageUrl: row.imageUrl ? row.imageUrl.toString('base64') : null // Convert image back to base64 for frontend
      };
    });

    await connection.end(); // Close the connection
    res.json(formattedProducts); // Send the product data as JSON
  } catch (err) {
    console.error('Error fetching products:', err);
    res.status(500).send('Internal Server Error');
  }
});

const fs = require('fs');

function encodeImageToBase64(filePath) {
  const imageBuffer = fs.readFileSync(filePath); // อ่านไฟล์ภาพ
  const imageBase64 = imageBuffer.toString('base64'); // แปลงเป็น Base64
  return imageBase64;
}

// กำหนด port ของเซิร์ฟเวอร์
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

