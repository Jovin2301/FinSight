const express = require('express');
const multer = require('multer');
const { createWorker } = require('tesseract.js');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/scan', upload.single('receipt'), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ message: 'No receipt image uploaded' });
    }

    const worker = await createWorker('eng');

    try {
        const result = await worker.recognize(req.file.buffer);
        res.status(200).json({ text: result.data.text });
    } catch (error) {
        console.error('Receipt scan error:', error);
        res.status(500).json({ message: 'Could not scan receipt' });
    } finally {
        await worker.terminate();
    }
});

module.exports = router;
