const express = require('express');
const getConnection = require('../config/database');
const checkRoleOrOwnership = require('../middleware/authMiddleware');
const router = express.Router();

// ตรวจสอบสิทธิ์ในการเข้าถึง Product
router.post('/checkRoleAndOwnership', checkRoleOrOwnership, async (req, res) => {
  res.status(200).json({ message: 'Permission granted' });
});

module.exports = router;
