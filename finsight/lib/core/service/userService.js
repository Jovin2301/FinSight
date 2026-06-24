const db = require('../database');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.userId = decoded.userId; // attach it to the request for downstream handlers
        next();
    } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired token' });
    }
}

// GET USER
async function getUserById(id) {
    const result = await db.query(
        `SELECT * FROM public."User"
        WHERE "userID" = $1`,
        [id]
    );

    return result.rows[0];
}

// get user by email for login purpose
async function getUserByEmail(email) {
    const result = await db.query(
        `SELECT * FROM public."User" WHERE LOWER("userEmail") = LOWER($1)`,
        [email]
    );
    return result.rows[0];
}

async function loginUser(email, password) {
    const result = await db.query(
        `SELECT * FROM public."User" WHERE LOWER("userEmail") = LOWER($1)`,
        [email]
    );
    const user = result.rows[0];
    if (!user) throw new Error('Invalid credentials');

    const match = await bcrypt.compare(password, user.userPassword);
    if (!match) throw new Error('Invalid credentials');

    const token = jwt.sign(
        { userId: user.userID }, 
        process.env.JWT_SECRET,  // a long random string, kept in .env, never hardcoded
        { expiresIn: '7d' }
    );

    return { token, user: { id: user.userID, username: user.userName, email: user.userEmail } };
}

async function registerUser(user) {
    const hashedPassword = await bcrypt.hash(user.password, 12);
    const dateJoined = new Date().toISOString().split('T')[0]; //date
    const lastlogin = new Date().toISOString(); //timestamp

    const result = await db.query(
        `INSERT INTO public."User"
        ("userID", "userName", "userPassword", "userEmail", "userDateJoined", "userMonthlyIncome", "lastLogin")
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *`,
        [
            uuidv4(),
            user.username,
            hashedPassword,
            user.email,
            dateJoined,
            0, //defaulted value for the user -> for further application customisation
            lastlogin
        ]
    );

    return result.rows[0];
}


// // UPDATE LAST LOGIN (simulate login)
// router.put('/login/:id', async (req, res) => {
//     try {
//         const user = await userService.updateLastLogin(req.params.userID);
//         res.json(user);
//     } catch (err) {
//         res.status(500).json({ error: err.message });
//     }
// });

module.exports = {
    authMiddleware,
    registerUser,
    getUserById,
    loginUser,
    getUserByEmail
};