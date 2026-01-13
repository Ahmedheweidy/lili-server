/**
 * WatchParty Server
 * سيرفر المزامنة بين أحمد وليلى
 * يستخدم Socket.io للاتصال اللحظي
 */

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// تخزين حالة الغرفة
const roomState = {
  isPlaying: false,
  currentTime: 0,
  lastUpdate: Date.now(),
  connectedUsers: []
};

// API endpoint للتحقق من حالة السيرفر
app.get('/', (req, res) => {
  res.json({
    status: 'online',
    message: '🎬 WatchParty Server is running!',
    connectedUsers: roomState.connectedUsers.length,
    roomState: {
      isPlaying: roomState.isPlaying,
      currentTime: roomState.currentTime
    }
  });
});

// التعامل مع اتصالات Socket.io
io.on('connection', (socket) => {
  console.log(`✅ User connected: ${socket.id}`);
  
  // إضافة المستخدم للغرفة
  socket.on('join', (username) => {
    socket.username = username || 'Guest';
    roomState.connectedUsers.push({
      id: socket.id,
      name: socket.username
    });
    
    console.log(`👤 ${socket.username} joined the party!`);
    
    // إرسال الحالة الحالية للمستخدم الجديد
    socket.emit('sync-state', roomState);
    
    // إعلام الجميع بانضمام مستخدم جديد
    io.emit('user-joined', {
      username: socket.username,
      totalUsers: roomState.connectedUsers.length
    });
  });

  // استقبال أمر التشغيل
  socket.on('play', (data) => {
    console.log(`▶️ ${socket.username} pressed PLAY at ${data.currentTime}s`);
    roomState.isPlaying = true;
    roomState.currentTime = data.currentTime;
    roomState.lastUpdate = Date.now();
    
    // إرسال لكل المستخدمين ما عدا المرسل
    socket.broadcast.emit('remote-play', {
      currentTime: data.currentTime,
      triggeredBy: socket.username
    });
  });

  // استقبال أمر الإيقاف
  socket.on('pause', (data) => {
    console.log(`⏸️ ${socket.username} pressed PAUSE at ${data.currentTime}s`);
    roomState.isPlaying = false;
    roomState.currentTime = data.currentTime;
    roomState.lastUpdate = Date.now();
    
    socket.broadcast.emit('remote-pause', {
      currentTime: data.currentTime,
      triggeredBy: socket.username
    });
  });

  // استقبال أمر التقديم/الترجيع
  socket.on('seek', (data) => {
    console.log(`⏩ ${socket.username} seeked to ${data.currentTime}s`);
    roomState.currentTime = data.currentTime;
    roomState.lastUpdate = Date.now();
    
    socket.broadcast.emit('remote-seek', {
      currentTime: data.currentTime,
      triggeredBy: socket.username
    });
  });

  // طلب مزامنة الوقت
  socket.on('request-sync', () => {
    socket.emit('sync-state', roomState);
  });

  // تحديث الوقت الحالي (كل 5 ثواني)
  socket.on('time-update', (data) => {
    roomState.currentTime = data.currentTime;
    roomState.isPlaying = data.isPlaying;
  });

  // عند قطع الاتصال
  socket.on('disconnect', () => {
    console.log(`❌ ${socket.username || 'User'} disconnected`);
    roomState.connectedUsers = roomState.connectedUsers.filter(
      user => user.id !== socket.id
    );
    
    io.emit('user-left', {
      username: socket.username,
      totalUsers: roomState.connectedUsers.length
    });
  });
});

// تشغيل السيرفر
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log('═══════════════════════════════════════');
  console.log('   🎬 WatchParty Server Started!');
  console.log('═══════════════════════════════════════');
  console.log(`   📡 Port: ${PORT}`);
  console.log('═══════════════════════════════════════');
});
