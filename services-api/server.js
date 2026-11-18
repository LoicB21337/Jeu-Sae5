'use strict';

const crypto = require('crypto');
const express = require('express');
const { Pool } = require('pg');

const {
  PORT = '4000',
  API_KEY = '',
  DB_HOST = '127.0.0.1',
  DB_PORT = '5432',
  DB_USER = 'jeu',
  DB_PASSWORD = '',
  DB_NAME = 'jeu',
} = process.env;

if (!API_KEY) {
  console.error('API_KEY manquante : refus de démarrer.');
  process.exit(1);
}

const pool = new Pool({
  host: DB_HOST,
  port: Number.parseInt(DB_PORT, 10),
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
});

const db = {
  ping: () => pool.query('SELECT 1'),
  insertSession: (s) =>
    pool.query(
      `INSERT INTO sessions (room_code, port, started_at, ended_at, duration_s, max_players)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [s.room_code, s.port, s.started_at, s.ended_at, s.duration_s, s.max_players]
    ),
  listSessions: (limit) =>
    pool.query('SELECT * FROM sessions ORDER BY ended_at DESC LIMIT $1', [limit]),
  stats: () =>
    pool.query(
      `SELECT COUNT(*)::int AS sessions,
              COALESCE(ROUND(AVG(duration_s)), 0)::int AS avg_duration_s
       FROM sessions`
    ),
};

const app = express();
app.use(express.json());

function safeEqual(a, b) {
  const ba = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  return ba.length === bb.length && crypto.timingSafeEqual(ba, bb);
}

function requireKey(req, res, next) {
  if (!safeEqual(req.get('x-api-key') || '', API_KEY)) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  next();
}

app.get('/health', async (_req, res) => {
  try {
    await db.ping();
    res.json({ ok: true });
  } catch (err) {
    res.status(503).json({ ok: false, error: err.message });
  }
});

app.post('/sessions', requireKey, async (req, res) => {
  const b = req.body || {};
  const valid =
    typeof b.room_code === 'string' && b.room_code.length > 0 && b.room_code.length <= 8 &&
    Number.isInteger(b.port) &&
    !Number.isNaN(Date.parse(b.started_at)) &&
    !Number.isNaN(Date.parse(b.ended_at)) &&
    Number.isInteger(b.duration_s) && b.duration_s >= 0 &&
    Number.isInteger(b.max_players);
  if (!valid) return res.status(400).json({ error: 'invalid_body' });

  try {
    const result = await db.insertSession(b);
    res.status(201).json({ id: result.rows[0].id });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error' });
  }
});

app.get('/sessions', requireKey, async (req, res) => {
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 200);
  try {
    res.json((await db.listSessions(limit)).rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error' });
  }
});

app.get('/stats', requireKey, async (_req, res) => {
  try {
    res.json((await db.stats()).rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'db_error' });
  }
});

app.listen(Number.parseInt(PORT, 10), () => console.log(`API services sur le port ${PORT}`));
