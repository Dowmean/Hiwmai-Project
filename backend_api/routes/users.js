const express = require('express');
const getConnection = require('../config/database');
const router = express.Router();

const validRoles = ['User', 'Recipient', 'Admin'];

// ตรวจสอบ Role
router.get('/getUserRole', async (req, res) => {
  const email = req.query.email;

  if (!email) {
    return res.status(400).json({ message: 'Email is required' });
  }

  try {
    const connection = await getConnection();
    const [rows] = await connection.query(
      'SELECT role FROM users WHERE email = ?',
      [email]
    );

    if (rows.length > 0) {
      const userRole = rows[0].role;

      if (validRoles.includes(userRole)) {
        res.status(200).json({ role: userRole });
      } else {
        res.status(400).json({ message: 'Invalid role in database' });
      }
    } else {
      res.status(404).json({ message: 'User not found' });
    }

    await connection.end();
  } catch (error) {
    console.error('Error fetching user role:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;
