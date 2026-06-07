const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
  pingTimeout: 30000,
  pingInterval: 10000,
});

// كل غرفة بتتخزن لوحدها
const rooms = new Map();

function getRoom(roomId) {
  if (!rooms.has(roomId)) {
    rooms.set(roomId, {
      isPlaying: false,
      currentTime: 0,
      lastUpdate: Date.now(),
      users: new Map(),
      messages: [],       // last 100 chat messages
      source: null,       // { type: 'youtube'|'direct'|'remote', url, title }
    });
  }
  return rooms.get(roomId);
}

// بيحسب الوقت الحقيقي لو الفيديو شغال
function getCurrentTime(room) {
  if (room.isPlaying) {
    return room.currentTime + (Date.now() - room.lastUpdate) / 1000;
  }
  return room.currentTime;
}

function removeFromRoom(socket, roomId) {
  const room = rooms.get(roomId);
  if (!room) return;
  room.users.delete(socket.id);
  socket.leave(roomId);
  io.to(roomId).emit('user-left', {
    username: socket.username,
    totalUsers: room.users.size,
  });
  // امسح الغرفة لو فضت
  if (room.users.size === 0) rooms.delete(roomId);
}

// ── API endpoints ─────────────────────────────────────
app.get('/', (req, res) => {
  const totalUsers = [...rooms.values()].reduce((n, r) => n + r.users.size, 0);
  res.json({
    status: 'online',
    message: 'WatchParty Server is running!',
    activeRooms: rooms.size,
    totalUsers,
  });
});

app.get('/rooms', (req, res) => {
  const list = [...rooms.entries()].map(([id, room]) => ({
    id,
    users: [...room.users.values()].map((u) => u.name),
    isPlaying: room.isPlaying,
    currentTime: Math.floor(getCurrentTime(room)),
  }));
  res.json(list);
});

