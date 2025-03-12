const mysql = require('mysql2/promise');  // ใช้ mysql2 ที่รองรับ promises
const bodyParser = require('body-parser');
const express = require('express'); // โหลดโมดูล
const cors = require('cors');
const reload = require('reload');
const fs = require('fs');
require('dotenv').config();  // ใช้ dotenv เพื่อดึงตัวแปรสภาพแวดล้อมจากไฟล์ .env
const app = express();
const admin = require('firebase-admin'); // เพิ่มการ require firebase-admin


// เปิดใช้งาน reload
reload(app).then(() => {
  console.log('Reload is enabled');
}).catch(err => {
  console.error('Failed to enable reload:', err);
});

// กำหนด limit ของ body parser เพื่อรองรับข้อมูลขนาดใหญ่ เช่น รูปภาพ
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));
app.use(cors());

// ตั้งค่า Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Middleware สำหรับ JSON
app.use(express.json());

// เชื่อมต่อกับฐานข้อมูล MySQL
async function getConnection() {
  return await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'Dowmean',
    password: process.env.DB_PASS || '',
    database: process.env.DB_NAME || 'hiwmai'
  });
}

// เส้นทาง GET สำหรับ root URL
app.get('/', (req, res) => {
  res.send('Welcome to the API');
});

// ตรวจสอบ role ที่ได้รับจากฐานข้อมูล
const validRoles = ['User', 'Recipient', 'Admin'];

