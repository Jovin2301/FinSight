const db = require('../database');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const jwt = require('jsonwebtoken');

//update user preferences
async function updateUserPreferences(preferences, user) {
  // Check if row exists, insert default if not
  const exists = await db.query(
    `SELECT 1 FROM public."userPreference" WHERE "userID" = $1`,
    [user.userid]
  );

  if (exists.rows.length === 0) {
    await db.query(
      `INSERT INTO public."userPreference" 
      ("prefID", "userID", "prefCurrency", "prefTheme", "prefNotification", "prefBudgetCycle", "prefIncomeType", "prefBudgetCycleDate")
      VALUES ($1, $2, 'SGD', 'Light', true, 'Monthly', 'Salaried', 1)`,
      [
        uuidv4(),
        user.userid
      ]
    );
  }

  // rest of your existing update logic...
  const fields = [];
  const values = [];
  let idx = 1;

  if (preferences.prefBudgetCycle !== undefined) {
    fields.push(`"prefBudgetCycle" = $${idx++}`);
    values.push(preferences.prefBudgetCycle);
  }
  if (preferences.currency !== undefined) {
    fields.push(`"prefCurrency" = $${idx++}`);
    values.push(preferences.currency);
  }
  if (preferences.prefTheme !== undefined) {
    fields.push(`"prefTheme" = $${idx++}`);
    values.push(preferences.prefTheme);
  }
  if (preferences.notification !== undefined) {
    fields.push(`"prefNotification" = $${idx++}`);
    values.push(preferences.notification === 'Enabled');
  }
  if (preferences.incomeType !== undefined) {
    fields.push(`"prefIncomeType" = $${idx++}`);
    values.push(preferences.incomeType);
  }
  if (preferences.budgetCycleDate !== undefined) {
    fields.push(`"prefBudgetCycleDate" = $${idx++}`);
    values.push(preferences.budgetCycleDate);
  }

  if (fields.length === 0) return null;

  values.push(user.userid);

  const result = await db.query(
    `UPDATE public."userPreference"
     SET ${fields.join(', ')}
     WHERE "userID" = $${idx}
     RETURNING *`,
    values
  );

  return result.rows[0];
}

async function getUserPreferences(user) {
    const result = await db.query(
        `SELECT * FROM public."userPreference" 
        WHERE "userID" = $1`,
        [user.userid]
    );
    return result.rows[0];
}

//get user saving goals
async function getSavingGoal(user) {
    const result = await db.query(
        `SELECT * FROM public."savingGoals" 
        WHERE "userID" = $1`,
        [user.userid]
    );
    return result.rows;
}

//update user saving goals
async function updateSavingGoal(user, goalId, savingGoal) {
    const result = await db.query(
        `UPDATE public."savingGoals"
         SET "goalName" = $3, "goalDueDate" = $4, "goalTargetAmt" = $5,
             "goalCurrentAmt" = $6, "goalStatus" = $7, "goalIcon" = $8
         WHERE "userID" = $1 AND "goalID" = $2
         RETURNING *;`,
        [user.userid, goalId, savingGoal.goalName, savingGoal.goalDueDate,
         savingGoal.goalTargetAmt, savingGoal.goalCurrentAmt, savingGoal.goalStatus, savingGoal.iconEmoji]
    );
    return result.rows[0];
}

//update user saving goals
async function createSavingGoal(user, savingGoal) {
    const result = await db.query(
        `INSERT INTO public."savingGoals" 
        ("goalID", "userID", "goalName", "goalDueDate", "goalTargetAmt", "goalCurrentAmt", "goalStatus", "goalIcon")
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
        RETURNING *`,
        [
            uuidv4(),
            user.userid,
            savingGoal.goalName,
            savingGoal.goalDueDate,
            savingGoal.goalTargetAmt,
            savingGoal.goalCurrentAmt,
            savingGoal.goalStatus,
            savingGoal.iconEmoji
        ]
    );
    return result.rows[0];
}

async function deleteSavingGoal(user, savingGoalId) {
    const result = await db.query(
        `
        DELETE FROM public."savingGoals"
        WHERE "goalID" = $1
        RETURNING *;
        `,
        [
            savingGoalId
        ]
    );

    return result.rows[0];
}


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

// UPDATE user detail
async function updateUserDetail(user) {
    const result = await db.query(
        `UPDATE public."User"
        SET "userName" = $1,
            "userEmail" = $2
        WHERE "userID" = $3
        RETURNING *`,
        [
            user.username,
            user.email,
            user.userid
        ]
    );
    return result.rows[0];
}

async function changeUserPassword(user) {
    const existing = await db.query(
        `SELECT "userPassword" FROM public."User" WHERE "userID" = $1`,
        [user.userid]
    );

    if (existing.rows.length === 0) {
        throw new Error('User not found');
    }

    const isMatch = await bcrypt.compare(
        user.currentPassword,
        existing.rows[0].userPassword
    );

    if (!isMatch) {
        throw new Error('Current password is incorrect');
    }

    const hashedPassword = await bcrypt.hash(user.password, 12);

    const result = await db.query(
        `UPDATE public."User"
        SET "userPassword" = $1
        WHERE "userID" = $2
        RETURNING *`,
        [hashedPassword, user.userid]
    );

    return result.rows[0];
}



module.exports = {
    authMiddleware,
    registerUser,
    getUserById,
    loginUser,
    getUserByEmail,
    updateUserDetail,
    updateUserPreferences,
    getUserPreferences,
    getSavingGoal,
    updateSavingGoal,
    deleteSavingGoal,
    createSavingGoal,
    changeUserPassword
};