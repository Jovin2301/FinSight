const db = require('../database');

async function createUser(user) {
    const hashedPassword = await bcrypt.hash(user.userPassword, 12);

    const result = await db.query(
        `INSERT INTO public."User"
        ("userName", "userPassword", "userEmail", "userMonthlyIncome")
        VALUES ($1, $2, $3, $4)
        RETURNING *`,
        [
            user.userName,
            hashedPassword,
            user.userEmail,
            user.userMonthlyIncome
        ]
    );

    return result.rows[0];
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
        `SELECT * FROM public."User" WHERE "userEmail" = $1`,
        [email]
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
    createUser,
    getUserById,
    getUserByEmail
};