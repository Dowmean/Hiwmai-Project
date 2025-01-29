const mysql = require('mysql2/promise');  // ใช้ mysql2 ที่รองรับ promises
const bodyParser = require('body-parser');
const express = require('express'); // โหลดโมดูล
const cors = require('cors');
const reload = require('reload');
const fs = require('fs');
require('dotenv').config();  // ใช้ dotenv เพื่อดึงตัวแปรสภาพแวดล้อมจากไฟล์ .env
const app = express();
const admin = require('firebase-admin'); // เพิ่มการ require firebase-admin
const sharp = require('sharp');
const path = require('path');
const http = require('http');
const socketIo = require('socket.io');
const multer = require('multer');
const timeout = require('express-timeout-handler');


const timeoutOptions = {
  timeout: 60000, // 15 seconds
  onTimeout: (req, res) => {
    res.status(503).send({ message: 'Service Unavailable. Please try again later.' });
  },
  onDelayedResponse: (req, method, args, requestTime) => {
    console.warn('Response delayed:', { method, args, requestTime });
  },
};


//chats
// สร้าง HTTP Server
const server = http.createServer(app);
// ใช้ server กับ Socket.io
const { Server } = require('socket.io');
const io = new Server(server);


// กำหนด limit ของ body parser เพื่อรองรับข้อมูลขนาดใหญ่ เช่น รูปภาพ
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true }));
app.use(cors());
app.use(express.json({ limit: '10mb' }));
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
    password: process.env.DB_PASS || 'Dowmean.1006',
    database: process.env.DB_NAME || 'hiwmai'
  });
}

// เส้นทาง GET สำหรับ root URL
app.get('/', (req, res) => {
  res.send('Welcome to the API');
});


app.post('/api/register', async (req, res) => {
  console.log("Received Request:", req.body); // ✅ Debug: ดูค่าที่ส่งจาก Flutter

  const { firebase_uid, email, first_name } = req.body;

  if (!firebase_uid || !email || !first_name) {
    return res.status(400).json({ message: "Missing required fields" });
  }

  try {
    const connection = await getConnection();
    const sql = "INSERT INTO users (firebase_uid, email, first_name) VALUES (?, ?, ?)";
    
    await connection.execute(sql, [firebase_uid, email, first_name]);

    console.log("User inserted successfully"); // ✅ Debug: ดูว่าข้อมูลถูก INSERT หรือไม่

    connection.end();
    res.status(200).json({ message: "User registered successfully" });
  } catch (error) {
    console.error("Database Error:", error); // ✅ Debug: เช็ค Error
    res.status(500).json({ message: "Database error", error: error.message });
  }
});




// ตรวจสอบ 
// role ที่ได้รับจากฐานข้อมูล
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

//สิทโพสต์
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

