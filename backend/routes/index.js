const express = require('express');
const router = express.Router();

// 导入各个路由模块
const authRoutes = require('./auth');
const recordRoutes = require('./records');
const chatRoutes = require('./chat');

// 注册路由
router.use('/auth', authRoutes);
router.use('/records', recordRoutes);
router.use('/chat', chatRoutes);

// 健康检查路由
router.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: '服务正常运行' });
});

module.exports = router;