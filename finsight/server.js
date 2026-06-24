const express = require('express');
const jwt = require('jsonwebtoken');
const app = express();

app.use(express.json());

const userRoutes = require('./lib/core/routes/userRoutes');
app.use('/user', userRoutes);

app.listen(3000, () => {
    console.log('Server running on port 3000');
});