// ── Socket.io ─────────────────────────────────────────
io.on('connection', (socket) => {
  console.log(`Connected: ${socket.id}`);
  let currentRoomId = null;

  socket.on('join', (payload) => {
    const roomId =
      typeof payload?.roomId === 'string' && payload.roomId.trim()
        ? payload.roomId.trim().slice(0, 50)
        : 'default';
    const username =
      typeof payload?.username === 'string' && payload.username.trim()
        ? payload.username.trim().slice(0, 30)
        : typeof payload === 'string' && payload.trim()
        ? payload.trim().slice(0, 30)
        : 'Guest';

    // اطلع من الغرفة القديمة لو موجود
    if (currentRoomId) removeFromRoom(socket, currentRoomId);

    currentRoomId = roomId;
    socket.username = username;
    socket.join(roomId);

    const room = getRoom(roomId);
    room.users.set(socket.id, { id: socket.id, name: username });

    console.log(`${username} joined room "${roomId}"`);

    // ابعت الحالة الحقيقية للداخل الجديد (آخر 50 رسالة)
    socket.emit('sync-state', {
      isPlaying: room.isPlaying,
      currentTime: getCurrentTime(room),
      users: [...room.users.values()],
      messages: room.messages.slice(-50),
      source: room.source,
    });

    socket.to(roomId).emit('user-joined', {
      username,
      totalUsers: room.users.size,
    });
  });

  socket.on('play', (data) => {
    if (!currentRoomId) return;
    const time = parseFloat(data?.currentTime);
    if (isNaN(time) || time < 0) return;

    const room = getRoom(currentRoomId);
    room.isPlaying = true;
    room.currentTime = time;
    room.lastUpdate = Date.now();

    console.log(`PLAY  | ${socket.username} @ ${time.toFixed(1)}s | room: ${currentRoomId}`);
    socket.to(currentRoomId).emit('remote-play', { currentTime: time, triggeredBy: socket.username });
  });

  socket.on('pause', (data) => {
    if (!currentRoomId) return;
    const time = parseFloat(data?.currentTime);
    if (isNaN(time) || time < 0) return;

    const room = getRoom(currentRoomId);
    room.isPlaying = false;
    room.currentTime = time;
    room.lastUpdate = Date.now();

    console.log(`PAUSE | ${socket.username} @ ${time.toFixed(1)}s | room: ${currentRoomId}`);
    socket.to(currentRoomId).emit('remote-pause', { currentTime: time, triggeredBy: socket.username });
  });

  socket.on('seek', (data) => {
    if (!currentRoomId) return;
    const time = parseFloat(data?.currentTime);
    if (isNaN(time) || time < 0) return;

    const room = getRoom(currentRoomId);
    room.currentTime = time;
    room.lastUpdate = Date.now();

    console.log(`SEEK  | ${socket.username} -> ${time.toFixed(1)}s | room: ${currentRoomId}`);
    socket.to(currentRoomId).emit('remote-seek', { currentTime: time, triggeredBy: socket.username });
  });

  socket.on('request-sync', () => {
    if (!currentRoomId) return;
    const room = getRoom(currentRoomId);
    socket.emit('sync-state', {
      isPlaying: room.isPlaying,
      currentTime: getCurrentTime(room),
      users: [...room.users.values()],
      messages: room.messages.slice(-50),
      source: room.source,
    });
  });

  // ── Media source (what are we watching) ───────────────
  socket.on('set-source', (data) => {
    if (!currentRoomId) return;
    const type = ['youtube', 'direct', 'remote'].includes(data?.type) ? data.type : null;
    if (!type) return;
    const url = typeof data?.url === 'string' ? data.url.trim().slice(0, 1000) : '';
    const title = typeof data?.title === 'string' ? data.title.trim().slice(0, 200) : '';

    const room = getRoom(currentRoomId);
    room.source = { type, url, title };
    // reset playback for the new media
    room.isPlaying = false;
    room.currentTime = 0;
    room.lastUpdate = Date.now();

    console.log(`SOURCE| ${socket.username} -> ${type} ${title || url} | room: ${currentRoomId}`);
    io.to(currentRoomId).emit('source-changed', room.source);
  });

  // ── Chat ──────────────────────────────────────────────
  socket.on('chat-message', (data) => {
    if (!currentRoomId) return;
    const text = typeof data?.text === 'string' ? data.text.trim().slice(0, 500) : '';
    if (!text) return;

    const message = {
      id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
      username: socket.username,
      text,
      timestamp: Date.now(),
    };

    const room = getRoom(currentRoomId);
    room.messages.push(message);
    if (room.messages.length > 100) room.messages.shift();

    console.log(`CHAT  | ${socket.username}: ${text.slice(0, 50)}`);
    io.to(currentRoomId).emit('chat-message', message);
  });

  // الـ client بيبعت الوقت الحالي دوريًا - بنحدث لو الفيديو شغال
  socket.on('time-update', (data) => {
    if (!currentRoomId) return;
    const time = parseFloat(data?.currentTime);
    if (isNaN(time) || time < 0) return;
    const room = getRoom(currentRoomId);
    if (room.isPlaying) {
      room.currentTime = time;
      room.lastUpdate = Date.now();
    }
  });

  socket.on('disconnect', (reason) => {
    console.log(`Disconnected: ${socket.username || socket.id} (${reason})`);
    if (currentRoomId) removeFromRoom(socket, currentRoomId);
  });

  socket.on('error', (err) => {
    console.error(`Socket error [${socket.id}]:`, err.message);
  });
});

// ── Graceful shutdown ─────────────────────────────────
process.on('SIGTERM', () => {
  console.log('Shutting down gracefully...');
  io.close();
  server.close(() => process.exit(0));
});

process.on('SIGINT', () => {
  console.log('\nStopping server...');
  io.close();
  server.close(() => process.exit(0));
});

// ── Start ─────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log('═══════════════════════════════════════');
  console.log('   WatchParty Server Started!');
  console.log(`   Port: ${PORT}`);
  console.log('═══════════════════════════════════════');
});
