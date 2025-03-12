const mysql = require('mysql2/promise');

// ฟังก์ชันสำหรับเชื่อมต่อฐานข้อมูล
async function getConnection() {
  return await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'Dowmean',
    password: process.env.DB_PASS || '',
    database: process.env.DB_NAME || 'hiwmai',
  });
}

module.exports = getConnection;
