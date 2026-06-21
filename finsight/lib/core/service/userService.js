const db = require('../database');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
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
        `SELECT * FROM public."User" WHERE "userEmail" = $1`,
        [email]
    );
    return result.rows[0];
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
    registerUser,
    getUserById,
    getUserByEmail
};