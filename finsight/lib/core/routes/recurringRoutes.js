const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../service/userService');
const recurringService = require('../service/recurringService');

router.get('/', authMiddleware, async (req, res) => {
    try {
        const recurringPayments = await recurringService.getRecurringPayments(req.userId);
        res.json(recurringPayments);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.post('/', authMiddleware, async (req, res) => {
    try {
        await recurringService.createRecurringPayment(req.userId, req.body);
        const recurringPayments = await recurringService.getRecurringPayments(req.userId);
        res.status(201).json(recurringPayments);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/:id', authMiddleware, async (req, res) => {
    try {
        await recurringService.updateRecurringPayment(req.userId, req.params.id, req.body);
        const recurringPayments = await recurringService.getRecurringPayments(req.userId);
        res.json(recurringPayments);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.delete('/:id', authMiddleware, async (req, res) => {
    try {
        await recurringService.deleteRecurringPayment(req.userId, req.params.id);
        const recurringPayments = await recurringService.getRecurringPayments(req.userId);
        res.json(recurringPayments);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
