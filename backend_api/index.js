const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const dotenv = require('dotenv');
const userRoutes = require('./routes/userRoutes');
const productRoutes = require('./routes/productRoutes');

dotenv.config();
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// เส้นทางหลัก
app.use('/users', userRoutes);
app.use('/products', productRoutes);

// เส้นทางเริ่มต้น
app.get('/', (req, res) => {
  res.send('Welcome to the API');
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
