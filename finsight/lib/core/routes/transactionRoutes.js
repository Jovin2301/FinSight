const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../service/userService');
const transactionService = require('../service/transactionService');
const budgetService = require('../service/budgetService');

router.get('/', authMiddleware, async (req, res) => {
    try {
        const transactions = await transactionService.getTransactions(req.userId);
        res.json(transactions);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.post('/', authMiddleware, async (req, res) => {
    try {
        await transactionService.createTransaction(req.userId, req.body);
        await budgetService.getBudgets(req.userId);
        const transactions = await transactionService.getTransactions(req.userId);
        res.status(201).json(transactions);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.put('/:id', authMiddleware, async (req, res) => {
    try {
        await transactionService.updateTransaction(req.userId, req.params.id, req.body);
        await budgetService.getBudgets(req.userId);
        const transactions = await transactionService.getTransactions(req.userId);
        res.json(transactions);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

router.delete('/:id', authMiddleware, async (req, res) => {
    try {
        await transactionService.deleteTransaction(req.userId, req.params.id);
        const transactions = await transactionService.getTransactions(req.userId);
        res.json(transactions);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
