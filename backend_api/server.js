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

// API สำหรับดึงข้อมูลสินค้า
app.get('/getproduct', async (req, res) => {
  try {
    const connection = await getConnection();
    console.log("Connected to the database");

    const [rows] = await connection.query(`
      SELECT 
        p.*, 
        u.first_name AS firstName, 
        u.profile_picture AS profilePicture 
      FROM 
        product p 
      LEFT JOIN 
        recipients u 
      ON 
        p.userId = u.firebase_uid
    `);

    console.log("Fetched product rows: ", rows);
    
    const formattedProducts = rows.map(row => ({
      ...row,
      imageUrl: row.imageUrl ? row.imageUrl.toString('base64') : null,
      profilePicture: row.profilePicture ? row.profilePicture.toString('base64') : null
    }));

    await connection.end();
    console.log("Formatted products to send: ", formattedProducts);
    res.json(formattedProducts);
  } catch (err) {
    console.error('Error fetching products:', err);
    res.status(500).send('Internal Server Error');
  }
});

// API สำหรับดึงสินค้าตามหมวดหมู่
app.get('/category/:category', async (req, res) => {
  const { category } = req.params;

  try {
    const connection = await getConnection();
    const [rows] = await connection.query('SELECT * FROM product WHERE category = ?', [category]);

    const formattedProducts = rows.map(row => ({
      ...row,
      imageUrl: row.imageUrl ? row.imageUrl.toString('base64') : null
    }));

    await connection.end();
    res.json(formattedProducts);
  } catch (err) {
    console.error('Error fetching category products:', err);
    res.status(500).send('Internal Server Error');
  }
});



// API สำหรับสร้างหรืออัปเดตโปรไฟล์ผู้ใช้
app.post('/createOrUpdateUserProfile', async (req, res) => {
  const { firebaseUid, first_name, email } = req.body;

  try {
    const connection = await getConnection();

    // ตรวจสอบว่ามีโปรไฟล์ในฐานข้อมูลหรือไม่
    const [rows] = await connection.query(
      'SELECT * FROM users WHERE firebase_uid = ?',
      [firebaseUid]
    );

    if (rows.length === 0) {
      // ถ้าไม่มี ให้สร้างโปรไฟล์ใหม่ใน MySQL
      const insertQuery = `
        INSERT INTO users (firebase_uid, first_name, email)
        VALUES (?, ?, ?)
      `;
      await connection.query(insertQuery, [firebaseUid, first_name, email]);
      console.log("User profile created successfully.");
      res.status(201).send({ message: 'User profile created successfully.' });
    } else {
      console.log("User profile already exists.");
      res.status(200).send({ message: 'User profile already exists.' });
    }

    await connection.end(); // ปิดการเชื่อมต่อหลังจาก query เสร็จ
  } catch (err) {
    console.error('Error in createOrUpdateUserProfile:', err);
    res.status(500).send({ message: 'Database transaction error: ' + err.message });
  }
});

