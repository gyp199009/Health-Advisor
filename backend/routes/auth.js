const express = require('express');
const router = express.Router();
const User = require('../models/User');
const bcrypt = require('bcryptjs');

// 用户注册
router.post('/register', async (req, res) => {
  try {
    const { username, password, email, phone } = req.body;
    
    // 检查用户是否已存在
    const existingUser = await User.findOne({ $or: [{ username }, { email }] });
    if (existingUser) {
      return res.status(409).json({ message: '用户名或邮箱已被注册' });
    }
    
    // 对密码进行加密
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    
    // 创建新用户
    const newUser = new User({
      username,
      password: hashedPassword,
      email,
      phone
    });
    
    await newUser.save();
    
    res.status(201).json({ message: '注册成功', userId: newUser._id });
  } catch (error) {
    console.error('注册错误:', error);
    res.status(500).json({ message: '注册失败', error: error.message });
  }
});

// 用户登录
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // 查找用户
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ message: '用户名或密码不正确' });
    }
    
    // 验证密码
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ message: '用户名或密码不正确' });
    }
    
    // 登录成功
    res.status(200).json({
      message: '登录成功',
      user: {
        id: user._id,
        username: user.username,
        email: user.email
      }
    });
  } catch (error) {
    console.error('登录错误:', error);
    res.status(500).json({ message: '登录失败', error: error.message });
  }
});

// 获取用户信息
router.get('/profile/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const user = await User.findById(userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: '用户不存在' });
    }
    
    res.status(200).json({ user });
  } catch (error) {
    console.error('获取用户信息错误:', error);
    res.status(500).json({ message: '获取用户信息失败', error: error.message });
  }
});

module.exports = router;