// Endpoint: ตรวจสอบ Role ของผู้ใช้
app.get('/getUserRole', async (req, res) => {
  const email = req.query.email; // ดึง email จาก Query Parameters

  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  try {
    // เชื่อมต่อฐานข้อมูล
    const connection = await getConnection();

    // Query ดึงข้อมูล role
    const [rows] = await connection.query(
      'SELECT role FROM users WHERE email = ?',
      [email]
    );

    if (rows.length > 0) {
      const userRole = rows[0].role;

      // ตรวจสอบว่าบทบาทที่ได้รับถูกต้องหรือไม่
      if (validRoles.includes(userRole)) {
        res.status(200).json({ role: userRole }); // ส่ง role กลับไป
      } else {
        res.status(400).json({ message: 'Invalid role in database' });
      }
    } else {
      res.status(404).json({ message: 'User not found' }); // ไม่พบผู้ใช้
    }

    await connection.end(); // ปิดการเชื่อมต่อฐานข้อมูล
  } catch (error) {
    console.error('Error fetching user role:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

const checkRoleOrOwnership = async (req, res, next) => {
  const { id } = req.params; 
  const userEmail = req.body.email || req.query.email;

  if (!id || !userEmail) {
    console.error('Missing id or email');
    return res.status(400).json({ message: 'Post ID and Email are required' });
  }

  try {
    const connection = await getConnection();

    console.log('Checking ownership for Post ID:', id, 'Email:', userEmail);

    const [rows] = await connection.query(
      `SELECT p.email AS ownerEmail, u.role
       FROM product p
       JOIN users u ON p.email = u.email
       WHERE p.id = ?`,
      [id]
    );

    console.log('Query Result in Middleware:', rows);

    if (rows.length === 0) {
      console.error('Post not found for ID:', id);
      return res.status(404).json({ message: 'Post not found' });
    }

    const post = rows[0];
    console.log('Owner Email:', post.ownerEmail, 'User Email:', userEmail, 'Role:', post.role);

    if (post.ownerEmail === userEmail || post.role === 'Admin') {
      console.log('Permission granted');
      next();
    } else {
      console.error('Permission denied for user:', userEmail);
      res.status(403).json({ message: 'Permission denied' });
    }

    await connection.end();
  } catch (error) {
    console.error('Error in Middleware:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};



// Route: ตรวจสอบ Role หรือ Ownership
app.post('/checkRoleAndOwnership', async (req, res) => {
  const { email, product_id } = req.body;

  console.log('Request Body:', req.body);
  if (!email || !product_id) {
    console.error('Missing email or product_id');
    return res.status(400).json({ message: 'Email and Product ID are required' });
  }

  try {
    const connection = await getConnection();

    // Query เพื่อดึง ownerEmail จาก product และ role จาก users
    console.log('Executing Query for Product ID:', product_id, 'and Email:', email);

    const [rows] = await connection.query(
      `SELECT p.email AS ownerEmail, 
              (SELECT role FROM users WHERE email = ?) AS userRole
       FROM product p
       WHERE p.id = ?`,
      [email, product_id]
    );

    console.log('Query Result:', rows);

    if (rows.length === 0) {
      console.error('Post not found with Product ID:', product_id);
      return res.status(404).json({ message: 'Post not found' });
    }

    const post = rows[0];
    console.log('Post Data:', post);

    // Logic ตรวจสอบสิทธิ์
    const canEditOrDelete = email === post.ownerEmail || post.userRole === 'Admin';
    console.log('Can Edit/Delete:', canEditOrDelete);

    res.status(200).json({ canEditOrDelete });

    await connection.end();
  } catch (error) {
    console.error('Error checking role or ownership:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});




// Route: แก้ไขโพสต์
app.put('/editpost/:id', async (req, res) => {
  const { id } = req.params;
  const { productName, productDescription, price, category, imageUrl } = req.body;

  try {
    const connection = await getConnection();
    const sql = `
      UPDATE product
      SET productName = ?, productDescription = ?, price = ?, category = ?, imageUrl = ?
      WHERE id = ?`;
    console.log('Executing SQL:', sql, [productName, productDescription, price, category, imageUrl, id]);

    const [result] = await connection.query(sql, [productName, productDescription, price, category, imageUrl, id]);
    console.log('SQL Result:', result);

    await connection.end();
    res.json({ message: 'Post updated successfully' });
  } catch (error) {
    console.error('Error updating post:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


// Route: ลบโพสต์
app.delete('/deletepost/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const connection = await getConnection();
    const sql = 'DELETE FROM product WHERE id = ?';
    console.log('Executing SQL:', sql, [id]);

    const [result] = await connection.query(sql, [id]);
    console.log('SQL Result:', result);

    await connection.end();
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});



// ลบผู้ใช้จาก Firebase Authentication
app.delete('/deleteUser', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).send({ message: 'Email is required' });
  }

  try {
    // ดึง UID จาก Firebase Authentication โดยใช้ email
    const userRecord = await admin.auth().getUserByEmail(email);

    // ลบผู้ใช้ใน Firebase Authentication
    await admin.auth().deleteUser(userRecord.uid);

    // ลบข้อมูลผู้ใช้ในฐานข้อมูล (ถ้ามี)
    const connection = await getConnection();
    const [result] = await connection.query('DELETE FROM users WHERE email = ?', [email]);
    await connection.end();

    if (result.affectedRows > 0) {
      res.status(200).send({ message: 'User deleted successfully' });
    } else {
      res.status(404).send({ message: 'User not found in database' });
    }
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).send({ message: 'Failed to delete user', error: error.message });
  }
});



app.get('/getrecipients', async (req, res) => {
  try {
    const connection = await getConnection();
    // ใช้ INNER JOIN เพื่อเลือกเฉพาะผู้ใช้ที่มีอยู่ในตาราง recipients
    const [rows] = await connection.query(`
      SELECT 
        users.id, 
        users.first_name, 
        users.profile_picture, 
        users.email
      FROM 
        users
      INNER JOIN 
        recipients
      ON 
        users.firebase_uid = recipients.firebase_uid
    `);

    if (rows.length > 0) {
      const users = rows.map(user => ({
        id: user.id,
        first_name: user.first_name,
        profile_picture: user.profile_picture
          ? user.profile_picture.toString('base64') // Convert to Base64 for frontend
          : null,
        email: user.email,
      }));
      res.status(200).json(users);
    } else {
      console.log('No users found in recipients table');
      res.status(404).json({ message: 'No users found in recipients' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ message: 'Internal server error', error: err.message });
  }
});


// อับอัปเดต role เป็น Recipient
app.put('/updateUserRole', async (req, res) => {
  const { email } = req.body;

  try {
    const connection = await getConnection(); // เชื่อมต่อกับฐานข้อมูล
    const query = `UPDATE users SET role = 'Recipient' WHERE email = ?`;
    const [result] = await connection.query(query, [email]);
    await connection.end();

    if (result.affectedRows > 0) {
      res.status(200).send({ message: 'User role updated successfully' });
    } else {
      res.status(404).send({ message: 'User not found' });
    }
  } catch (error) {
    console.error('Error updating user role:', error);
    res.status(500).send({ message: 'Failed to update user role', error: error.message });
  }
});

app.delete('/deleteRecipient', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).send({ message: 'Email is required' });
  }

  try {
    // เชื่อมต่อกับฐานข้อมูล
    const connection = await getConnection();

    // ดึง firebase_uid จาก users โดยใช้ email
    const [userRows] = await connection.query(
      'SELECT firebase_uid FROM users WHERE email = ?',
      [email]
    );

    if (userRows.length === 0) {
      return res.status(404).send({ message: 'User not found in users table' });
    }

    const firebaseUid = userRows[0].firebase_uid;

    // ลบเฉพาะผู้ใช้ในตาราง recipients
    const [deleteResult] = await connection.query(
      'DELETE FROM recipients WHERE firebase_uid = ?',
      [firebaseUid]
    );

    await connection.end();

    if (deleteResult.affectedRows > 0) {
      res.status(200).send({ message: 'User deleted from recipients table successfully' });
    } else {
      res.status(404).send({ message: 'User not found in recipients table' });
    }
  } catch (error) {
    console.error('Error deleting user from recipients:', error);
    res.status(500).send({ message: 'Internal server error', error: error.message });
  }
});

// ดึงข้อมูลผู้รับหิ้วบทั้งหมด
app.get('/recipients', async (req, res) => {
  try {
    const connection = await getConnection();
    const query = `
      SELECT 
        u.firebase_uid,
        u.first_name, 
        u.profile_picture 
      FROM users u
      WHERE u.role = 'Recipient'
    `;

    const [rows] = await connection.query(query);

    const recipients = rows.map(row => ({
      firebaseUid: row.firebase_uid,
      firstName: row.first_name,
      profilePicture: row.profile_picture
        ? row.profile_picture.toString('base64') // Convert to Base64
        : null,
    }));

    res.status(200).json(recipients);
  } catch (err) {
    console.error('Error fetching recipients:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});

// ดึงข้อมูลตาม firebase_uid
app.get('/recipients/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params; // รับค่า firebase_uid จาก URL

  try {
    console.log('Requested firebase_uid:', firebase_uid); // Debug

    const connection = await getConnection();
    const query = `
      SELECT 
        bank_name, 
        account_name, 
        account_number
      FROM recipients
      WHERE firebase_uid = ?
    `;

    const [rows] = await connection.query(query, [firebase_uid]);

    console.log('Query result:', rows); // Debug

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    const recipient = rows[0];
    res.status(200).json({
      bankName: recipient.bank_name,
      accountName: recipient.account_name,
      accountNumber: recipient.account_number,
    });
  } catch (err) {
    console.error('Error fetching recipient details:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});



// API สำหรับสร้างโพสต์ใหม่
const sharp = require('sharp');

app.post('/createpost', async (req, res) => {
  const { firebase_uid, category, productName, productDescription, price, imageUrl } = req.body;

  // ตรวจสอบฟิลด์ที่จำเป็น
  if (!firebase_uid || !category || !productName || !productDescription || !price) {
    return res.status(400).send('Missing required fields');
  }

  const postedDate = new Date();

  try {
    const connection = await getConnection(); // ใช้ createConnection() จากฟังก์ชัน getConnection()
    console.log('Database connected successfully');

    // ตรวจสอบผู้ใช้
    const [users] = await connection.query(
      'SELECT first_name, email FROM users WHERE firebase_uid = ?',
      [firebase_uid]
    );
    const user = users[0];

    if (!user) {
      connection.end(); // ใช้ end() แทน release()
      return res.status(404).send('User not found');
    }

    const { first_name, email } = user;

    // แปลง Base64 เป็น Binary และลดขนาดรูปภาพ 
    let imageBlob = null;
    if (imageUrl && imageUrl.trim() !== '') {
      try {
        const buffer = Buffer.from(imageUrl, 'base64'); // แปลง Base64 เป็น Buffer

        // ลดขนาดรูปภาพด้วย sharp
        imageBlob = await sharp(buffer)
          .resize({ width: 800 }) // ลดความกว้างภาพเป็น 800px
          .jpeg({ quality: 70 }) // ลดคุณภาพของ JPEG
          .toBuffer();

      } catch (err) {
        console.error('Error processing image with sharp:', err);
        connection.end(); // ใช้ end() แทน release()
        return res.status(400).send('Invalid image format or processing error');
      }
    }

    // บันทึกข้อมูลลงในฐานข้อมูล
    const sql = `
      INSERT INTO product (first_name, email, category, productName, productDescription, price, imageUrl, postedDate)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    await connection.query(sql, [
      first_name,
      email,
      category,
      productName,
      productDescription,
      price,
      imageBlob,
      postedDate,
    ]);

    connection.end(); // ใช้ end() แทน release()
    res.status(201).send('Post created successfully');
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).send('Internal Server Error');
  }
});


// API สำหรับดึงข้อมูล Product พร้อม Profile Picture
app.get('/getproduct', async (req, res) => {
  try {
    const connection = await getConnection(); // Establish connection to the database

    // Join product table with users table using email
    const query = `
      SELECT p.*, u.profile_picture
      FROM product p
      LEFT JOIN users u ON p.email = u.email
    `;
    const [rows] = await connection.query(query);

    // Format the product data, converting profile_picture to base64 if present
    const formattedProduct = rows.map(row => {
      return {
        ...row,
        imageUrl: row.imageUrl && Buffer.isBuffer(row.imageUrl) ? Buffer.from(row.imageUrl).toString('base64') : null,
        profile_picture: row.profile_picture && Buffer.isBuffer(row.profile_picture) ? Buffer.from(row.profile_picture).toString('base64') : null
      };
    });
    

    await connection.end(); // Close the connection
    res.json(formattedProduct); // Send the formatted product data as JSON
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
    const query = `
      SELECT p.*, u.first_name, u.email, u.profile_picture
      FROM product p
      LEFT JOIN users u ON p.email = u.email
      WHERE p.category = ?
    `;
    const [rows] = await connection.query(query, [category]);

    const formattedProduct = rows.map(row => ({
      ...row,
      imageUrl: row.imageUrl ? row.imageUrl.toString('base64') : null,
      profilePicture: row.profile_picture ? row.profile_picture.toString('base64') : null,
      firstName: row.first_name,
      email: row.email,
    }));

    await connection.end();
    res.json(formattedProduct);
  } catch (err) {
    console.error('Error fetching category products:', err);
    res.status(500).send('Internal Server Error');
  }
});

//โพสต์ทั้งหมด
app.get('/posts', async (req, res) => {
  console.log('Incoming request for /posts');
  try {
    const connection = await getConnection();
    const [rows] = await connection.query(`
      SELECT 
        p.id, 
        p.productName, 
        p.productDescription, 
        p.price, 
        p.imageUrl, 
        u.first_name, 
        u.profile_picture
      FROM product p
      LEFT JOIN users u ON p.email = u.email
    `);

    const formattedPosts = rows.map((row) => ({
      id: row.id,
      productName: row.productName,
      productDescription: row.productDescription,
      price: parseFloat(row.price),
      imageUrl: row.imageUrl ? row.imageUrl.toString('base64') : null, // แปลง Blob เป็น Base64
      firstName: row.first_name || 'Unknown User',
      profilePicture: row.profile_picture
        ? row.profile_picture.toString('base64') // แปลง Blob เป็น Base64
        : null,
    }));

    console.log('Data sent to client:', formattedPosts); // Debug ข้อมูล
    res.json(formattedPosts); // ส่งข้อมูลกลับใน JSON
  } catch (err) {
    console.error('Error fetching posts:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});
// API สำหรับดึงโพสต์ของผู้ใช้เฉพาะรายบุคคล
app.get('/postsByUser', async (req, res) => {
  const email = req.query.email; // รับ email จาก query parameter
  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  console.log(`Incoming request for /postsByUser?email=${email}`);

  try {
    const connection = await getConnection();

    // ดึงโพสต์เฉพาะของผู้ใช้งานตาม email
    const [rows] = await connection.query(`
      SELECT 
        p.id, 
        p.productName, 
        p.productDescription, 
        p.price, 
        p.imageUrl, 
        u.first_name, 
        u.profile_picture
      FROM product p
      LEFT JOIN users u ON p.email = u.email
      WHERE p.email = ?
    `, [email]);

    const formattedPosts = rows.map((row) => ({
      id: row.id,
      productName: row.productName,
      productDescription: row.productDescription,
      price: parseFloat(row.price),
      imageUrl: row.imageUrl ? row.imageUrl.toString('base64') : null, // แปลง Blob เป็น Base64
      firstName: row.first_name || 'Unknown User',
      profilePicture: row.profile_picture
        ? row.profile_picture.toString('base64') // แปลง Blob เป็น Base64
        : null,
    }));

    console.log('Filtered posts for user:', formattedPosts); // Debug ข้อมูล
    res.json(formattedPosts); // ส่งข้อมูลกลับใน JSON
  } catch (err) {
    console.error('Error fetching user posts:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});

//ผู้ใช้ทั้งหมดพร้อมรูป
app.get('/getAllUsers', async (req, res) => {
  try {
    const connection = await getConnection();
    const [rows] = await connection.query('SELECT id, first_name, profile_picture, email FROM users');

    if (rows.length > 0) {
      const users = rows.map(user => ({
        id: user.id,
        first_name: user.first_name,
        profile_picture: user.profile_picture
          ? user.profile_picture.toString('base64') // Convert to Base64 for frontend
          : null,
        email: user.email,
      }));
      res.json(users);
    } else {
      res.status(404).json({ message: 'No users found' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});


// API สำหรับสร้างหรืออัปเดตโปรไฟล์ผู้ใช้
app.post('/createOrUpdateUserProfile', async (req, res) => {
  const { firebaseUid, first_name, email } = req.body;

  console.log('Received data:', req.body); // เพิ่มบรรทัดนี้

  try {
    const connection = await getConnection();

    const [rows] = await connection.execute(
      'SELECT * FROM users WHERE firebase_uid = ?',
      [firebaseUid]
    );

    if (rows.length === 0) {
      const insertQuery = `
        INSERT INTO users (firebase_uid, first_name, email)
        VALUES (?, ?, ?)
      `;
      await connection.execute(insertQuery, [firebaseUid, first_name, email]);
      console.log('User profile created successfully.');
      res.status(201).send({ message: 'User profile created successfully.' });
    } else {
      console.log('User profile already exists.');
      res.status(200).send({ message: 'User profile already exists.' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error in createOrUpdateUserProfile:', err);
    res
      .status(500)
      .send({ message: 'Database transaction error: ' + err.message });
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

//fetching all users
app.get('/getAllUsers', async (req, res) => {
  try {
    const connection = await getConnection();
    const [rows] = await connection.query('SELECT id, first_name, profile_picture, email FROM users');

    if (rows.length > 0) {
      const users = rows.map(user => ({
        id: user.id,
        first_name: user.first_name,
        profile_picture: user.profile_picture
          ? user.profile_picture.toString('base64') // Convert to Base64 for frontend
          : null,
        email: user.email,
      }));
      res.json(users);
    } else {
      res.status(404).json({ message: 'No users found' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error fetching users:', err);
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

    // Ensure all required fields 
    if (!firebase_uid || !accountType || !title || !firstName || !lastName || !phoneNumber || !address || !bankName || !accountName || !accountNumber || !taxId || typeof vatRegistered === 'undefined') {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Check if the user already 
    const [existingUser] = await connection.execute(
      'SELECT * FROM recipients WHERE firebase_uid = ?',
      [firebase_uid]
    );

    if (existingUser.length > 0) {
      // Update if user 
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

// API สำหรับดึงข้อมูลโปรไฟล์ผู้ใช้
app.get('/getProfile', async (req, res) => {
  const email = req.query.email; // รับ email จาก query parameter

  if (!email) {
    return res.status(400).json({ message: 'Missing email parameter' });
  }

  try {
    const connection = await getConnection();

    // ดึงข้อมูลผู้ใช้จากฐานข้อมูล
    const [rows] = await connection.query(
      'SELECT first_name, profile_picture FROM users WHERE email = ?',
      [email]
    );

    if (rows.length > 0) {
      const user = rows[0];

      res.json({
        username: `${user.first_name} `, // รวมชื่อและนามสกุล
        profile_picture: user.profile_picture
          ? user.profile_picture.toString('base64') // แปลงภาพเป็น Base64
          : null,
      });
    } else {
      res.status(404).json({ message: 'User not found' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error fetching user profile:', err);
    res.status(500).json({ message: 'Internal server error', error: err.message });
  }
});

// API สำหรับเพิ่ม/ลบรายการโปรด
app.post('/toggleFavorite', async (req, res) => {
  let { email, product_id, is_favorite } = req.body;

  if (!email || !product_id) {
    return res.status(400).send({ message: 'Missing email or product_id' });
  }

  product_id = parseInt(product_id, 10);
  if (isNaN(product_id) || product_id <= 0) {
    return res.status(400).send({ message: 'Invalid product_id' });
  }

  is_favorite = is_favorite === true || is_favorite === 'true';

  let connection;
  try {
    connection = await getConnection();

    // ตรวจสอบว่าผลิตภัณฑ์มีอยู่ในฐานข้อมูล
    const [productCheck] = await connection.query(
      'SELECT id FROM product WHERE id = ?',
      [product_id]
    );
    if (productCheck.length === 0) {
      return res.status(404).send({ message: 'Product not found' });
    }

    if (is_favorite) {
      // เพิ่มรายการโปรด
      const sqlInsert =
        'INSERT INTO favorites (email, product_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE email = VALUES(email)';
      await connection.execute(sqlInsert, [email, product_id]);
    } else {
      // ลบรายการโปรด
      const [deleteResult] = await connection.execute(
        'DELETE FROM favorites WHERE email = ? AND product_id = ?',
        [email, product_id]
      );

      if (deleteResult.affectedRows === 0) {
        return res.status(404).send({ message: 'Favorite not found for deletion' });
      }
    }

    res.status(200).send({ message: 'Favorite status updated successfully' });
  } catch (error) {
    console.error('Error in toggleFavorite:', error);
    res.status(500).send({ message: 'Error updating favorite status', error });
  } finally {
    if (connection) {
      try {
        await connection.end();
      } catch (closeError) {
        console.error('Error closing the database connection:', closeError);
      }
    }
  }
});


//get fav
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

//getรายการโปรดเฉพาะรายบุคคล
app.post('/getproduct/fetchByIds', async (req, res) => {
  const { product_ids } = req.body;
  console.log('ff');

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
    console.log('ff2');
    if (rows.length === 0) {
      console.log('No product found for given IDs.');
    } else {
      console.log('Fetched product:', rows);
      
    }

    res.status(200).send(rows);
    console.log('ff3');
  } catch (error) {
    console.error('Error in /getproduct/fetchByIds:', error);
    res.status(500).send({ message: 'Error fetching product', error });
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
