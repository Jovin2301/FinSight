const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const { getUserByEmail, authMiddleware, loginUser, updateUserDetail, updateUserPreferences, getUserPreferences } = require('../service/userService');
const userService = require('../service/userService');

//update user preferences
router.post('/updateUserPreferences', authMiddleware, async (req, res) => {
    try {
        // No db calls here — all handled in the service
        const result = await userService.updateUserPreferences(req.body, { userid: req.userId });
        res.status(201).json(result ?? {});
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// get userpreferences
router.get('/getUserPreferences', authMiddleware, async (req, res) => {
    try {
        const userPreference = await userService.getUserPreferences({ userid : req.userId });
        res.status(201).json(userPreference);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});




router.get('/:id', authMiddleware, async (req, res) => {
    console.log('ID received:', req.params.id);

    try {
        const user = await userService.getUserById(req.params.id);
        console.log('User found:', user);

        res.json(user);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

// User login logic - 'localhost/user/login'
/*router.post('/login', authMiddleware, async (req, res) => {
    try {
        const { email, password } = req.body;
        const user = await getUserByEmail(email);

        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const passwordMatches = await bcrypt.compare(password, user.userPassword); 

        if (!passwordMatches) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        res.json({
            userID: user.userID,
            userName: user.userName,
            userEmail: user.userEmail
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});*/

router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const result = await loginUser(email, password);
        res.status(200).json(result); // sends back { token, user }
    } catch (err) {
        res.status(401).json({ error: err.message });
    }
});

// creating / registering user
router.post('/register', authMiddleware, async (req, res) => {
    console.log('body', req.body);
    try {
        const user = await userService.registerUser(req.body);
        res.status(201).json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// editing the username and email for user 
router.post('/updateUserDetail', authMiddleware, async (req, res) => {
    try {
        const user = await userService.updateUserDetail(req.body);
        res.status(201).json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});



module.exports = router;