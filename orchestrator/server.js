'use strict';

const express = require('express');
const readline = require('readline');
const { spawn } = require('child_process');

const {
  PORT = '3000',
  PUBLIC_HOST = '127.0.0.1',
  GODOT_BIN = 'godot',
  GODOT_PROJECT = '/home/ubuntu/jeu-project',
  PORT_MIN = '7778',
  PORT_MAX = '7799',
  SERVICES_URL = '',
  API_KEY = '',
  READY_TIMEOUT_MS = '10000',
  EMPTY_GRACE_MS = '30000',     
  IDLE_TIMEOUT_MS = '300000',  
  MAX_LIFETIME_MS = '7200000', 
} = process.env;

const MAX_PLAYERS = 2;
const num = (v) => Number.parseInt(v, 10);

/** code -> { code, port, proc, players, maxPlayers, everJoined, createdAt, startedAt, ready, closed, timers } */
const rooms = new Map();

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
function newCode() {
  for (let attempt = 0; attempt < 100; attempt++) {
    let code = '';
    for (let i = 0; i < 4; i++) code += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
    if (!rooms.has(code)) return code;
  }
  throw new Error('no_code');
}

function freePort() {
  const used = new Set([...rooms.values()].map((r) => r.port));
  for (let p = num(PORT_MIN); p <= num(PORT_MAX); p++) if (!used.has(p)) return p;
  return null;
}

function log(room, msg) {
  console.log(`[${room ? room.code : 'orch'}] ${msg}`);
}

function createRoom() {
  const port = freePort();
  if (port === null) return null;

  const room = {
    code: newCode(),
    port,
    proc: null,
    players: 0,
    maxPlayers: MAX_PLAYERS,
    everJoined: false,
    createdAt: new Date(),
    startedAt: null,
    ready: false,
    closed: false,
    timers: {},
    readyWaiters: [],
  };

  const proc = spawn(
    GODOT_BIN,
    ['--headless', '--path', GODOT_PROJECT, '-s', 'res://Scripts/server.gd', '--', `--port=${port}`],
    { stdio: ['ignore', 'pipe', 'pipe'] }
  );
  room.proc = proc;
  rooms.set(room.code, room);
  log(room, `salle créée, Godot pid=${proc.pid} port UDP ${port}`);

  readline.createInterface({ input: proc.stdout }).on('line', (line) => onGodotLine(room, line));
  readline.createInterface({ input: proc.stderr }).on('line', (line) => log(room, `stderr: ${line}`));
  proc.on('error', (err) => {
    log(room, `impossible de lancer Godot : ${err.message}`);
    closeRoom(room, 'spawn_error');
  });
  proc.on('exit', (code, signal) => {
    log(room, `Godot terminé (code=${code}, signal=${signal})`);
    closeRoom(room, 'process_exit');
  });

  room.timers.idle = setTimeout(() => {
    if (!room.everJoined) closeRoom(room, 'idle_timeout');
  }, num(IDLE_TIMEOUT_MS));
  room.timers.lifetime = setTimeout(() => closeRoom(room, 'max_lifetime'), num(MAX_LIFETIME_MS));

  return room;
}

function onGodotLine(room, line) {
  if (/Serveur démarré sur le port/.test(line)) {
    room.ready = true;
    room.readyWaiters.splice(0).forEach((resolve) => resolve(true));
  }
  let m = line.match(/Joueur connecté : \d+ \((\d+)\/(\d+)\)/);
  if (m) {
    room.players = num(m[1]);
    if (!room.everJoined) {
      room.everJoined = true;
      room.startedAt = new Date();
    }
    clearTimeout(room.timers.empty);
    log(room, `joueur connecté (${room.players}/${room.maxPlayers})`);
    return;
  }
  m = line.match(/Joueur déconnecté : \d+ \((\d+)\/(\d+)\)/);
  if (m) {
    room.players = num(m[1]);
    log(room, `joueur déconnecté (${room.players}/${room.maxPlayers})`);
    if (room.players === 0) {
      room.timers.empty = setTimeout(() => closeRoom(room, 'empty'), num(EMPTY_GRACE_MS));
    }
  }
}

function waitReady(room) {
  if (room.ready) return Promise.resolve(true);
  return new Promise((resolve) => {
    room.readyWaiters.push(resolve);
    setTimeout(() => resolve(false), num(READY_TIMEOUT_MS));
  });
}

async function closeRoom(room, reason) {
  if (room.closed) return;
  room.closed = true;
  Object.values(room.timers).forEach(clearTimeout);
  rooms.delete(room.code);
  if (room.proc && room.proc.exitCode === null) room.proc.kill('SIGTERM');
  log(room, `salle fermée (${reason})`);

  if (room.everJoined) await reportSession(room);
}

async function reportSession(room) {
  if (!SERVICES_URL) return;
  const endedAt = new Date();
  const body = {
    room_code: room.code,
    port: room.port,
    started_at: room.startedAt.toISOString(),
    ended_at: endedAt.toISOString(),
    duration_s: Math.round((endedAt - room.startedAt) / 1000),
    max_players: room.maxPlayers,
  };
  try {
    const res = await fetch(`${SERVICES_URL}/sessions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-api-key': API_KEY },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(5000),
    });
    log(room, `session envoyée à l'API services (HTTP ${res.status})`);
  } catch (err) {
    log(room, `échec d'envoi de la session : ${err.message}`);
  }
}

const app = express();
app.use(express.json());

const roomInfo = (r) => ({ code: r.code, host: PUBLIC_HOST, port: r.port });

app.get('/health', (_req, res) => res.json({ ok: true, rooms: rooms.size }));

app.get('/rooms', (_req, res) =>
  res.json([...rooms.values()].map((r) => ({ code: r.code, players: r.players, max_players: r.maxPlayers })))
);

app.post('/rooms', async (_req, res) => {
  let room;
  try {
    room = createRoom();
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
  if (!room) return res.status(503).json({ error: 'no_free_port' });

  const ok = await waitReady(room);
  if (room.closed) return res.status(500).json({ error: 'server_failed_to_start' });
  if (!ok) log(room, 'pas de signal "prêt" dans le délai, on renvoie quand même la salle');
  res.status(200).json(roomInfo(room));
});

app.post('/rooms/:code/join', (req, res) => {
  const room = rooms.get(String(req.params.code).toUpperCase());
  if (!room || room.closed) return res.status(404).json({ error: 'room_not_found' });
  if (room.players >= room.maxPlayers) return res.status(409).json({ error: 'room_full' });
  res.json(roomInfo(room));
});

const server = app.listen(num(PORT), () =>
  console.log(`Orchestrateur sur le port ${PORT} (hôte public ${PUBLIC_HOST}, UDP ${PORT_MIN}-${PORT_MAX})`)
);

function shutdown() {
  console.log('Arrêt : fermeture des salles…');
  for (const room of [...rooms.values()]) {
    room.closed = true;
    Object.values(room.timers).forEach(clearTimeout);
    if (room.proc && room.proc.exitCode === null) room.proc.kill('SIGTERM');
  }
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 2000).unref();
}
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
