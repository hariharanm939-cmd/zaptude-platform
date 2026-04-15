const express = require('express');
const cors = require('cors');
require('dotenv').config();

const db = require('./config/db');
const authRoutes = require('./routes/auth');
const studentRoutes = require('./routes/students');
const batchRoutes = require('./routes/batches');
const questionRoutes = require('./routes/questions');
const testRoutes = require('./routes/tests');
const studentPortalRoutes = require('./routes/studentPortal');
const analyticsRoutes = require('./routes/analytics');
const mockTestRoutes = require('./routes/mockTest');
const mistakeBankRoutes = require('./routes/mistakeBank');
const retestRoutes = require('./routes/retest');

const app = express();

// ✅ These MUST come before all routes
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/mistakes', mistakeBankRoutes);
app.use('/api/retest', retestRoutes);

app.get('/', (req, res) => {
  res.json({ message: 'Placement System API is running' });
});

app.use('/api/auth', authRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/batches', batchRoutes);
app.use('/api/questions', questionRoutes);
app.use('/api/tests', testRoutes);
app.use('/api/portal', studentPortalRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/mock', mockTestRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});