require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 5000;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 静态文件目录 - 用于存储上传的文件
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 添加前端静态文件服务
// 优先使用build目录（生产环境）
app.use(express.static(path.join(__dirname, '../frontend/build')));
// 如果文件在build中不存在，则尝试public目录（开发环境）
app.use(express.static(path.join(__dirname, '../frontend/public')));

// 连接MongoDB
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/health-advisor')
  .then(() => console.log('MongoDB连接成功'))
  .catch(err => console.error('MongoDB连接失败:', err));

// 路由
app.use('/api', routes);

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: '服务器内部错误', error: err.message });
});


// 处理前端路由 - 将所有非API请求交给前端路由处理
app.get('*', (req, res) => {
  if (req.path.startsWith('/api')) {
    return res.status(404).json({ message: 'API路由不存在' });
  }
  
  // 优先尝试从build目录提供文件（生产环境）
  const buildPath = path.join(__dirname, '../frontend/build/index.html');
  const publicPath = path.join(__dirname, '../frontend/public/index.html');
  
  // 检查build目录是否存在，如果存在则使用build目录的index.html
  if (fs.existsSync(buildPath)) {
    res.sendFile(buildPath);
  } else {
    // 否则使用public目录的index.html（开发环境）
    res.sendFile(publicPath);
  }
});

// 启动服务器
app.listen(PORT, () => {
  console.log(`服务器运行在端口: ${PORT}`);
});