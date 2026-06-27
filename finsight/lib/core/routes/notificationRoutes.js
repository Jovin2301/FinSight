const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../service/userService');
const notificationService = require('../service/notificationService');

router.get('/', authMiddleware, async (req, res) => {
    try {
        const notifications = await notificationService.getNotifications(req.userId);
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/read-all', authMiddleware, async (req, res) => {
    try {
        await notificationService.markAllAsRead(req.userId);
        const notifications = await notificationService.getNotifications(req.userId);
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/:id/read', authMiddleware, async (req, res) => {
    try {
        await notificationService.markAsRead(req.userId, req.params.id);
        const notifications = await notificationService.getNotifications(req.userId);
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
