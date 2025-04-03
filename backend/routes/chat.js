const express = require('express');
const router = express.Router();
const Conversation = require('../models/Conversation');
const Message = require('../models/Message');
const Record = require('../models/Record');
const aiService = require('../services/aiService');

// 创建新对话
router.post('/conversations', async (req, res) => {
  try {
    const { userId, title } = req.body;
    
    if (!userId) {
      return res.status(400).json({ message: '缺少用户ID' });
    }
    
    const newConversation = new Conversation({
      userId,
      title: title || `对话 ${new Date().toLocaleString()}`,
      createdAt: new Date(),
      lastUpdated: new Date()
    });
    
    await newConversation.save();
    
    res.status(201).json({
      message: '对话创建成功',
      conversation: {
        id: newConversation._id,
        title: newConversation.title,
        createdAt: newConversation.createdAt
      }
    });
  } catch (error) {
    console.error('创建对话错误:', error);
    res.status(500).json({ message: '创建对话失败', error: error.message });
  }
});

// 获取用户的所有对话
router.get('/conversations/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const conversations = await Conversation.find({ userId })
      .sort({ lastUpdated: -1 });
    
    res.status(200).json({ conversations });
  } catch (error) {
    console.error('获取对话列表错误:', error);
    res.status(500).json({ message: '获取对话列表失败', error: error.message });
  }
});

// 获取单个对话的所有消息
router.get('/conversations/:conversationId/messages', async (req, res) => {
  try {
    const { conversationId } = req.params;
    
    const messages = await Message.find({ conversationId })
      .sort({ timestamp: 1 });
    
    res.status(200).json({ messages });
  } catch (error) {
    console.error('获取对话消息错误:', error);
    res.status(500).json({ message: '获取对话消息失败', error: error.message });
  }
});

// 获取可用的AI模型列表
router.get('/models', (req, res) => {
  try {
    const models = aiService.getAvailableModels();
    res.status(200).json({ models });
  } catch (error) {
    console.error('获取AI模型列表错误:', error);
    res.status(500).json({ message: '获取AI模型列表失败', error: error.message });
  }
});

// 发送消息并获取AI回复
router.post('/conversations/:conversationId/messages', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { userId, content, modelType = 'volcengine' } = req.body;
    
    if (!content) {
      return res.status(400).json({ message: '消息内容不能为空' });
    }
    
    // 保存用户消息
    const userMessage = new Message({
      conversationId,
      userId,
      content,
      role: 'user',
      timestamp: new Date()
    });
    
    await userMessage.save();
    
    // 更新对话的最后更新时间
    await Conversation.findByIdAndUpdate(conversationId, {
      lastUpdated: new Date()
    });
    
    // 获取对话历史
    const conversationHistory = await Message.find({ conversationId })
      .sort({ timestamp: 1 })
      .select('content role');

    // 获取用户的所有病历记录
    const userRecords = await Record.find({ userId }).select('textContent recordType description uploadDate');
    
    // 构建发送给AI的上下文
    let context = "";
    if (userRecords.length > 0) {
      context += "以下是用户的病历资料:\n";
      userRecords.forEach((record, index) => {
        context += `病历 ${index + 1} (${record.recordType}) - ${record.uploadDate.toLocaleDateString()}:\n`;
        if (record.description) context += `描述: ${record.description}\n`;
        context += `${record.textContent}\n\n`;
      });
    }
    
    // 构建消息历史
    const messages = [
      { role: "system", content: `你是一个专业的健康顾问AI助手。请基于用户提供的病历资料，给出专业、准确的健康建议。\n${context}` },
      ...conversationHistory.map(msg => ({
        role: msg.role,
        content: msg.content
      }))
    ];

    try {
      // 调用选定的AI模型生成回复
      const aiResponse = await aiService.generateResponse(modelType, messages);

      // 保存AI回复消息
      const aiMessage = new Message({
        conversationId,
        content: aiResponse,
        role: 'assistant',
        timestamp: new Date()
      });

      await aiMessage.save();

      res.status(200).json({
        userMessage: {
          id: userMessage._id,
          content: userMessage.content,
          timestamp: userMessage.timestamp
        },
        aiMessage: {
          id: aiMessage._id,
          content: aiMessage.content,
          timestamp: aiMessage.timestamp
        }
      });
    } catch (error) {
      console.error('AI服务错误:', error);
      
      // 保存错误消息
      const errorMessage = new Message({
        conversationId,
        content: `AI服务暂时不可用: ${error.message}`,
        role: 'assistant',
        error: true,
        timestamp: new Date()
      });

      await errorMessage.save();

      res.status(200).json({
        userMessage: {
          id: userMessage._id,
          content: userMessage.content,
          timestamp: userMessage.timestamp
        },
        aiMessage: {
          id: errorMessage._id,
          content: errorMessage.content,
          timestamp: errorMessage.timestamp,
          error: true
        }
      });
    }
  } catch (error) {
    console.error('发送消息错误:', error);
    res.status(500).json({ message: '发送消息失败', error: error.message });
  }
});

// 删除对话
router.delete('/conversations/:conversationId', async (req, res) => {
  try {
    const { conversationId } = req.params;
    
    // 删除对话及其所有消息
    await Conversation.findByIdAndDelete(conversationId);
    await Message.deleteMany({ conversationId });
    
    res.status(200).json({ message: '对话删除成功' });
  } catch (error) {
    console.error('删除对话错误:', error);
    res.status(500).json({ message: '删除对话失败', error: error.message });
  }
});

// 更新对话标题
router.put('/conversations/:conversationId', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { title } = req.body;
    
    if (!title) {
      return res.status(400).json({ message: '标题不能为空' });
    }
    
    const updatedConversation = await Conversation.findByIdAndUpdate(
      conversationId,
      { title, lastUpdated: new Date() },
      { new: true }
    );
    
    if (!updatedConversation) {
      return res.status(404).json({ message: '对话不存在' });
    }
    
    res.status(200).json({
      message: '对话标题更新成功',
      conversation: updatedConversation
    });
  } catch (error) {
    console.error('更新对话标题错误:', error);
    res.status(500).json({ message: '更新对话标题失败', error: error.message });
  }
});

module.exports = router;