//Regis recipients
app.post('/saveUserData', async (req, res) => {
  console.log('Received data:', req.body);
  try {
    const connection = await getConnection();

    const {
      firebase_uid,
      title,
      firstName,
      lastName,
      phoneNumber,
      address,
      bankName,
      accountName,
      accountNumber
    } = req.body;

    console.log('Preparing to insert or update data');

    // Ensure all required fields are provided
    if (!firebase_uid  || !title || !firstName || !lastName || !phoneNumber || !address || !bankName || !accountName || !accountNumber) {
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
          title = ?, first_name = ?, last_name = ?,
          phone_number = ?, address = ?, bank_name = ?, account_name = ?,
          account_number = ?
        WHERE firebase_uid = ?
      `;
      await connection.execute(updateSql, [
        title,
        firstName,
        lastName,
        phoneNumber,
        address,
        bankName,
        accountName,
        accountNumber,
        firebase_uid
      ]);

      console.log('Data updated successfully');
      res.status(200).json({ message: 'Data updated successfully' });
    } else {
      // Insert new record if user does not exist
      const insertSql = `
        INSERT INTO recipients 
        (firebase_uid, title, first_name, last_name, phone_number, address, bank_name, account_name, account_number) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      const [result] = await connection.execute(insertSql, [
        firebase_uid,
        title,
        firstName,
        lastName,
        phoneNumber,
        address,
        bankName,
        accountName,
        accountNumber
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


// เพิ่ม Static Route สำหรับภาพโปรไฟล์
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));

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

      // สร้าง URL สำหรับ profile_picture
      let profilePictureUrl = null;
      if (user.profile_picture) {
        profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${user.profile_picture}`;
      }

      res.json({
        username: `${user.first_name} `,
        profile_picture: profilePictureUrl, // ส่ง URL ของภาพโปรไฟล์แทน Base64
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



// เพิ่ม Static Route สำหรับรูปภาพโปรไฟล์
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));

// API สำหรับดึงรายการ Recipients
app.get('/getrecipients', async (req, res) => {
  try {
    const connection = await getConnection();
    // ใช้ INNER JOIN และ WHERE เพื่อตรวจสอบ role != 'Recipient'
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
      WHERE 
        users.role != 'Recipient'
    `);

    if (rows.length > 0) {
      const users = rows.map(user => {
        // สร้าง URL สำหรับรูปภาพโปรไฟล์
        const profilePictureUrl = user.profile_picture
          ? `${req.protocol}://${req.get('host')}/assets/images/profile/${user.profile_picture}`
          : null;

        return {
          id: user.id,
          first_name: user.first_name,
          profile_picture: profilePictureUrl, // ส่ง URL ของรูปภาพแทน Base64
          email: user.email,
        };
      });

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
// เพิ่ม Static Route สำหรับรูปภาพโปรไฟล์
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));

// ดึงข้อมูลผู้รับหิ้วทั้งหมด
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
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${row.profile_picture}`
        : null, // ส่ง URL ของรูปภาพแทน Base64
    }));

    res.status(200).json(recipients);
  } catch (err) {
    console.error('Error fetching recipients:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});

//Admin 
// ดึงข้อมูลตาม firebase_uid
app.get('/recipients/:firebase_uid', async (req, res) => {
  const { firebase_uid } = req.params;

  try {
    console.log('Requested firebase_uid:', firebase_uid);

    const connection = await getConnection();
    const query = `
      SELECT 
        r.bank_name, 
        r.account_name, 
        r.account_number,
        u.profile_picture
      FROM recipients r
      LEFT JOIN users u ON r.firebase_uid = u.firebase_uid
      WHERE r.firebase_uid = ?
    `;

    const [rows] = await connection.query(query, [firebase_uid]);

    console.log('Query result:', rows);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Recipient not found' });
    }

    const recipient = rows[0];
    res.status(200).json({
      bankName: recipient.bank_name,
      accountName: recipient.account_name,
      accountNumber: recipient.account_number,
      profilePicture: recipient.profile_picture
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${recipient.profile_picture}`
        : null, // ส่ง URL ของรูปภาพแทน Base64
    });
  } catch (err) {
    console.error('Error fetching recipient details:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});


//All
app.get('/recipients/:firebase_uid/ALLincome', async (req, res) => {
  const { firebase_uid } = req.params;

  try {
    console.log('Requested firebase_uid:', firebase_uid);

    const connection = await getConnection();
    const query = `
      SELECT 
        SUM(o.total) AS total_income,
        MIN(o.shopdate) AS first_shopdate,
        MAX(o.shopdate) AS last_shopdate,
        r.bank_name,
        r.account_name,
        r.account_number,
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON p.email = u.email
      LEFT JOIN recipients r ON u.firebase_uid = r.firebase_uid
      WHERE u.firebase_uid = ?
      GROUP BY r.bank_name, r.account_name, r.account_number, u.profile_picture;
    `;

    const [rows] = await connection.query(query, [firebase_uid]);

    console.log('Query result:', rows);

    if (rows.length === 0 || !rows[0].total_income) {
      return res.status(404).json({ message: 'No income found for this recipient' });
    }

    const recipient = rows[0];
    res.status(200).json({
      totalIncome: recipient.total_income,
      firstShopDate: recipient.first_shopdate,
      lastShopDate: recipient.last_shopdate,
      bankName: recipient.bank_name,
      accountName: recipient.account_name,
      accountNumber: recipient.account_number,
      profilePicture: recipient.profile_picture
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${recipient.profile_picture}`
        : null,
    });
  } catch (err) {
    console.error('Error fetching recipient income details:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});

//satus 
app.get('/recipients/:firebase_uid/Successincome', async (req, res) => {
  const { firebase_uid } = req.params;

  try {
    console.log('Requested firebase_uid:', firebase_uid);

    const connection = await getConnection();
    const query = `
      SELECT 
        SUM(o.total) AS total_income,
        MIN(o.shopdate) AS first_shopdate,
        MAX(o.shopdate) AS last_shopdate,
        r.bank_name,
        r.account_name,
        r.account_number,
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON p.email = u.email
      LEFT JOIN recipients r ON u.firebase_uid = r.firebase_uid
      WHERE u.firebase_uid = ?
      AND o.status IN ('ให้คะแนน', 'คำสั่งซื้อสำเร็จ')
      GROUP BY r.bank_name, r.account_name, r.account_number, u.profile_picture;
    `;

    const [rows] = await connection.query(query, [firebase_uid]);

    console.log('Query result:', rows);

    if (rows.length === 0 || !rows[0].total_income) {
      return res.status(404).json({ message: 'No income found for this recipient' });
    }

    const recipient = rows[0];
    res.status(200).json({
      totalIncome: recipient.total_income,
      firstShopDate: recipient.first_shopdate,
      lastShopDate: recipient.last_shopdate,
      bankName: recipient.bank_name,
      accountName: recipient.account_name,
      accountNumber: recipient.account_number,
      profilePicture: recipient.profile_picture
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${recipient.profile_picture}`
        : null,
    });
  } catch (err) {
    console.error('Error fetching recipient income details:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});


//satus 
app.get('/recipients/:firebase_uid/Complete', async (req, res) => {
  const { firebase_uid } = req.params;

  try {
    console.log('Requested firebase_uid:', firebase_uid);

    const connection = await getConnection();
    const query = `
      SELECT 
        SUM(o.total) AS total_income,
        MIN(o.shopdate) AS first_shopdate,
        MAX(o.shopdate) AS last_shopdate,
        r.bank_name,
        r.account_name,
        r.account_number,
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON p.email = u.email
      LEFT JOIN recipients r ON u.firebase_uid = r.firebase_uid
      WHERE u.firebase_uid = ?
      AND o.status IN ('ทำการจ่ายเรียบร้อยแล้ว')
      GROUP BY r.bank_name, r.account_name, r.account_number, u.profile_picture;
    `;

    const [rows] = await connection.query(query, [firebase_uid]);

    console.log('Query result:', rows);

    if (rows.length === 0 || !rows[0].total_income) {
      return res.status(404).json({ message: 'No income found for this recipient' });
    }

    const recipient = rows[0];
    res.status(200).json({
      totalIncome: recipient.total_income,
      firstShopDate: recipient.first_shopdate,
      lastShopDate: recipient.last_shopdate,
      bankName: recipient.bank_name,
      accountName: recipient.account_name,
      accountNumber: recipient.account_number,
      profilePicture: recipient.profile_picture
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${recipient.profile_picture}`
        : null,
    });
  } catch (err) {
    console.error('Error fetching recipient income details:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});

app.post('/recipients/:firebase_uid/transfer', async (req, res) => {
  const { firebase_uid } = req.params;
  const { reference_number } = req.body;

  if (!reference_number || reference_number.trim() === '') {
    return res.status(400).json({ message: 'Reference number is required' });
  }

  let connection;
  try {
    connection = await getConnection();

    // ดึงข้อมูลคำสั่งซื้อที่เกี่ยวข้อง โดยใช้ product_id หา email
    const [orderRows] = await connection.query(
      `
      SELECT 
        p.email,
        SUM(o.total) AS total_income,
        GROUP_CONCAT(o.ref) AS order_refs
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      WHERE p.email IS NOT NULL
        AND o.status IN ('ให้คะแนน', 'คำสั่งซื้อสำเร็จ')
      GROUP BY p.email;
      `
    );

    if (orderRows.length === 0 || !orderRows[0].total_income) {
      return res.status(404).json({ message: 'No pending income found for this recipient' });
    }

    const total_income = orderRows[0].total_income;
    const email = orderRows[0].email;
    const order_refs = orderRows[0].order_refs;
    console.log(`Total income found: ${total_income}`);
    console.log(`Order refs: ${order_refs}`);
    console.log(`Email: ${email}`);

    // ตรวจสอบว่า reference_number ซ้ำหรือไม่
    const [existingPayments] = await connection.query(
      `SELECT reference_number FROM payment WHERE reference_number = ?`,
      [reference_number]
    );

    if (existingPayments.length > 0) {
      return res.status(400).json({ message: 'Reference number already exists' });
    }

    // เริ่มการทำธุรกรรม
    await connection.beginTransaction();

    // บันทึกข้อมูลการโอนเงินลงในตาราง payment
    await connection.query(
      `
      INSERT INTO payment (email, income, datepay, reference_number)
      VALUES (?, ?, NOW(), ?);
      `,
      [email, total_income, reference_number]
    );

    // อัปเดตสถานะคำสั่งซื้อเป็น "ทำการจ่ายเรียบร้อยแล้ว"
    await connection.query(
      `
      UPDATE orders 
      SET status = 'ทำการจ่ายเรียบร้อยแล้ว'
      WHERE ref IN (?);
      `,
      [order_refs.split(',')]
    );

    // ยืนยันการทำธุรกรรม
    await connection.commit();

    res.status(200).json({ message: 'Transfer successful' });
  } catch (err) {
    console.error('Error during transfer:', err);

    // ยกเลิกการทำธุรกรรมหากเกิดข้อผิดพลาด
    if (connection) {
      await connection.rollback();
    }

    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});




app.post('/updateUserProfile', async (req, res) => {
  const { email, first_name, gender, birth_date, profile_picture } = req.body;

  // ตรวจสอบฟิลด์ที่จำเป็น
  if (!email || !first_name || !gender || !birth_date) {
    return res.status(400).send('Missing required fields');
  }

  const uploadPath = path.join(__dirname, 'assets/images/profile');

  // ตรวจสอบและสร้างโฟลเดอร์หากยังไม่มี
  if (!fs.existsSync(uploadPath)) {
    fs.mkdirSync(uploadPath, { recursive: true });
  }

  let profilePictureFileName = null;

  try {
    const connection = await getConnection();

    // แปลง Base64 เป็นไฟล์รูปภาพ (หากส่งมา)
    if (profile_picture && profile_picture.trim() !== '') {
      try {
        const buffer = Buffer.from(profile_picture, 'base64');
        const timestamp = Date.now();
        const randomString = Math.random().toString(36).substring(2, 8);
        profilePictureFileName = `profile_${timestamp}_${randomString}.jpeg`;
        const filePath = path.join(uploadPath, profilePictureFileName);

        // ลดขนาดรูปภาพด้วย sharp และบันทึกไฟล์
        await sharp(buffer)
          .resize({ width: 300, height: 300 }) // ปรับขนาดรูปภาพเป็น 300x300 พิกเซล
          .jpeg({ quality: 80 }) // ลดคุณภาพรูปภาพเพื่อให้ขนาดเล็กลง
          .toFile(filePath);
      } catch (err) {
        console.error('Error processing image with sharp:', err);
        connection.end();
        return res.status(400).send('Invalid image format or processing error');
      }
    }

    // อัปเดตข้อมูลในฐานข้อมูล
    const updateQuery = `
      UPDATE users 
      SET first_name = ?, gender = ?, birth_date = ?, profile_picture = ?
      WHERE email = ?
    `;
    const [results] = await connection.query(updateQuery, [
      first_name,
      gender,
      birth_date,
      profilePictureFileName,
      email,
    ]);

    if (results.affectedRows > 0) {
      res.status(200).send({ message: 'User profile updated successfully.' });
    } else {
      res.status(404).send({ message: 'User not found.' });
    }

    await connection.end();
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).send('Internal Server Error');
  }
});

// Route: แก้ไขโพสต์
app.put('/editpost/:id', async (req, res) => {
  const { id } = req.params;
  const { productName, productDescription, price, category, imageUrl, shipping, carry } = req.body;

  // Log ข้อมูลที่รับมาจาก Frontend
  console.log('Received request to edit post:');
  console.log('Params:', req.params);
  console.log('Body:', req.body);

  try {
    const connection = await getConnection();

    const [rows] = await connection.query('SELECT imageUrl FROM product WHERE id = ?', [id]);
    console.log('Existing post image path:', rows); // Log รูปภาพเดิม (ถ้ามี)

    const oldImagePath = rows[0]?.imageUrl || null;
    let newImagePath = oldImagePath;

    // ถ้ามีการอัปโหลดรูปภาพใหม่
    if (imageUrl && imageUrl.trim() !== '') {
      const timestamp = Date.now();
      const randomString = Math.random().toString(36).substring(2, 8);
      const newFileName = `${timestamp}-${randomString}.jpg`;
      const newFilePath = path.join(__dirname, 'assets/images/post', newFileName);

      const buffer = Buffer.from(imageUrl, 'base64');
      await sharp(buffer)
        .resize({ width: 800 })
        .jpeg({ quality: 70 })
        .toFile(newFilePath);

      newImagePath = `assets/images/post/${newFileName}`;
      console.log('New image path:', newImagePath);

      // ลบรูปภาพเก่าถ้าพบ
      if (oldImagePath && fs.existsSync(path.join(__dirname, oldImagePath))) {
        fs.unlinkSync(path.join(__dirname, oldImagePath));
        console.log('Deleted old image:', oldImagePath);
      }
    }

    const sql = `
      UPDATE product
      SET productName = ?, productDescription = ?, price = ?, category = ?, imageUrl = ?, shipping = ?, carry = ?
      WHERE id = ?`;
    console.log('SQL Query:', sql);

    const [result] = await connection.query(sql, [
      productName,
      productDescription,
      price,
      category,
      newImagePath,
      shipping,
      carry,
      id,
    ]);

    console.log('SQL Result:', result);

    await connection.end();

    if (result.affectedRows > 0) {
      res.json({ message: 'Post updated successfully' });
    } else {
      res.status(404).json({ message: 'Post not found or no changes made' });
    }
  } catch (error) {
    console.error('Error updating post:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


// Route: ลบโพสต์
app.delete('/deletepost/:id', async (req, res) => {
  const { id } = req.params;

  // Log ข้อมูลที่รับมาจาก Frontend
  console.log('Received request to delete post:');
  console.log('Params:', req.params);

  try {
    const connection = await getConnection();

    const [rows] = await connection.query('SELECT imageUrl FROM product WHERE id = ?', [id]);
    console.log('Existing post image path:', rows); // Log รูปภาพเดิม (ถ้ามี)

    const imagePath = rows[0]?.imageUrl || null;

    const sql = 'DELETE FROM product WHERE id = ?';
    console.log('SQL Query:', sql);

    const [result] = await connection.query(sql, [id]);
    console.log('SQL Result:', result);

    if (imagePath && fs.existsSync(path.join(__dirname, imagePath))) {
      fs.unlinkSync(path.join(__dirname, imagePath));
      console.log('Deleted image file:', imagePath);
    }

    await connection.end();

    if (result.affectedRows > 0) {
      res.json({ message: 'Post deleted successfully' });
    } else {
      res.status(404).json({ message: 'Post not found' });
    }
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});




// เพิ่ม Static Route สำหรับรูปภาพโปรไฟล์
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));

// API สำหรับดึงข้อมูล Product พร้อม Profile Picture
app.get('/getproduct', async (req, res) => {
  try {
    const connection = await getConnection(); // Establish connection to the database

    // Join product table with users table using email
    const query = `
      SELECT p.*, u.first_name, u.email, u.profile_picture
      FROM product p
      LEFT JOIN users u ON p.email = u.email
    `;
    const [rows] = await connection.query(query);

    // Format the product data
    const formattedProduct = rows.map(row => {
      let imageUrl = row.imageUrl;

      // ตรวจสอบว่า imageUrl เป็น Buffer และแปลงเป็น string
      if (Buffer.isBuffer(imageUrl)) {
        imageUrl = imageUrl.toString(); // แปลง Buffer เป็น string
      }

      // กำหนด path ของไฟล์สินค้า
      const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrl || '');
      let productImageUrl = null;

      try {
        if (imageUrl && fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrl}`;
        }
      } catch (error) {
        console.error('Error checking image file:', error);
      }

      // กำหนด path ของไฟล์โปรไฟล์
      const profilePictureUrl = row.profile_picture
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${row.profile_picture}`
        : null;

      return {
        id: row.id,
        productName: row.productName,
        category: row.category,
        price: row.price,
        imageUrl: productImageUrl, // URL รูปสินค้า
        profilePicture: profilePictureUrl, // URL รูปโปรไฟล์
        firstName: row.first_name || 'Unknown', // เพิ่ม first_name
        email: row.email || 'Unknown',
        postedDate: row.postedDate,
      };
    });

    await connection.end(); // Close the connection
    res.json(formattedProduct); // Send the formatted product data as JSON
  } catch (err) {
    console.error('Error fetching products:', err.message);
    console.error(err.stack);
    res.status(500).send('Internal Server Error');
  }
});



// API สำหรับดึงสินค้าตามหมวดหมู่
// Static route to serve profile pictures
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));
app.use('/assets/images/post', express.static(path.join(__dirname, 'assets', 'images', 'post')));

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

    const formattedProduct = rows.map(row => {
      let imageUrl = row.imageUrl;

      // ตรวจสอบว่า imageUrl เป็น Buffer และแปลงเป็น string
      if (Buffer.isBuffer(imageUrl)) {
        imageUrl = imageUrl.toString(); // แปลง Buffer เป็น string
      }

      // กำหนด path ของไฟล์สินค้า
      const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrl || '');
      let productImageUrl = null;

      try {
        if (imageUrl && fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrl}`;
        }
      } catch (error) {
        console.error('Error checking image file:', error);
      }

      // กำหนด path ของไฟล์โปรไฟล์
      const profilePictureUrl = row.profile_picture
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${row.profile_picture}`
        : null;

      return {
        id: row.id,
        productName: row.productName,
        category: row.category,
        price: row.price,
        imageUrl: productImageUrl, // URL รูปสินค้า
        profilePicture: profilePictureUrl, // URL รูปโปรไฟล์
        firstName: row.first_name || 'Unknown',
        email: row.email || 'Unknown',
      };
    });

    await connection.end();
    res.json(formattedProduct);
  } catch (err) {
    console.error('Error fetching category products:', err.message);
    console.error(err.stack);
    res.status(500).send('Internal Server Error');
  }
});

// Static route to serve profile pictures
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));

app.get('/product/:id', async (req, res) => {
  const productId = req.params.id;

  if (!productId) {
    return res.status(400).send({ message: 'Product ID is required' });
  }

  let connection;
  try {
    console.log('Fetching product with ID:', productId);

    connection = await getConnection();

    const [product] = await connection.query(
      `
      SELECT 
        p.id, 
        p.productName, 
        p.category, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS price, 
        p.imageUrl, 
        p.postedDate, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry,
        p.email,
        u.first_name,
        u.profile_picture
      FROM product p
      LEFT JOIN users u ON p.email = u.email
      WHERE p.id = ?
      `,
      [productId]
    );

    if (!product || product.length === 0) {
      console.error('Product not found');
      return res.status(404).send({ message: 'Product not found' });
    }

    // Handle product image URL
    let productImageUrl = null;
    if (product[0].imageUrl) {
      const imageUrlString = product[0].imageUrl.toString();
      const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
      if (fs.existsSync(imagePath)) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
      }
    }

    // Handle profile picture URL
    let profilePictureUrl = null;
    if (product[0].profile_picture) {
      const profilePictureFile = product[0].profile_picture.toString(); // Convert Buffer to string if necessary
      const profilePicturePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureFile);

      if (fs.existsSync(profilePicturePath)) {
        profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureFile}`;
      } else {
        console.error('Profile picture not found:', profilePicturePath);
      }
    }

    res.status(200).send({
      id: product[0].id,
      productName: product[0].productName,
      productDescription: product[0].productDescription,
      category: product[0].category,
      price: product[0].price,
      imageUrl: productImageUrl,
      postedDate: product[0].postedDate,
      shipping: product[0].shipping,
      carry: product[0].carry,
      email: product[0].email,
      firstName: product[0].first_name,
      profilePicture: profilePictureUrl, // ส่ง URL แทนการบีบอัด
    });
  } catch (error) {
    console.error('Error fetching product:', error.message);
    console.error(error.stack);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


//โพสต์ทั้งหมด
// เพิ่ม static route สำหรับโปรไฟล์
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));

// API สำหรับโพสต์ทั้งหมด
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

    const formattedPosts = rows.map((row) => {
      // สร้าง URL สำหรับ product image
      let productImageUrl = null;
      if (row.imageUrl) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${row.imageUrl}`;
      }

      // สร้าง URL สำหรับ profile picture
      let profilePictureUrl = null;
      if (row.profile_picture) {
        profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${row.profile_picture}`;
      }

      return {
        id: row.id,
        productName: row.productName,
        productDescription: row.productDescription,
        price: parseFloat(row.price),
        imageUrl: productImageUrl, // URL สำหรับภาพสินค้า
        firstName: row.first_name || 'Unknown User',
        profilePicture: profilePictureUrl, // URL สำหรับภาพโปรไฟล์
      };
    });

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

    const formattedPosts = rows.map((row) => {
      // ตรวจสอบและแปลง imageUrl
      let imageUrlString = row.imageUrl;
      if (Buffer.isBuffer(imageUrlString)) {
        imageUrlString = imageUrlString.toString(); // แปลง Buffer เป็น string
      }

      const productImageUrl = imageUrlString
        ? `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`
        : null;

      // ตรวจสอบและแปลง profile_picture
      let profilePictureString = row.profile_picture;
      if (Buffer.isBuffer(profilePictureString)) {
        profilePictureString = profilePictureString.toString(); // แปลง Buffer เป็น string
      }

      let profilePictureUrl = null;
      if (profilePictureString) {
        const profilePicturePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
        if (fs.existsSync(profilePicturePath)) {
          profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
        }
      }

      return {
        id: row.id,
        productName: row.productName || 'Unnamed Product',
        productDescription: row.productDescription || 'No description available',
        price: row.price ? parseFloat(row.price) : 0.0,
        imageUrl: productImageUrl,
        firstName: row.first_name || 'Unknown User',
        profilePicture: profilePictureUrl,
      };
    });

    console.log('Filtered posts for user:', formattedPosts);
    res.json(formattedPosts);
  } catch (err) {
    console.error('Error fetching user posts:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});



//PostDeatail 
app.get('/product/:id', async (req, res) => {
  const productId = req.params.id;

  if (!productId) {
    return res.status(400).send({ message: 'Product ID is required' });
  }

  let connection;
  try {
    console.log('Fetching product with ID:', productId); // Debug Step 1

    connection = await getConnection();
    console.log('Step 2: Connected to database'); // Debug Step 2

    const [product] = await connection.query(
      `
      SELECT 
        p.id, 
        p.productName, 
        p.category, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS price, 
        p.imageUrl, 
        p.postedDate, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry,
        p.email,
        u.first_name,
        u.profile_picture
      FROM product p
      LEFT JOIN users u ON p.email = u.email
      WHERE p.id = ?
      `,
      [productId]
    );

    if (!product || product.length === 0) {
      console.error('Step 3: Product not found'); // Debug Step 3
      return res.status(404).send({ message: 'Product not found' });
    }
    console.log('Step 4: Fetched product:', product[0]); // Debug Step 4

    // Handle imageUrl
    let productImageUrl = null;
    if (product[0].imageUrl) {
      let imageUrlString = product[0].imageUrl;

      // แปลง Buffer เป็น string (ถ้าจำเป็น)
      if (Buffer.isBuffer(imageUrlString)) {
        imageUrlString = imageUrlString.toString(); // แปลง Buffer เป็น string
      }

      const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
      if (fs.existsSync(imagePath)) {
        console.log('Step 5: Image exists at path:', imagePath); // Debug Step 5
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
      } else {
        console.error('Step 6: Product image not found:', imagePath); // Debug Step 6
      }
    }

    // Handle profile_picture compression
    let profilePictureBase64 = null;
    if (product[0].profile_picture) {
      try {
        console.log('Step 7: Compressing profile picture'); // Debug Step 7
        const buffer = Buffer.from(product[0].profile_picture, 'binary');
        const compressedBuffer = await sharp(buffer).resize({ width: 100 }).jpeg({ quality: 70 }).toBuffer();
        profilePictureBase64 = compressedBuffer.toString('base64'); // Convert to Base64
      } catch (sharpError) {
        console.error('Error compressing profile picture:', sharpError.message); // Debug sharp error
      }
    }

    res.status(200).send({
      id: product[0].id,
      productName: product[0].productName,
      productDescription: product[0].productDescription,
      category: product[0].category,
      price: product[0].price,
      imageUrl: productImageUrl,
      postedDate: product[0].postedDate,
      shipping: product[0].shipping,
      carry: product[0].carry,
      email: product[0].email, 
      firstName: product[0].first_name,
      profilePicture: profilePictureBase64,
    });
  } catch (error) {
    console.error('Error fetching product:', error.message);
    console.error(error.stack);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
      console.log('Step 8: Database connection closed'); // Debug Step 8
    }
  }
});


app.post('/createOrder', async (req, res) => {
  const { email, name, address, phone_number, total, num, note, product_id, image } = req.body;

  if (!email || !name || !address || !phone_number || !total || !num || !product_id) {
    return res.status(400).send({ message: 'Missing required fields' });
  }

  let connection;
  try {
    connection = await getConnection();

    // ตรวจสอบและแปลง total ให้เป็นตัวเลขก่อนบันทึก
    const parsedTotal = parseFloat(total);

    if (isNaN(parsedTotal)) {
      return res.status(400).send({ message: 'Invalid total value' });
    }

    // ตรวจสอบค่า image ถ้าไม่มี ให้ใช้ null
    const validatedImage = image || null;

    // สร้าง ref ล่วงหน้า
    const generatedRef = `ORD${new Date().toISOString().slice(0, 10).replace(/-/g, '')}${Math.floor(Math.random() * 1000000).toString().padStart(6, '0')}`;

    // ดำเนินการ INSERT
    await connection.execute(
      `INSERT INTO orders 
      (ref, email, name, address, phone_number, total, num, note, product_id, image, shopdate, status) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'ยังไม่ชำระ')`,
      [generatedRef, email, name, address, phone_number, parsedTotal, num, note, product_id, validatedImage]
    );

    // ส่ง ref กลับใน response
    res.status(201).send({ message: 'Order created successfully', ref: generatedRef });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

//ที่อยู่
//เพิ่มที่อยู่
// ✅ เพิ่มที่อยู่
app.post("/addresses", async (req, res) => {
  const { firebase_uid, email, name, phone, address_detail, province, district, subdistrict, postal_code, is_default, address_type } = req.body;

  try {
    const connection = await getConnection();
    
    // ถ้าเป็นที่อยู่เริ่มต้น ต้องรีเซ็ตที่อยู่เริ่มต้นอื่นๆก่อน
    if (is_default) {
      await connection.execute("UPDATE addresses SET is_default = FALSE WHERE firebase_uid = ?", [firebase_uid]);
    }

    const sql = `
      INSERT INTO addresses 
      (firebase_uid, email, name, phone, address_detail, province, district, subdistrict, postal_code, is_default, address_type) 
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    await connection.execute(sql, [firebase_uid, email, name, phone, address_detail, province, district, subdistrict, postal_code, is_default, address_type]);

    connection.end();
    res.status(201).json({ message: "Address added successfully" });
  } catch (error) {
    res.status(500).json({ message: "Database error", error: error.message });
  }
});


// ✅ ดึงข้อมูลจังหวัดทั้งหมด
app.get("/provinces", async (req, res) => {
  try {
    const connection = await getConnection();
    const [rows] = await connection.execute("SELECT id, name_th FROM provinces ORDER BY name_th");
    connection.end();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ ดึงอำเภอตามจังหวัด
app.get("/amphures/:province_id", async (req, res) => {
  try {
    const { province_id } = req.params;
    const connection = await getConnection();
    const [rows] = await connection.execute("SELECT id, name_th FROM amphures WHERE province_id = ? ORDER BY name_th", [province_id]);
    connection.end();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ ดึงตำบลตามอำเภอ
app.get("/districts/:amphure_id", async (req, res) => {
  try {
    const { amphure_id } = req.params;
    const connection = await getConnection();
    const [rows] = await connection.execute("SELECT id, name_th, zip_code FROM districts WHERE amphure_id = ? ORDER BY name_th", [amphure_id]);
    connection.end();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});


// ✅ ดึงรายการที่อยู่ของผู้ใช้
app.get("/addresses/:firebase_uid", async (req, res) => {
  try {
    const connection = await getConnection();
    const [rows] = await connection.execute(
      "SELECT * FROM addresses WHERE firebase_uid = ? ORDER BY is_default DESC",
      [req.params.firebase_uid]
    );
    connection.end();
    res.status(200).json(rows);
  } catch (error) {
    res.status(500).json({ message: "Database error", error: error.message });
  }
});


//ลบที่อยู่
// ✅ ลบที่อยู่
app.delete("/addresses/:id", async (req, res) => {
  try {
    const connection = await getConnection();
    await connection.execute("DELETE FROM addresses WHERE id = ?", [req.params.id]);
    connection.end();
    res.status(200).json({ message: "Address deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Database error", error: error.message });
  }
});


//Recip
// API: ดึงข้อมูลคำสั่งซื้อ recipt
app.get('/getOrdersByEmail', async (req, res) => {
  const userEmail = req.query.email; // รับ email จาก Query Parameter

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();

    // JOIN ตาราง orders, product, และ users
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE p.email = ?
      `,
      [userEmail] // กรอง product.email ให้ตรงกับ userEmail
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No orders found for this user' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching orders by email:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


//Users
// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ยังไม่ชำระ"
app.get('/TopayOrdersByEmail', async (req, res) => {
  const userEmail = req.query.email;

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();
    console.log('Database connected');

    // ดึงข้อมูลคำสั่งซื้อ
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE o.email = ? AND o.status = 'ยังไม่ชำระ'
      `,
      [userEmail]
    );

    console.log('Query result:', orders);

    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No unpaid orders found for this user' });
    }

    // แปลง imageUrl และ profile_picture เป็น URL
    const updatedOrders = orders.map((order) => {
      let productImageUrl = null;
      let profilePictureUrl = null;

      // แปลง product_image เป็น URL
      if (order.product_image) {
        let imageUrlString = order.product_image;
        if (Buffer.isBuffer(imageUrlString)) {
          imageUrlString = imageUrlString.toString();
        }

        const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
        if (fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
        }
      }

      // แปลง profile_picture เป็น URL
      if (order.profile_picture) {
        let profilePictureString = order.profile_picture;
        if (Buffer.isBuffer(profilePictureString)) {
          profilePictureString = profilePictureString.toString();
        }

        const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
        if (fs.existsSync(profilePath)) {
          profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
        }
      }

      return {
        ...order,
        product_image: productImageUrl,
        profile_picture: profilePictureUrl,
      };
    });

    res.status(200).send({
      message: 'Unpaid orders fetched successfully',
      orders: updatedOrders,
    });
  } catch (error) {
    console.error('Error fetching unpaid orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "กำลังจัดส่ง" user
app.get('/ShippingOrdersByEmailUser', async (req, res) => {
  const userEmail = req.query.email;

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();
    console.log('Database connected');

    // ดึงข้อมูลคำสั่งซื้อ
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        TRIM(LOWER(o.email)) AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        TRIM(LOWER(o.status)) AS status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON TRIM(LOWER(o.email)) = TRIM(LOWER(u.email))
      WHERE TRIM(LOWER(o.email)) = TRIM(LOWER(?)) 
        AND TRIM(LOWER(o.status)) = 'กำลังจัดส่ง'
      `,
      [userEmail.trim().toLowerCase()]
    );

    console.log('Query result:', orders);

    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No orders with status "กำลังจัดส่ง" found for this user' });
    }

    // แปลง imageUrl และ profile_picture เป็น URL
    const updatedOrders = orders.map((order) => {
      let productImageUrl = null;
      let profilePictureUrl = null;

      // แปลง product_image เป็น URL
      if (order.product_image) {
        let imageUrlString = order.product_image;
        if (Buffer.isBuffer(imageUrlString)) {
          imageUrlString = imageUrlString.toString();
        }

        const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
        if (fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
        }
      }

      // แปลง profile_picture เป็น URL
      if (order.profile_picture) {
        let profilePictureString = order.profile_picture;
        if (Buffer.isBuffer(profilePictureString)) {
          profilePictureString = profilePictureString.toString();
        }

        const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
        if (fs.existsSync(profilePath)) {
          profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
        }
      }

      return {
        ...order,
        product_image: productImageUrl,
        profile_picture: profilePictureUrl,
      };
    });

    res.status(200).send({
      message: 'Orders with status "กำลังจัดส่ง" fetched successfully',
      orders: updatedOrders,
    });
  } catch (error) {
    console.error('Error fetching orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


// API: อัปเดตสถานะคำสั่งซื้อเป็น 'คำสั่งซื้อสำเร็จ' user
app.put('/updateSuccessOrderStatus', async (req, res) => {
  const { orderRef } = req.body; // รับค่า orderRef จาก body

  if (!orderRef) {
    return res.status(400).send({ message: 'Missing required parameter: orderRef' });
  }

  let connection;
  try {
    connection = await getConnection();

    // อัปเดตสถานะคำสั่งซื้อ
    const [result] = await connection.query(
      `UPDATE orders SET status = 'คำสั่งซื้อสำเร็จ' WHERE ref = ?`,
      [orderRef]
    );

    if (result.affectedRows === 0) {
      return res.status(404).send({ message: 'Order not found or already updated.' });
    }

    res.status(200).send({ message: 'Order status updated successfully.' });
  } catch (error) {
    console.error('Error updating order status:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "คำสั่งซื้อสำเร็จ" user
app.get('/SuccessOrdersByEmailUser', async (req, res) => {
  const userEmail = req.query.email;

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();
    console.log('Database connected');

    // ดึงข้อมูลคำสั่งซื้อ
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        TRIM(LOWER(o.email)) AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        TRIM(LOWER(o.status)) AS status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON TRIM(LOWER(o.email)) = TRIM(LOWER(u.email))
      WHERE TRIM(LOWER(o.email)) = TRIM(LOWER(?)) 
        AND TRIM(LOWER(o.status)) = 'คำสั่งซื้อสำเร็จ'
      `,
      [userEmail.trim().toLowerCase()]
    );

    console.log('Query result:', orders);

    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No orders with status "กำลังจัดส่ง" found for this user' });
    }

    // แปลง imageUrl และ profile_picture เป็น URL
    const updatedOrders = orders.map((order) => {
      let productImageUrl = null;
      let profilePictureUrl = null;

      // แปลง product_image เป็น URL
      if (order.product_image) {
        let imageUrlString = order.product_image;
        if (Buffer.isBuffer(imageUrlString)) {
          imageUrlString = imageUrlString.toString();
        }

        const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
        if (fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
        }
      }

      // แปลง profile_picture เป็น URL
      if (order.profile_picture) {
        let profilePictureString = order.profile_picture;
        if (Buffer.isBuffer(profilePictureString)) {
          profilePictureString = profilePictureString.toString();
        }

        const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
        if (fs.existsSync(profilePath)) {
          profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
        }
      }

      return {
        ...order,
        product_image: productImageUrl,
        profile_picture: profilePictureUrl,
      };
    });

    res.status(200).send({
      message: 'Orders with status "กำลังจัดส่ง" fetched successfully',
      orders: updatedOrders,
    });
  } catch (error) {
    console.error('Error fetching orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ให้คะแนน" user
app.get('/ReviewsOrdersByEmailUser', async (req, res) => {
  const userEmail = req.query.email;

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();
    console.log('Database connected');

    // ดึงข้อมูลคำสั่งซื้อ
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        TRIM(LOWER(o.email)) AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        TRIM(LOWER(o.status)) AS status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON TRIM(LOWER(o.email)) = TRIM(LOWER(u.email))
WHERE TRIM(LOWER(o.email)) = TRIM(LOWER(?)) 
  AND TRIM(LOWER(o.status)) IN ('ให้คะแนน', 'ทำการจ่ายเรียบร้อยแล้ว')

      `,
      [userEmail.trim().toLowerCase()]
    );

    console.log('Query result:', orders);

    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No orders with status "กำลังจัดส่ง" found for this user' });
    }

    // แปลง imageUrl และ profile_picture เป็น URL
    const updatedOrders = orders.map((order) => {
      let productImageUrl = null;
      let profilePictureUrl = null;

      // แปลง product_image เป็น URL
      if (order.product_image) {
        let imageUrlString = order.product_image;
        if (Buffer.isBuffer(imageUrlString)) {
          imageUrlString = imageUrlString.toString();
        }

        const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
        if (fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
        }
      }

      // แปลง profile_picture เป็น URL
      if (order.profile_picture) {
        let profilePictureString = order.profile_picture;
        if (Buffer.isBuffer(profilePictureString)) {
          profilePictureString = profilePictureString.toString();
        }

        const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
        if (fs.existsSync(profilePath)) {
          profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
        }
      }

      return {
        ...order,
        product_image: productImageUrl,
        profile_picture: profilePictureUrl,
      };
    });

    res.status(200).send({
      message: 'Orders with status "กำลังจัดส่ง" fetched successfully',
      orders: updatedOrders,
    });
  } catch (error) {
    console.error('Error fetching orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ดึงข้อมูลคำสั่งซื้อทั้งหมด user
app.get('/OrderHistoryUser', async (req, res) => {
  const userEmail = req.query.email;

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();
    console.log('Database connected');

    // ดึงข้อมูลคำสั่งซื้อ
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        TRIM(LOWER(o.email)) AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON TRIM(LOWER(o.email)) = TRIM(LOWER(u.email))
      WHERE TRIM(LOWER(o.email)) = TRIM(LOWER(?)) 
        
      `,
      [userEmail.trim().toLowerCase()]
    );

    console.log('Query result:', orders);

    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No orders  for this user' });
    }

    // แปลง imageUrl และ profile_picture เป็น URL
    const updatedOrders = orders.map((order) => {
      let productImageUrl = null;
      let profilePictureUrl = null;

      // แปลง product_image เป็น URL
      if (order.product_image) {
        let imageUrlString = order.product_image;
        if (Buffer.isBuffer(imageUrlString)) {
          imageUrlString = imageUrlString.toString();
        }

        const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
        if (fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
        }
      }

      // แปลง profile_picture เป็น URL
      if (order.profile_picture) {
        let profilePictureString = order.profile_picture;
        if (Buffer.isBuffer(profilePictureString)) {
          profilePictureString = profilePictureString.toString();
        }

        const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
        if (fs.existsSync(profilePath)) {
          profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
        }
      }

      return {
        ...order,
        product_image: productImageUrl,
        profile_picture: profilePictureUrl,
      };
    });

    res.status(200).send({
      message: 'Orders with fetched successfully',
      orders: updatedOrders,
    });
  } catch (error) {
    console.error('Error fetching orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});



//Admin 
// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ยังไม่ชำระ"
app.get('/ToPayOrders', async (req, res) => {
  let connection;
  try {
    connection = await getConnection();

    // ดึงข้อมูลจากตาราง orders, product, และ users เฉพาะที่ status = "ยังไม่ชำระ"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE o.status = 'ยังไม่ชำระ'
      `
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No unpaid orders found' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Unpaid orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching unpaid orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: อัปเดตสถานะคำสั่งซื้อเป็น 'ชำระเงินสำเร็จ'
app.put('/updateOrderStatus', async (req, res) => {
  const { orderRef } = req.body; // รับค่า orderRef จาก body

  if (!orderRef) {
    return res.status(400).send({ message: 'Missing required parameter: orderRef' });
  }

  let connection;
  try {
    connection = await getConnection();

    // อัปเดตสถานะคำสั่งซื้อ
    const [result] = await connection.query(
      `UPDATE orders SET status = 'ชำระเงินสำเร็จ' WHERE ref = ?`,
      [orderRef]
    );

    if (result.affectedRows === 0) {
      return res.status(404).send({ message: 'Order not found or already updated.' });
    }

    res.status(200).send({ message: 'Order status updated successfully.' });
  } catch (error) {
    console.error('Error updating order status:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "คำสั่งซื้อสำเร็จ" และ "ให้คะแนน"
app.get('/SuccessAndReviewOrders', async (req, res) => {
  let connection;
  try {
    connection = await getConnection();

    // ดึงข้อมูลจากตาราง orders, product, และ users ที่ status = "คำสั่งซื้อสำเร็จ" หรือ "ให้คะแนน"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE o.status IN ('คำสั่งซื้อสำเร็จ', 'ให้คะแนน', 'ทำการจ่ายเรียบร้อยแล้ว') -- เงื่อนไขสถานะ
      `
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No orders with status "คำสั่งซื้อสำเร็จ" or "ให้คะแนน" found' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Orders with status "คำสั่งซื้อสำเร็จ" and "ให้คะแนน" fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});



//Recipt
// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ยังไม่ชำระ"  
app.get('/getTopayOrdersByEmail', async (req, res) => {
  const userEmail = req.query.email; // รับ email จาก Query Parameter

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();

    // JOIN ตาราง orders, product, และ users เฉพาะที่ status = "ยังไม่ชำระ"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE p.email = ? AND o.status = 'ยังไม่ชำระ'
      `,
      [userEmail] // กรอง product.email ให้ตรงกับ userEmail
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No completed orders found for this user' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Completed orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching completed orders by email:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});



// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ทำการจ่ายเรียบร้อยแล้ว"
app.get('/TranfercompletedOrders', async (req, res) => {
  let connection;
  try {
    connection = await getConnection();

    // ดึงข้อมูลจากตาราง orders, product, และ users เฉพาะที่ status = "ชำระเงินสำเร็จ"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE o.status = 'ทำการจ่ายเรียบร้อยแล้ว'
      `
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No unpaid orders found' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Unpaid orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching unpaid orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ทำการจ่ายเรียบร้อยแล้ว"
app.get('/TranfercompletedOrders', async (req, res) => {
  let connection;
  try {
    connection = await getConnection();

    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE o.status = 'ทำการจ่ายเรียบร้อยแล้ว'
      `
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No unpaid orders found' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Unpaid orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching unpaid orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

//Orders satatus ยกเลิก
// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ยกเลิก"
app.get('/OrderscancleAdmin', async (req, res) => {
  let connection;
  try {
    connection = await getConnection();

    // ดึงข้อมูลจากตาราง orders, product, และ users เฉพาะที่ status = "ยกเลิก"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE o.status = 'ยกเลิก'
      `
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No unpaid orders found' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Unpaid orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching unpaid orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: อัปเดตสถานะคำสั่งซื้อเป็น "คืนเงินแล้ว"
app.put('/refundOrderAdmin', async (req, res) => {
  const { orderRef } = req.body;

  if (!orderRef) {
      return res.status(400).json({ message: 'Missing required parameter: orderRef' });
  }

  let connection;
  try {
      connection = await getConnection(); // ใช้ getConnection() เชื่อมต่อ MySQL

      // ตรวจสอบว่าคำสั่งซื้อมีสถานะ "ยกเลิก" หรือไม่
      const [existingOrder] = await connection.query(
          `SELECT * FROM orders WHERE ref = ? AND status = 'ยกเลิก'`,
          [orderRef]
      );

      if (existingOrder.length === 0) {
          return res.status(404).json({ message: 'Order not found or not eligible for refund' });
      }

      // อัปเดตสถานะเป็น "คืนเงินแล้ว"
      await connection.query(
          `UPDATE orders SET status = 'คืนเงินแล้ว' WHERE ref = ?`,
          [orderRef]
      );

      res.status(200).json({ message: 'Refund processed successfully' });
  } catch (error) {
      console.error('Error processing refund:', error);
      res.status(500).json({ message: 'Internal Server Error' });
  } finally {
      if (connection) {
          await connection.end();
      }
  }
});


// API: ดึงข้อมูลคำสั่งซื้อทั้งหมด (ไม่กรอง status)
app.get('/OrderHistoryAdmin', async (req, res) => {
  let connection;
  try {
    connection = await getConnection();
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note,
        o.status, 
        o.product_id, 
        o.shopdate,  
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      ` 
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No orders found' });
    }

    // แปลง image paths เป็น URL
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // ตรวจสอบและแปลง URL สำหรับ product_image
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }
          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // ตรวจสอบและแปลง URL สำหรับ profile_picture
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }
          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'All orders fetched successfully', 
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching orders:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


//Recip
// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ที่ต้องจัดส่ง"
app.get('/getToshipOrdersByEmail', async (req, res) => {
  const userEmail = req.query.email; // รับ email จาก Query Parameter

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();

    // JOIN ตาราง orders, product, และ users เฉพาะที่ status = "ที่ต้องจัดส่ง"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE p.email = ? AND o.status = ('ที่ต้องจัดส่ง')
      `,
      [userEmail] // กรอง product.email ให้ตรงกับ userEmail
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No completed orders found for this user' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Completed orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching completed orders by email:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

//เพิ่มเลขพัสดุ
app.post('/addTrackingNumber', async (req, res) => {
  const { ref, trackingNumber } = req.body;

  if (!ref || !trackingNumber) {
    return res.status(400).send({ message: 'Missing required parameters' });
  }

  let connection;
  try {
    connection = await getConnection();

    // ตรวจสอบคำสั่งซื้อและดึง email ของเจ้าของสินค้า
    const [order] = await connection.query(
      `
      SELECT o.*, p.email AS owner_email
      FROM orders o
      JOIN product p ON o.product_id = p.id
      WHERE o.ref = ?
      `,
      [ref]
    );

    if (!order.length) {
      return res.status(404).send({ message: 'Order not found' });
    }

    const { owner_email } = order[0];

    // เพิ่มเลขพัสดุใน Table purchase
    await connection.query(
      `
      INSERT INTO purchase (ref, email, trackingnumber, confirm_order)
      VALUES (?, ?, ?, TRUE)
      ON DUPLICATE KEY UPDATE
      trackingnumber = VALUES(trackingnumber),
      confirm_order = TRUE
      `,
      [ref, owner_email, trackingNumber]
    );

    // อัปเดตสถานะใน Table orders เป็น "กำลังจัดส่ง"
    await connection.query(
      `
      UPDATE orders
      SET status = 'กำลังจัดส่ง'
      WHERE ref = ?
      `,
      [ref]
    );

    res.status(200).send({ message: 'Tracking number added and status updated successfully' });
  } catch (error) {
    console.error('Error adding tracking number:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});



// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "กำลังจัดส่ง"
app.get('/getShippingOrdersByEmail', async (req, res) => {
  const userEmail = req.query.email; // รับ email จาก Query Parameter

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();

    // JOIN ตาราง orders, product, และ users เฉพาะที่ status = "กำลังจัดส่ง"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE p.email = ? AND o.status = 'กำลังจัดส่ง'
      `,
      [userEmail] // กรอง product.email ให้ตรงกับ userEmail
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No completed orders found for this user' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Completed orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching completed orders by email:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});



app.get('/getReviewDetails', async (req, res) => {
  const { email, orderRef } = req.query;

  if (!email || !orderRef) {
    return res.status(400).send({ message: 'Missing required parameters' });
  }

  let connection;
  try {
    connection = await getConnection();
    const [reviewDetails] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref,
        o.email AS order_email,
        p.productName,
        p.imageUrl AS product_image,
        u.first_name,
        u.profile_picture,
        r.rate AS review_rate,
        r.description AS review_description
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      LEFT JOIN reviews r ON o.ref = r.ref
      WHERE o.email = ? AND o.ref = ?
      `,
      [email, orderRef]
    );

    if (!reviewDetails || reviewDetails.length === 0) {
      return res.status(404).send({ message: 'No review found for this order' });
    }

    const review = reviewDetails[0];

    // Debug ข้อมูลก่อนแปลง
    console.log('Fetched Review:', review);

    // ตรวจสอบและแปลงค่าที่เป็น Buffer ให้เป็น String
    const productImage = Buffer.isBuffer(review.product_image)
      ? review.product_image.toString()
      : review.product_image;

    const profilePicture = Buffer.isBuffer(review.profile_picture)
      ? review.profile_picture.toString()
      : review.profile_picture;

    // จัดการรูปภาพสินค้า
    let productImageUrl = null;
    if (productImage) {
      const productImagePath = path.join(__dirname, 'assets', 'images', 'post', productImage);
      if (fs.existsSync(productImagePath)) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${productImage}`;
      } else {
        console.warn(`Product image not found: ${productImagePath}`);
      }
    }

    // จัดการรูปโปรไฟล์ผู้ใช้งาน
    let profilePictureUrl = null;
    if (profilePicture) {
      const profilePicturePath = path.join(__dirname, 'assets', 'images', 'profile', profilePicture);
      if (fs.existsSync(profilePicturePath)) {
        profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePicture}`;
      } else {
        console.warn(`Profile picture not found: ${profilePicturePath}`);
      }
    }

    // Debug ข้อมูล URL ที่สร้าง
    console.log('Product Image URL:', productImageUrl);
    console.log('Profile Picture URL:', profilePictureUrl);

    // ส่งข้อมูลพร้อมลิงก์รูปภาพที่ปรับแล้ว
    res.status(200).send({
      order_ref: review.order_ref,
      order_email: review.order_email,
      first_name: review.first_name, // เพิ่ม u.first_name
      productName: review.productName,
      product_image: productImageUrl,
      profile_picture: profilePictureUrl,
      review_rate: review.review_rate,
      review_description: review.review_description,
    });
  } catch (error) {
    console.error('Error fetching review details:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});




// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "คำสั่งซื้อสำเร็จ"
app.get('/getCompletedOrdersByEmail', async (req, res) => {
  const userEmail = req.query.email; // รับ email จาก Query Parameter

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();

    // JOIN ตาราง orders, product, และ users เฉพาะที่ status = "ตำสั่งซื้อสำเร็จ"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE p.email = ? AND o.status = 'คำสั่งซื้อสำเร็จ'
      `,
      [userEmail] // กรอง product.email ให้ตรงกับ userEmail
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No completed orders found for this user' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Completed orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching completed orders by email:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ดึงข้อมูลคำสั่งซื้อที่สถานะเป็น "ให้คะแนน"
app.get('/getReviewsOrdersByEmail', async (req, res) => {
  const userEmail = req.query.email; // รับ email จาก Query Parameter

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();

    // JOIN ตาราง orders, product, และ users เฉพาะที่ status = "สำเร็จ"
    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      WHERE p.email = ? AND o.status IN ('ให้คะแนน', 'ทำการจ่ายเรียบร้อยแล้ว')
      `,
      [userEmail] // กรอง product.email ให้ตรงกับ userEmail
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No completed orders found for this user' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Completed orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching completed orders by email:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


// API: ยกเลิกคำสั่งซื้อ
app.put('/cancelOrder', async (req, res) => {
  const { orderRef } = req.body;

  if (!orderRef) {
    return res.status(400).send({ message: 'Missing required parameter: orderRef' });
  }

  let connection;
  try {
    connection = await getConnection();
    const [result] = await connection.query(
      `UPDATE orders SET status = 'ยกเลิก' WHERE ref = ?`,
      [orderRef]
    );

    if (result.affectedRows === 0) {
      return res.status(404).send({ message: 'Order not found' });
    }

    res.status(200).send({ message: 'Order canceled successfully' });
  } catch (error) {
    console.error('Error updating order status:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});




// API: เพิ่มรีวิวสำหรับคำสั่งซื้อ
app.post('/addReview', async (req, res) => {
  const { ref, email, rate, description } = req.body;

  if (!ref || !email || !rate || rate < 1 || rate > 5 || !description) {
    return res.status(400).send({
      message: 'Missing or invalid parameters. Please ensure all fields are valid.',
    });
  }

  let connection;
  try {
    connection = await getConnection();

    // ตรวจสอบว่าคำสั่งซื้อมีอยู่ใน Table: orders และสถานะเป็น "สำเร็จ"
    const [orderCheck] = await connection.query(
      'SELECT * FROM orders WHERE ref = ? AND email = ? AND status = "คำสั่งซื้อสำเร็จ"',
      [ref, email]
    );

    if (orderCheck.length === 0) {
      return res.status(404).send({
        message: 'Order not found or not completed. Cannot add review.',
      });
    }

    // เพิ่มรีวิวลงใน Table: reviews
    const [insertResult] = await connection.query(
      `
      INSERT INTO reviews (ref, email, rate, description)
      VALUES (?, ?, ?, ?)
      `,
      [ref, email, rate, description]
    );

    // อัปเดตสถานะใน Table: orders ให้เป็น "ให้คะแนน"
    await connection.query(
      `
      UPDATE orders
      SET status = "ให้คะแนน"
      WHERE ref = ? AND email = ?
      `,
      [ref, email]
    );

    res.status(201).send({
      message: 'Review added successfully and order status updated!',
      reviewId: insertResult.insertId,
    });
  } catch (error) {
    console.error('Error adding review:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

//คำสั่งซื้อทั้งหมดนักหิ้ว
app.get('/OrderHistoryRecipient', async (req, res) => {
  const userEmail = req.query.email; // รับ email จาก Query Parameter

  if (!userEmail) {
    return res.status(400).send({ message: 'Missing required parameter: email' });
  }

  let connection;
  try {
    connection = await getConnection();

    const [orders] = await connection.query(
      `
      SELECT 
        o.ref AS order_ref, 
        o.email AS order_email, 
        o.name, 
        o.address, 
        o.phone_number, 
        o.total, 
        o.num AS quantity, 
        o.note, 
        o.product_id, 
        o.shopdate, 
        o.status, 
        p.productName, 
        p.productDescription, 
        CAST(p.price AS DECIMAL(10, 2)) AS product_price, 
        p.imageUrl AS product_image, 
        p.category, 
        CAST(p.shipping AS DECIMAL(10, 2)) AS shipping_cost, 
        CAST(p.carry AS DECIMAL(10, 2)) AS carry_cost, 
        p.email AS product_email, 
        u.first_name AS ordered_by, 
        u.profile_picture
      FROM orders o
      LEFT JOIN product p ON o.product_id = p.id
      LEFT JOIN users u ON o.email = u.email
      
      `,
      [userEmail] // กรอง product.email ให้ตรงกับ userEmail
    );

    // ตรวจสอบว่าพบคำสั่งซื้อหรือไม่
    if (!orders || orders.length === 0) {
      return res.status(404).send({ message: 'No completed orders found for this user' });
    }

    // จัดการ product_image และ profile_picture
    const processedOrders = await Promise.all(
      orders.map(async (order) => {
        let productImageUrl = null;
        let profilePictureUrl = null;

        // แปลง product_image เป็น URL หรือ Base64
        if (order.product_image) {
          let imageUrlString = order.product_image;
          if (Buffer.isBuffer(imageUrlString)) {
            imageUrlString = imageUrlString.toString();
          }

          const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrlString);
          if (fs.existsSync(imagePath)) {
            productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrlString}`;
          }
        }

        // แปลง profile_picture เป็น URL
        if (order.profile_picture) {
          let profilePictureString = order.profile_picture;
          if (Buffer.isBuffer(profilePictureString)) {
            profilePictureString = profilePictureString.toString();
          }

          const profilePath = path.join(__dirname, 'assets', 'images', 'profile', profilePictureString);
          if (fs.existsSync(profilePath)) {
            profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${profilePictureString}`;
          }
        }

        return {
          ...order,
          product_image: productImageUrl,
          profile_picture: profilePictureUrl,
        };
      })
    );

    res.status(200).send({
      message: 'Completed orders fetched successfully',
      orders: processedOrders,
    });
  } catch (error) {
    console.error('Error fetching completed orders by email:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
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

  // ตรวจสอบฟิลด์ที่จำเป็น
  if (!email || !first_name || !gender || !birth_date) {
    return res.status(400).send('Missing required fields');
  }

  const uploadPath = path.join(__dirname, 'assets/images/profile');

  // ตรวจสอบและสร้างโฟลเดอร์หากยังไม่มี
  if (!fs.existsSync(uploadPath)) {
    fs.mkdirSync(uploadPath, { recursive: true });
  }

  let profilePictureFileName = null;

  try {
    const connection = await getConnection();

    // แปลง Base64 เป็นไฟล์รูปภาพ (หากส่งมา)
    if (profile_picture && profile_picture.trim() !== '') {
      try {
        const buffer = Buffer.from(profile_picture, 'base64');
        const timestamp = Date.now();
        const randomString = Math.random().toString(36).substring(2, 8);
        profilePictureFileName = `profile_${timestamp}_${randomString}.jpeg`;
        const filePath = path.join(uploadPath, profilePictureFileName);

        // ลดขนาดรูปภาพด้วย sharp และบันทึกไฟล์
        await sharp(buffer)
          .resize({ width: 300, height: 300 }) // ปรับขนาดรูปภาพเป็น 300x300 พิกเซล
          .jpeg({ quality: 80 }) // ลดคุณภาพรูปภาพเพื่อให้ขนาดเล็กลง
          .toFile(filePath);
      } catch (err) {
        console.error('Error processing image with sharp:', err);
        connection.end();
        return res.status(400).send('Invalid image format or processing error');
      }
    }

    // อัปเดตข้อมูลในฐานข้อมูล
    const updateQuery = `
      UPDATE users 
      SET first_name = ?, gender = ?, birth_date = ?, profile_picture = ?
      WHERE email = ?
    `;
    const [results] = await connection.query(updateQuery, [
      first_name,
      gender,
      birth_date,
      profilePictureFileName,
      email,
    ]);

    if (results.affectedRows > 0) {
      res.status(200).send({ message: 'User profile updated successfully.' });
    } else {
      res.status(404).send({ message: 'User not found.' });
    }

    await connection.end();
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).send('Internal Server Error');
  }
});


// API สำหรับดึงข้อมูลผู้ใช้
// เพิ่ม Static Route สำหรับรูปภาพโปรไฟล์
app.use('/assets/images/profile', express.static(path.join(__dirname, 'assets', 'images', 'profile')));

// API สำหรับดึงข้อมูลโปรไฟล์ผู้ใช้
app.get('/getUserProfile', async (req, res) => {
  const email = req.query.email;

  try {
    const connection = await getConnection();
    const [rows] = await connection.query('SELECT * FROM users WHERE email = ?', [email]);

    if (rows.length > 0) {
      const user = rows[0];
      const profilePictureUrl = user.profile_picture
        ? `${req.protocol}://${req.get('host')}/assets/images/profile/${user.profile_picture}`
        : null; // ส่ง URL ของรูปภาพแทน Base64

      res.json({
        username: user.first_name,
        gender: user.gender,
        birth_date: user.birth_date,
        profile_picture: profilePictureUrl, // ส่ง URL ของรูปภาพแทน Base64
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


app.get('/getAllUsers', async (req, res) => {
  try {
    const connection = await getConnection();
    const [rows] = await connection.query('SELECT id, first_name, profile_picture, email FROM users');

    if (rows.length > 0) {
      const users = rows.map(user => {
        const profilePictureUrl = user.profile_picture
          ? `${req.protocol}://${req.get('host')}/assets/images/profile/${user.profile_picture}`
          : null;

        // Debug logging
        console.log(`User: ${user.first_name}, Profile Picture URL: ${profilePictureUrl}`);

        return {
          id: user.id,
          first_name: user.first_name,
          profile_picture: profilePictureUrl, // ส่ง URL
          email: user.email,
        };
      });

      res.json(users);
    } else {
      console.log('No users found in database');
      res.status(404).json({ message: 'No users found' });
    }

    await connection.end();
  } catch (err) {
    console.error('Error fetching users:', err);
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

app.post('/getproduct/fetchByIds', async (req, res) => {
  const { product_ids } = req.body;

  if (!product_ids || !Array.isArray(product_ids)) {
    return res.status(400).send({ message: 'Invalid product IDs' });
  }

  let connection;
  try {
    connection = await getConnection();

    const placeholders = product_ids.map(() => '?').join(',');
    const sqlSelect = `
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
      WHERE p.id IN (${placeholders})
    `;

    const [rows] = await connection.execute(sqlSelect, product_ids);

    // จัดรูปแบบข้อมูลและสร้าง URL สำหรับ imageUrl และ profile_picture
    const formattedProducts = rows.map((row) => {
      // จัดการ product image URL
      let productImageUrl = null;
      if (row.imageUrl) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${row.imageUrl}`;
      }

      // จัดการ profile picture URL
      let profilePictureUrl = null;
      if (row.profile_picture) {
        profilePictureUrl = `${req.protocol}://${req.get('host')}/assets/images/profile/${row.profile_picture}`;
      }

      return {
        id: row.id,
        productName: row.productName,
        productDescription: row.productDescription,
        price: parseFloat(row.price),
        imageUrl: productImageUrl, // URL ของภาพสินค้า
        firstName: row.first_name || 'Unknown User',
        profilePicture: profilePictureUrl, // URL ของรูปโปรไฟล์
      };
    });

    res.status(200).send(formattedProducts); // ส่งข้อมูลกลับใน JSON
  } catch (error) {
    console.error('Error in /getproduct/fetchByIds:', error);
    res.status(500).send({ message: 'Error fetching product', error });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


// WebSocket Logic สำหรับแชทเรียลไทม์
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('joinRoom', ({ sender, receiver }) => {
    const roomId = [sender, receiver].sort().join('_');
    socket.join(roomId);
    console.log(`${sender} joined room: ${roomId}`);
  });
  
  io.on('connection', (socket) => {
    socket.on('sendMessage', (data) => {
      // แจ้งข้อความให้ Client ฝั่ง Receiver
      io.to(data.receiver).emit('receiveMessage', data);
    });
  });
  
  socket.on('sendMessage', async (data) => {
    const { sender, receiver, message, imageUrl } = data;
    const roomId = [sender, receiver].sort().join('_');

    let connection;
    try {
      connection = await getConnection();
      await connection.query(
        'INSERT INTO chats (sender_email, receiver_email, message, image_url) VALUES (?, ?, ?, ?)',
        [sender, receiver, message, imageUrl]
      );
      io.to(roomId).emit('receiveMessage', data); // ส่งข้อความให้ทุกคนในห้อง
    } catch (error) {
      console.error('Error saving message:', error);
    } finally {
      if (connection) {
        await connection.end();
      }
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// API: ดึงรายละเอียดผู้ใช้
app.get('/getUserDetails', async (req, res) => {
  const { email } = req.query;
  console.log(`Received email: ${email}`); // Debug email

  if (!email) {
    return res.status(400).send({ message: 'Email is required' });
  }

  let connection;
  try {
    connection = await getConnection();
    const [rows] = await connection.query(
      'SELECT first_name, profile_picture FROM users WHERE email = ?',
      [email]
    );

    console.log(`Query Result: ${rows}`); // Debug query result

    if (rows.length === 0) {
      console.log('User not found'); // Debug user not found
      return res.status(404).send({ message: 'User not found' });
    }

    const profilePictureUrl = rows[0].profile_picture
    ? `${req.protocol}://${req.get('host')}/assets/images/profile/${rows[0].profile_picture}`
    : null;
  
  res.json({
    first_name: rows[0].first_name,
    profile_picture: profilePictureUrl,
  });
  
  
  } catch (error) {
    console.error('Error fetching user details:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});



// API: ดึงข้อความแชท
app.get('/fetchChats', async (req, res) => {
  const { sender, receiver } = req.query;
  if (!sender || !receiver) {
    return res.status(400).send({ message: 'Sender and Receiver are required' });
  }

  try {
    const connection = await getConnection();
    const [rows] = await connection.query(
      `
      SELECT sender_email, receiver_email, message, image_url, timestamp 
      FROM chats 
      WHERE (sender_email = ? AND receiver_email = ?) 
         OR (sender_email = ? AND receiver_email = ?) 
      ORDER BY timestamp ASC
      `,
      [sender, receiver, receiver, sender]
    );

    const formattedRows = rows.map((row) => ({
      sender_email: row.sender_email,
      receiver_email: row.receiver_email,
      message: row.message,
      image_url: row.image_url
  ? `${req.protocol}://${req.get('host')}/assets/images/messages/${path.basename(row.image_url)}`
  : null,



      timestamp: row.timestamp,
    }));

    res.json(formattedRows);
  } catch (error) {
    console.error('Error fetching chats:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  }
});

app.get('/test-message-image', (req, res) => {
  const filePath = path.join(__dirname, 'assets', 'images', 'messages', 'message_1736791055332.jpg');
  if (fs.existsSync(filePath)) {
    res.sendFile(filePath);
  } else {
    res.status(404).send({ message: 'File not found' });
  }
});
3

// Static route สำหรับเสิร์ฟรูปภาพจาก assets/images/chat
app.use('/assets/images/messages', express.static(path.join(__dirname, 'assets', 'images', 'messages')));
// API: ส่งข้อความแชท (รองรับรูปภาพ)

// API: ส่งข้อความแชท (รองรับรูปภาพ)
app.post('/sendMessage', async (req, res) => {
  const { sender, receiver, message, imageBase64 } = req.body;

  if (!sender || !receiver || (!message && !imageBase64)) {
    return res.status(400).send({ message: 'Sender, Receiver, and either Message or ImageUrl are required' });
  }

  let imageUrl = null;

  if (imageBase64) {
    try {
      const buffer = Buffer.from(imageBase64, 'base64');
      const fileName = `message_${Date.now()}.jpg`;
      const filePath = path.join(__dirname, 'assets', 'images', 'messages', fileName);

      fs.writeFileSync(filePath, buffer);
      imageUrl = `/assets/images/messages/${fileName}`;
    } catch (err) {
      console.error('Error saving image:', err);
      return res.status(500).send({ message: 'Error saving image' });
    }
  }

  try {
    const connection = await getConnection();
    await connection.query(
      'INSERT INTO chats (sender_email, receiver_email, message, image_url) VALUES (?, ?, ?, ?)',
      [sender, receiver, message || null, imageUrl || null]
    );
    res.status(200).send({ message: 'Message saved successfully', imageUrl });
  } catch (error) {
    console.error('Error saving message:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  }
})

// Static route สำหรับเสิร์ฟรูปภาพจาก assets/images/chat
app.use('/assets/images/messages', express.static(path.join(__dirname, 'assets', 'images', 'messages')));




app.get('/getMessagesForReceiver', async (req, res) => {
  const { receiver } = req.query;

  if (!receiver) {
    return res.status(400).send({ message: 'Receiver email is required' });
  }

  console.log('Fetching messages for receiver:', receiver); // Debugging

  let connection;
  try {
    connection = await getConnection();
    const [rows] = await connection.query(
      `
      SELECT sender_email, receiver_email, message, image_url, timestamp 
      FROM chats 
      WHERE receiver_email = ? 
      ORDER BY timestamp DESC
      `,
      [receiver]
    );

    if (rows.length === 0) {
      console.log('No messages found for receiver:', receiver); // Debugging
      return res.status(404).send({ message: 'No messages found for this receiver' });
    }

    res.json(
      rows.map((row) => ({
        sender_email: row.sender_email,
        receiver_email: row.receiver_email,
        message: row.message,
        image_url: row.image_url
  ? `${req.protocol}://${req.get('host')}/assets/images/messages/${path.basename(row.image_url)}`
  : null,

        timestamp: row.timestamp,
      }))
    );
    
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


app.get('/getMessageSenders', async (req, res) => {
  const { email } = req.query;

  if (!email) {
    return res.status(400).send({ message: 'Email is required' });
  }

  let connection;
  try {
    connection = await getConnection();
    const [rows] = await connection.query(
      `
      SELECT DISTINCT u.first_name, u.profile_picture, c.sender_email 
      FROM users u 
      JOIN chats c 
      ON u.email = c.sender_email 
      WHERE c.receiver_email = ?
      `,
      [email]
    );

    res.json(
      rows.map((row) => ({
        first_name: row.first_name,
        profile_picture: row.profile_picture
          ? `${req.protocol}://${req.get('host')}/assets/images/profile/${row.profile_picture}`
          : null,
        sender_email: row.sender_email,
      }))
    );
    
  } catch (error) {
    console.error('Error fetching message senders:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

// API: ค้นหาสินค้าจาก productName
// API: ค้นหาสินค้าจาก productName
app.get('/searchProducts', async (req, res) => {
  const searchTerm = req.query.productName;

  if (!searchTerm) {
    return res.status(400).send({ message: 'Missing required parameter: productName' });
  }

  let connection;
  try {
    connection = await getConnection();
    console.log('Database connected for product search.');

    // ค้นหาสินค้าจาก productName
    const [products] = await connection.query(
      `
      SELECT 
        id,
        productName,
        productDescription,
        CAST(price AS CHAR) AS price, -- ✅ แปลง DECIMAL เป็น CHAR เพื่อป้องกันปัญหา
        imageUrl,
        category,
        CAST(shipping AS CHAR) AS shipping_cost,
        CAST(carry AS CHAR) AS carry_cost
      FROM product
      WHERE LOWER(productName) LIKE ?
      `,
      [`%${searchTerm.toLowerCase()}%`]
    );

    if (!products || products.length === 0) {
      return res.status(404).send({ message: 'No products found' });
    }

    // ปรับ URL ของรูปภาพให้ถูกต้อง
    const updatedProducts = products.map((product) => {
      let productImageUrl = null;

      if (product.imageUrl) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${product.imageUrl}`;
      }

      return {
        ...product,
        imageUrl: productImageUrl,
      };
    });

    res.status(200).send({
      message: 'Products fetched successfully',
      products: updatedProducts,
    });
  } catch (error) {
    console.error('Error searching products:', error.message);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});

//เพิ่มบัญชีธนาคาร
app.post("/bank-accounts", async (req, res) => {
  const { firebase_uid, email, fullname, banknumber, bankname, is_default } = req.body;

  try {
    const connection = await getConnection();
    
    // ถ้าบัญชีนี้เป็นค่าเริ่มต้น ให้รีเซ็ตบัญชีอื่นๆก่อน
    if (is_default) {
      await connection.execute("UPDATE bank_accounts SET is_default = FALSE WHERE firebase_uid = ?", [firebase_uid]);
    }

    const sql = "INSERT INTO bank_accounts (firebase_uid, email, fullname, banknumber, bankname, is_default) VALUES (?, ?, ?, ?, ?, ?)";
    await connection.execute(sql, [firebase_uid, email, fullname, banknumber, bankname, is_default]);

    connection.end();
    res.status(201).json({ message: "Bank account added successfully" });
  } catch (error) {
    res.status(500).json({ message: "Database error", error: error.message });
  }
});

//ดึงบัญชีธนาคารของลูกค้า
app.get("/bank-accounts/:firebase_uid", async (req, res) => {
  try {
    const connection = await getConnection();
    const [rows] = await connection.execute(
      "SELECT * FROM bank_accounts WHERE firebase_uid = ? ORDER BY is_default DESC",
      [req.params.firebase_uid]
    );
    connection.end();
    res.status(200).json(rows);
  } catch (error) {
    res.status(500).json({ message: "Database error", error: error.message });
  }
});

//ลบบัญชีธนาคาร
app.delete("/bank-accounts/:id", async (req, res) => {
  try {
    const connection = await getConnection();
    await connection.execute("DELETE FROM bank_accounts WHERE id = ?", [req.params.id]);
    connection.end();
    res.status(200).json({ message: "Bank account deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Database error", error: error.message });
  }
});



// กำหนด port ของเซิร์ฟเวอร์
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
