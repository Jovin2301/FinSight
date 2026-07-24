const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const { getUserByEmail, authMiddleware, loginUser, updateUserDetail, updateUserPreferences, getUserPreferences, getSavingGoal, updateSavingGoal, deleteSavingGoal, createSavingGoal } = require('../service/userService');
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

router.get('/getSavingGoal', authMiddleware, async (req, res) => {
    try {
        const savingGoals = await userService.getSavingGoal({ userid : req.userId });
        res.status(201).json(savingGoals);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/updateSavingGoal/:id', authMiddleware, async (req, res) => {
    try {
        console.log('userId:', req.userId, 'goalId param:', req.params.id, 'body:', req.body);
        const updatedGoal = await userService.updateSavingGoal(
            { userid: req.userId },
            req.params.id,
            req.body
        );
        console.log('updatedGoal:', updatedGoal);
        res.status(200).json(updatedGoal);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/createSavingGoal', authMiddleware, async (req, res) => {
    try {
        const savingGoals = await userService.createSavingGoal(
            { userid : req.userId }, 
            req.body
        );
        res.status(201).json(savingGoals);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


router.delete("/deleteSavingGoals/:goalId", authMiddleware, async (req, res) => {
    try {
        const deleted = await userService.deleteSavingGoal(
            { userid: req.userId },
            req.params.goalId
        );

        res.json(deleted);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// User login logic - 'localhost/user/login'
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
router.post('/register', async (req, res) => {
    console.log('!!!! REGISTER HANDLER HIT !!!!');
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

router.post('/changeUserPassword', authMiddleware, async (req, res) => {
    try {
        const user = await userService.changeUserPassword(req.body);
        res.status(201).json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});



module.exports = router;