// API สำหรับอัปเดตโปรไฟล์ผู้ใช้
app.post('/updateUserProfile', async (req, res) => {
  const { email, first_name, gender, birth_date, profile_picture } = req.body;

  const updateQuery = `
    UPDATE users 
    SET first_name = ?, gender = ?, birth_date = ?, profile_picture = ?
    WHERE email = ?
  `;

  try {
    const connection = await getConnection();
    const [results] = await connection.query(updateQuery, [first_name, gender, birth_date, profile_picture ? Buffer.from(profile_picture, 'base64') : null, email]);
    
    if (results.affectedRows > 0) {
      res.status(200).send({ message: 'User profile updated successfully.' });
    } else {
      res.status(404).send({ message: 'User not found.' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error updating profile:', err);
    res.status(500).send({ message: 'Database update error: ' + err.message });
  }
});



// API สำหรับดึงข้อมูลผู้ใช้
app.get('/getUserProfile', async (req, res) => {
  const email = req.query.email;
  try {
    const connection = await getConnection();
    const [rows] = await connection.query('SELECT * FROM users WHERE email = ?', [email]);

    if (rows.length > 0) {
      res.json({
        username: rows[0].first_name,
        gender: rows[0].gender,
        birth_date: rows[0].birth_date,
        profile_picture: rows[0].profile_picture ? rows[0].profile_picture.toString('base64') : null, // แปลงภาพเป็น Base64
      });
    } else {
      res.status(404).json({ message: 'User not found' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});


// Regis recipients
app.post('/saveUserData', async (req, res) => {
  console.log('Received data:', req.body);
  try {
    const connection = await getConnection();

    const {
      firebase_uid,
      accountType,
      title,
      firstName,
      lastName,
      phoneNumber,
      address,
      bankName,
      accountName,
      accountNumber,
      taxId,
      idCardImage,
      vatRegistered
    } = req.body;

    console.log('Preparing to insert or update data');

    // Ensure all required fields are present
    if (!firebase_uid || !accountType || !title || !firstName || !lastName || !phoneNumber || !address || !bankName || !accountName || !accountNumber || !taxId || typeof vatRegistered === 'undefined') {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Check if the user already exists
    const [existingUser] = await connection.execute(
      'SELECT * FROM recipients WHERE firebase_uid = ?',
      [firebase_uid]
    );

    if (existingUser.length > 0) {
      // Update if user exists
      const updateSql = `
        UPDATE recipients SET
          account_type = ?, title = ?, first_name = ?, last_name = ?,
          phone_number = ?, address = ?, bank_name = ?, account_name = ?,
          account_number = ?, tax_id = ?, id_card_image = ?, vat_registered = ?
        WHERE firebase_uid = ?
      `;
      await connection.execute(updateSql, [
        accountType,
        title,
        firstName,
        lastName,
        phoneNumber,
        address,
        bankName,
        accountName,
        accountNumber,
        taxId,
        idCardImage ? Buffer.from(idCardImage, 'base64') : null,
        vatRegistered ? 1 : 0,
        firebase_uid
      ]);

      console.log('Data updated successfully');
      res.status(200).json({ message: 'Data updated successfully' });
    } else {
      // Insert new record if user does not exist
      const insertSql = `
        INSERT INTO recipients 
        (firebase_uid, account_type, title, first_name, last_name, phone_number, address, bank_name, account_name, account_number, tax_id, id_card_image, vat_registered) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      const [result] = await connection.execute(insertSql, [
        firebase_uid,
        accountType,
        title,
        firstName,
        lastName,
        phoneNumber,
        address,
        bankName,
        accountName,
        accountNumber,
        taxId,
        idCardImage ? Buffer.from(idCardImage, 'base64') : null,
        vatRegistered ? 1 : 0
      ]);
      console.log('Data inserted successfully');
      res.status(200).json({ message: 'Data saved successfully', insertedId: result.insertId });
    }

    await connection.end();
  } catch (error) {
    console.error('Error saving data:', error.message);
    res.status(500).json({ message: 'Failed to save data', error: error.message });
  }
});

// API สำหรับเพิ่ม/ลบรายการโปรด
app.post('/toggleFavorite', async (req, res) => {
  let { email, product_id, is_favorite } = req.body;

  if (!email || !product_id) {
    return res.status(400).send({ message: 'Missing email or product_id' });
  }

  product_id = parseInt(product_id, 10);
  if (isNaN(product_id)) {
    return res.status(400).send({ message: 'Invalid product_id' });
  }

  is_favorite = is_favorite === true || is_favorite === 'true';

  let connection;
  try {
    connection = await getConnection();

    if (is_favorite) {
      const sqlInsert =
        'INSERT INTO favorites (email, product_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE product_id = VALUES(product_id)';
      await connection.execute(sqlInsert, [email, product_id]);
    } else {
      const sqlDelete = 'DELETE FROM favorites WHERE email = ? AND product_id = ?';
      await connection.execute(sqlDelete, [email, product_id]);
    }

    res.status(200).send({ message: 'Favorite status updated successfully' });
  } catch (error) {
    console.error('Error in toggleFavorite:', error);
    res.status(500).send({ message: 'Error updating favorite status', error });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

app.get('/favorites', async (req, res) => {
  const { email } = req.query;

  if (!email) {
    return res.status(400).send({ message: 'Missing email' });
  }

  let connection;
  try {
    connection = await getConnection();

    const sqlSelect = 'SELECT product_id FROM favorites WHERE email = ?';
    const [rows] = await connection.execute(sqlSelect, [email]);

    res.status(200).send(rows);
  } catch (error) {
    console.error('Error in /favorites:', error);
    res.status(500).send({ message: 'Error fetching favorites', error });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


app.post('/getproduct/fetchByIds', async (req, res) => {
  const { product_ids } = req.body;

  if (!product_ids || !Array.isArray(product_ids)) {
    return res.status(400).send({ message: 'Invalid product IDs' });
  }

  let connection;
  try {
    connection = await getConnection();

    const placeholders = product_ids.map(() => '?').join(',');
    const sqlSelect = `SELECT * FROM product WHERE id IN (${placeholders})`;
    
    // Log SQL Query และค่า product_ids
    console.log('SQL Query:', sqlSelect);
    console.log('Product IDs:', product_ids);

    const [rows] = await connection.execute(sqlSelect, product_ids);

    if (rows.length === 0) {
      console.log('No products found for given IDs.');
    } else {
      console.log('Fetched products:', rows);
    }

    res.status(200).send(rows);
  } catch (error) {
    console.error('Error in /getproduct/fetchByIds:', error);
    res.status(500).send({ message: 'Error fetching products', error });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


// จัดการข้อผิดพลาด
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send({ message: 'Internal Server Error', error: err.message });
});

// กำหนด port ของเซิร์ฟเวอร์
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});




