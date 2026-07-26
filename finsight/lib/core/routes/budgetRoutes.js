const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../service/userService');
const budgetService = require('../service/budgetService');

// get all budget categories for the form
router.get('/categories', authMiddleware, async (req, res) => {
    try {
        const categories = await budgetService.getCategories();
        res.json(categories);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// get budgets for logged in user
router.get('/', authMiddleware, async (req, res) => {
    try {
        const budgets = await budgetService.getBudgets(req.userId);
        res.json(budgets);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// create budget
router.post('/', authMiddleware, async (req, res) => {
    try {
        await budgetService.createBudget(req.userId, req.body);
        const budgets = await budgetService.getBudgets(req.userId);
        res.status(201).json(budgets);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// update budget
router.put('/:id', authMiddleware, async (req, res) => {
    try {
        await budgetService.updateBudget(req.userId, req.params.id, req.body);
        const budgets = await budgetService.getBudgets(req.userId);
        res.json(budgets);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// delete budget
router.delete('/:id', authMiddleware, async (req, res) => {
    try {
        await budgetService.deleteBudget(req.userId, req.params.id);
        const budgets = await budgetService.getBudgets(req.userId);
        res.json(budgets);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;
