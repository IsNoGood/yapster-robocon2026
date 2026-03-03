import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

// In-memory message storage
interface Message {
  id: string;
  text: string;
  timestamp: string;
}

const messages: Message[] = [];

// Middleware
app.use(express.json());

// CORS for local development
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.type('text/plain').send('Hello from backend: ok');
});

// Get all messages (newest first)
app.get('/api/messages', (req, res) => {
  res.json([...messages].reverse());
});

// Post a new message
app.post('/api/messages', (req, res) => {
  const { text } = req.body;

  // Validate message text
  if (!text || typeof text !== 'string') {
    return res.status(400).json({ error: 'Message text is required' });
  }

  if (text.trim().length === 0) {
    return res.status(400).json({ error: 'Message text cannot be empty' });
  }

  if (text.length > 280) {
    return res.status(400).json({ error: 'Message text cannot exceed 280 characters' });
  }

  // Create new message
  const message: Message = {
    id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
    text: text.trim(),
    timestamp: new Date().toISOString()
  };

  messages.push(message);
  res.status(201).json(message);
});

app.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
});
