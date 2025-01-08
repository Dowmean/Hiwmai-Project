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

// เปิดใช้งาน reload
reload(app).then(() => {
  console.log('Reload is enabled');
}).catch(err => {
  console.error('Failed to enable reload:', err);
});

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


//get list req recip
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
app.post('/createpost', async (req, res) => {
  const {
    firebase_uid,
    category,
    productName,
    productDescription,
    price,
    imageUrl,
    shipping,
    carry
  } = req.body;

  // ตรวจสอบฟิลด์ที่จำเป็น
  if (
    !firebase_uid ||
    !category ||
    !productName ||
    !productDescription ||
    !price ||
    shipping === undefined ||
    carry === undefined
  ) {
    return res.status(400).send('Missing required fields');
  }

  const postedDate = new Date();
  const uploadPath = path.join(__dirname, 'assets/images/post');

  // ตรวจสอบและสร้างโฟลเดอร์หากยังไม่มี
  if (!fs.existsSync(uploadPath)) {
    fs.mkdirSync(uploadPath, { recursive: true });
  }

  try {
    const connection = await getConnection();

    // ตรวจสอบผู้ใช้
    const [users] = await connection.query(
      'SELECT first_name, email FROM users WHERE firebase_uid = ?',
      [firebase_uid]
    );
    const user = users[0];

    if (!user) {
      connection.end();
      return res.status(404).send('User not found');
    }

    const { first_name, email } = user;

    // แปลง Base64 เป็นไฟล์รูปภาพ
    let imageFileName = null;
    if (imageUrl && imageUrl.trim() !== '') {
      try {
        const buffer = Buffer.from(imageUrl, 'base64');
        const timestamp = Date.now();
        const randomString = Math.random().toString(36).substring(2, 8);
        imageFileName = `${timestamp}-${randomString}.jpg`;
        const filePath = path.join(uploadPath, imageFileName);

        // ลดขนาดรูปภาพด้วย sharp และบันทึกไฟล์
        await sharp(buffer)
          .resize({ width: 800 })
          .jpeg({ quality: 70 })
          .toFile(filePath);
      } catch (err) {
        console.error('Error processing image with sharp:', err);
        connection.end();
        return res.status(400).send('Invalid image format or processing error');
      }
    }

    // บันทึกข้อมูลลงในฐานข้อมูล
    const sql = `
      INSERT INTO product (first_name, email, category, productName, productDescription, price, shipping, carry, imageUrl, postedDate)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    await connection.query(sql, [
      first_name,
      email,
      category,
      productName,
      productDescription,
      price,
      shipping,
      carry,
      imageFileName, // ใช้ชื่อไฟล์แทน Base64
      postedDate,
    ]);

    connection.end();
    res.status(201).send('Post created successfully');
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).send('Internal Server Error');
  }
});

// Route: แก้ไขโพสต์
app.put('/editpost/:id', async (req, res) => {
  const { id } = req.params;
  const { productName, productDescription, price, category, imageUrl, shipping, carry } = req.body;

  try {
    const connection = await getConnection();

    // ดึงข้อมูลโพสต์เก่าเพื่อลบรูปภาพเดิมออก
    const [rows] = await connection.query('SELECT imageUrl FROM product WHERE id = ?', [id]);
    const oldImagePath = rows[0]?.imageUrl || null;

    let newImagePath = oldImagePath;

    // ถ้ามีรูปภาพใหม่
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

      if (oldImagePath && fs.existsSync(path.join(__dirname, oldImagePath))) {
        fs.unlinkSync(path.join(__dirname, oldImagePath));
      }
    }

    // อัปเดตโพสต์ในฐานข้อมูล
    const sql = `
      UPDATE product
      SET productName = ?, productDescription = ?, price = ?, category = ?, imageUrl = ?, shipping = ?, carry = ?
      WHERE id = ?`;
    await connection.query(sql, [
      productName,
      productDescription,
      price,
      category,
      newImagePath,
      shipping,
      carry,
      id
    ]);

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

    // ดึงข้อมูลโพสต์เพื่อลบรูปภาพ
    const [rows] = await connection.query('SELECT imageUrl FROM product WHERE id = ?', [id]);
    const imagePath = rows[0]?.imageUrl || null;

    // ลบโพสต์ในฐานข้อมูล
    const sql = 'DELETE FROM product WHERE id = ?';
    await connection.query(sql, [id]);

    // ลบไฟล์รูปภาพ (ถ้ามี)
    if (imagePath && fs.existsSync(path.join(__dirname, imagePath))) {
      fs.unlinkSync(path.join(__dirname, imagePath));
    }

    await connection.end();
    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});


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

      // กำหนด path ของไฟล์
      const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrl || '');
      let productImageUrl = null;

      try {
        if (imageUrl && fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrl}`;
        }
      } catch (error) {
        console.error('Error checking image file:', error);
      }

      return {
        id: row.id,
        productName: row.productName,
        category: row.category,
        price: row.price,
        imageUrl: productImageUrl, // URL รูปสินค้า
        profilePicture: row.profile_picture ? row.profile_picture.toString('base64') : null, // รูปโปรไฟล์ใน Base64
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

// Static route to serve image files
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

      // กำหนด path ของไฟล์
      const imagePath = path.join(__dirname, 'assets', 'images', 'post', imageUrl || '');
      let productImageUrl = null;

      try {
        if (imageUrl && fs.existsSync(imagePath)) {
          productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${imageUrl}`;
        }
      } catch (error) {
        console.error('Error checking image file:', error);
      }

      return {
        id: row.id,
        productName: row.productName,
        category: row.category,
        price: row.price,
        imageUrl: productImageUrl, // URL รูปสินค้า
        profilePicture: row.profile_picture ? row.profile_picture.toString('base64') : null, // รูปโปรไฟล์ใน Base64
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

app.use('/assets/images/post', express.static(path.join(__dirname, 'assets', 'images', 'post')));



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

    const formattedPosts = rows.map((row) => {
      // ตรวจสอบและสร้าง URL สำหรับ imageUrl
      let productImageUrl = null;
      if (row.imageUrl) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${row.imageUrl}`;
      }

      return {
        id: row.id,
        productName: row.productName,
        productDescription: row.productDescription,
        price: parseFloat(row.price),
        imageUrl: productImageUrl, // เปลี่ยนเป็น URL ของภาพ
        firstName: row.first_name || 'Unknown User',
        profilePicture: row.profile_picture
          ? row.profile_picture.toString('base64') // แปลง Blob เป็น Base64
          : null,
      };
    });

    console.log('Data sent to client:', formattedPosts); // Debug ข้อมูล
    res.json(formattedPosts); // ส่งข้อมูลกลับใน JSON
  } catch (err) {
    console.error('Error fetching posts:', err);
    res.status(500).json({ error: 'Internal Server Error', details: err.message });
  }
});

