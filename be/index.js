const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const prisma = new PrismaClient();
const app = express();

app.use(cors());
app.use(express.json());

const SECRET = 'YOUR_SUPER_SECRET_KEY';

// Middleware to protect routes
const auth = (req, res, next) => {
  const token = req.header('Authorization');
  if (!token) return res.status(401).json({ error: 'No token, authorization denied' });
  try {
    const dec = jwt.verify(token.replace('Bearer ', ''), SECRET);
    req.userId = dec.userId;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Token is not valid' });
  }
};

// --- AUTH ---
app.post('/register', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) return res.status(400).json({ error: 'User already exists' });
    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { email, password: hashed, name: name || '' }
    });
    const token = jwt.sign({ userId: user.id }, SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, email: user.email, name: user.name } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(400).json({ error: 'Invalid credentials' });
    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(400).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ userId: user.id }, SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, email: user.email, name: user.name } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/me', auth, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    res.json({ id: user.id, email: user.email, name: user.name });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- TRANSACTIONS ---
app.get('/transactions', auth, async (req, res) => {
  try {
    const transactions = await prisma.transaction.findMany({
      where: { userId: req.userId },
      orderBy: { date: 'desc' },
    });
    res.json(transactions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/transactions', auth, async (req, res) => {
  try {
    const { type, date, amount, category, account, note } = req.body;
    const transaction = await prisma.transaction.create({
      data: {
        type,
        date: new Date(date),
        amount: parseFloat(amount) || 0,
        category: category || '',
        account: account || '',
        note: note || '',
        userId: req.userId,
      },
    });
    res.json(transaction);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/transactions/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { type, date, amount, category, account, note } = req.body;
    const transaction = await prisma.transaction.updateMany({
      where: { id: parseInt(id), userId: req.userId },
      data: {
        type,
        date: new Date(date),
        amount: parseFloat(amount) || 0,
        category: category || '',
        account: account || '',
        note: note || '',
      },
    });
    res.json(transaction);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/transactions/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.transaction.deleteMany({
      where: { id: parseInt(id), userId: req.userId },
    });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// --- CATEGORIES ---
app.get('/categories', auth, async (req, res) => {
  try {
    const categories = await prisma.category.findMany({
      where: { userId: req.userId }
    });
    res.json(categories);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/categories', auth, async (req, res) => {
  try {
    const { name } = req.body;
    const category = await prisma.category.create({
      data: { name, userId: req.userId },
    });
    res.json(category);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/categories/:id', auth, async (req, res) => {
  try {
    await prisma.category.deleteMany({
      where: { id: parseInt(req.params.id), userId: req.userId }
    });
    res.json({ success: true });
  } catch (error) { res.status(500).json({ error: error.message }); }
});

// --- ACCOUNTS ---
app.get('/accounts', auth, async (req, res) => {
  try {
    const accounts = await prisma.account.findMany({
      where: { userId: req.userId }
    });
    res.json(accounts);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/accounts', auth, async (req, res) => {
  try {
    const { type, amount } = req.body;
    const account = await prisma.account.create({
      data: {
        type,
        amount: parseFloat(amount) || 0,
        userId: req.userId,
      },
    });
    res.json(account);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.put('/accounts/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { type, amount } = req.body;
    const account = await prisma.account.updateMany({
      where: { id: parseInt(id), userId: req.userId },
      data: {
        type,
        amount: parseFloat(amount) || 0,
      },
    });
    res.json(account);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/accounts/:id', auth, async (req, res) => {
  try {
    await prisma.account.deleteMany({
      where: { id: parseInt(req.params.id), userId: req.userId }
    });
    res.json({ success: true });
  } catch (error) { res.status(500).json({ error: error.message }); }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
