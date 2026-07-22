const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const userRoutes = require('./lib/core/routes/userRoutes');
app.use('/user', userRoutes);

const budgetRoutes = require('./lib/core/routes/budgetRoutes');
app.use('/budget', budgetRoutes);

const notificationRoutes = require('./lib/core/routes/notificationRoutes');
app.use('/notification', notificationRoutes);

const transactionRoutes = require('./lib/core/routes/transactionRoutes');
app.use('/transaction', transactionRoutes);

const receiptRoutes = require('./lib/core/routes/receiptRoutes');
app.use('/receipt', receiptRoutes);

const recurringRoutes = require('./lib/core/routes/recurringRoutes');
app.use('/recurring', recurringRoutes);

app.listen(PORT, () => {
    console.log('Server running on port 3000');
});