// Static route to serve image files
app.use('/assets/images/post', express.static(path.join(__dirname, 'assets', 'images', 'post')));


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

    const formattedPosts = rows.map((row) => {
      // สร้าง URL สำหรับ imageUrl
      let productImageUrl = null;
      if (row.imageUrl) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${row.imageUrl}`;
      }

      return {
        id: row.id,
        productName: row.productName,
        productDescription: row.productDescription,
        price: parseFloat(row.price),
        imageUrl: productImageUrl, // ใช้ URL ของภาพ
        firstName: row.first_name || 'Unknown User',
        profilePicture: row.profile_picture
          ? row.profile_picture.toString('base64') // แปลง Blob เป็น Base64
          : null,
      };
    });

    console.log('Filtered posts for user:', formattedPosts); // Debug ข้อมูล
    res.json(formattedPosts); // ส่งข้อมูลกลับใน JSON
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


// API: สร้างคำสั่งซื้อใหม่
app.post('/createOrder', async (req, res) => {
  const { email, name, address, phone_number, total, num, note, product_id, image } = req.body;

  if (!email || !name || !address || !phone_number || !total || !num || !product_id) {
    return res.status(400).send({ message: 'Missing required fields' });
  }

  let connection;
  try {
    connection = await getConnection();

    // ตรวจสอบและแปลง total ให้เป็นตัวเลขก่อนบันทึก
    const parsedTotal = parseFloat(total); // แปลง total เป็นตัวเลข

    if (isNaN(parsedTotal)) {
      return res.status(400).send({ message: 'Invalid total value' });
    }

    const result = await connection.query(
      `INSERT INTO orders 
      (ref, email, name, address, phone_number, total, num, note, product_id, image, shopdate, status) 
      VALUES (
        CONCAT('ORD', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(FLOOR(RAND() * 100000), 6, '0')),
        ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), 'กำลังจัดส่ง')`,
      [email, name, address, phone_number, parsedTotal, num, note, product_id, image]
    );

    res.status(201).send({ message: 'Order created successfully', order_id: result.insertId });
  } catch (error) {
    console.error('Error creating order:', error);
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
        username: `${user.first_name} `,
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

    // จัดรูปแบบข้อมูลและสร้าง URL สำหรับ imageUrl
    const formattedProducts = rows.map((row) => {
      let productImageUrl = null;
      if (row.imageUrl) {
        productImageUrl = `${req.protocol}://${req.get('host')}/assets/images/post/${row.imageUrl}`;
      }

      return {
        id: row.id,
        productName: row.productName,
        productDescription: row.productDescription,
        price: parseFloat(row.price),
        imageUrl: productImageUrl, // ใช้ URL ของภาพ
        firstName: row.first_name || 'Unknown User',
        profilePicture: row.profile_picture
          ? row.profile_picture.toString('base64') // แปลง Blob เป็น Base64
          : null,
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



// Multer สำหรับจัดการการอัปโหลดไฟล์ภาพ
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, './uploads');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});
const upload = multer({ storage });
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API: อัปโหลดภาพ
app.post('/upload', upload.single('image'), (req, res) => {
  const file = req.file;
  if (!file) {
    return res.status(400).send('No file uploaded.');
  }
  res.json({ imageUrl: `/uploads/${file.filename}` });
});

