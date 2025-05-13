require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const https = require('https');
const routes = require('./routes');

// 创建证书目录（如果不存在）
const certDir = path.join(__dirname, 'certificates');
if (!fs.existsSync(certDir)) {
  fs.mkdirSync(certDir, { recursive: true });
}

// 自签名证书配置
const certOptions = {
  key: fs.existsSync(path.join(certDir, 'key.pem')) 
    ? fs.readFileSync(path.join(certDir, 'key.pem')) 
    : null,
  cert: fs.existsSync(path.join(certDir, 'cert.pem')) 
    ? fs.readFileSync(path.join(certDir, 'cert.pem')) 
    : null
};

const app = express();
const HTTP_PORT = process.env.HTTP_PORT || 5000;
const HTTPS_PORT = process.env.HTTPS_PORT || 5443;

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

// 启动HTTP服务器
app.listen(HTTP_PORT, () => {
  console.log(`HTTP服务器运行在端口: ${HTTP_PORT}`);
});

// 检查是否有证书文件
if (certOptions.key && certOptions.cert) {
  // 启动HTTPS服务器
  const httpsServer = https.createServer(certOptions, app);
  httpsServer.listen(HTTPS_PORT, () => {
    console.log(`HTTPS服务器运行在端口: ${HTTPS_PORT}`);
  });
} else {
  console.log('未找到SSL证书文件，HTTPS服务器未启动。请生成证书后重启服务器。');
  console.log('可以使用以下命令生成自签名证书：');
  console.log('openssl req -x509 -newkey rsa:4096 -keyout ./certificates/key.pem -out ./certificates/cert.pem -days 365 -nodes');
}