// API: ดึงรายละเอียดผู้ใช้
app.get('/getUserDetails', async (req, res) => {
  const { email } = req.query;
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

    if (rows.length === 0) {
      return res.status(404).send({ message: 'User not found' });
    }

    res.json({
      first_name: rows[0].first_name,
      profile_picture: rows[0].profile_picture
        ? rows[0].profile_picture.toString('base64')
        : null,
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

  let connection;
  try {
    connection = await getConnection();
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
    res.json(rows);
  } catch (error) {
    console.error('Error fetching chats:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


// API: ส่งข้อความแชท
app.post('/sendMessage', async (req, res) => {
  const { sender, receiver, message, imageUrl } = req.body;

  if (!sender || !receiver || !message) {
    return res.status(400).send({ message: 'Sender, Receiver, and Message are required' });
  }

  console.log('Data received from Flutter:', { sender, receiver, message, imageUrl }); // Debugging

  try {
    const connection = await getConnection();
    await connection.query(
      'INSERT INTO chats (sender_email, receiver_email, message, image_url) VALUES (?, ?, ?, ?)',
      [sender, receiver, message, imageUrl]
    );
    res.status(200).send({ message: 'Message saved successfully' });
  } catch (error) {
    console.error('Error saving message:', error);
    res.status(500).send({ message: 'Internal Server Error' });
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

    res.json(rows);
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

    res.json(rows.map(row => ({
      first_name: row.first_name,
      profile_picture: row.profile_picture
        ? row.profile_picture.toString('base64')
        : null,
      sender_email: row.sender_email,
    })));
  } catch (error) {
    console.error('Error fetching message senders:', error);
    res.status(500).send({ message: 'Internal Server Error' });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});


// กำหนด port ของเซิร์ฟเวอร์
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
