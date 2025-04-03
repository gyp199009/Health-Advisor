const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const pdfParse = require('pdf-parse');
const Tesseract = require('tesseract.js');
const mongoose = require('mongoose');
const Record = require('../models/Record');

// 配置文件上传
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../uploads');
    // 确保上传目录存在
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // 生成唯一文件名
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + ext);
  }
});

// 文件类型过滤
const fileFilter = (req, file, cb) => {
  // 允许的文件类型
  const allowedTypes = ['.jpg', '.jpeg', '.png', '.pdf', '.txt', '.doc', '.docx', '.xls', '.xlsx'];
  const allowedMimeTypes = ['image/jpeg', 'image/png', 'application/pdf', 'text/plain', 
    'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'];

  const ext = path.extname(file.originalname).toLowerCase();
  
  if (allowedTypes.includes(ext) && allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    const errorMsg = `不支持的文件类型 ${ext} (${file.mimetype})，允许的类型：${allowedTypes.join(', ')}`;
    cb(new Error(errorMsg), false);
  }
};

const upload = multer({ 
  storage, 
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 } // 限制文件大小为10MB
});

// 提取文本内容的函数
async function extractTextFromFile(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  let text = '';
  
  try {
    if (ext === '.pdf') {
      // 从PDF提取文本
      const dataBuffer = fs.readFileSync(filePath);
      const pdfData = await pdfParse(dataBuffer);
      text = pdfData.text;
    } else if (['.jpg', '.jpeg', '.png'].includes(ext)) {
      // 从图片提取文本 (OCR)
      const { data } = await Tesseract.recognize(filePath, 'chi_sim+eng');
      text = data.text;
    } else if (ext === '.txt') {
      // 直接读取文本文件
      text = fs.readFileSync(filePath, 'utf8');
    } else {
      // 对于其他文件类型，可以添加更多处理方法
      text = `无法提取文本内容，文件类型: ${ext}`;
    }
    
    return text;
  } catch (error) {
    console.error('提取文本错误:', error);
    return `提取文本失败: ${error.message}`;
  }
}

// 上传病历记录
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const { userId, recordType, description, originalFileName } = req.body;
    
    if (!userId) {
      return res.status(400).json({ message: '缺少用户ID' });
    }
    
    let fileData = {};
    let textContent = '';
    
    // 如果上传了文件
    if (req.file) {
      // 使用前端传来的原始文件名（如果有）或者使用multer解析的文件名
      const originalName = originalFileName || req.file.originalname;
      
      fileData = {
        filename: req.file.filename,
        originalName: originalName,
        path: req.file.path,
        mimetype: req.file.mimetype,
        size: req.file.size
      };
      
      // 提取文件中的文本内容
      textContent = await extractTextFromFile(req.file.path);
    } else if (req.body.textContent) {
      // 如果是直接输入的文本内容
      textContent = req.body.textContent;
    } else {
      return res.status(400).json({ message: '请提供文件或文本内容' });
    }
    
    // 创建新的病历记录
    const newRecord = new Record({
      userId,
      recordType: recordType || '其他',
      description,
      file: req.file ? fileData : null,
      textContent,
      uploadDate: new Date()
    });
    
    await newRecord.save();
    
    res.status(201).json({
      message: '病历记录上传成功',
      record: {
        id: newRecord._id,
        recordType: newRecord.recordType,
        description: newRecord.description,
        uploadDate: newRecord.uploadDate.toISOString()
      }
    });
  } catch (error) {
    console.error('上传病历记录错误:', error);
    console.error('请求体:', req.body);
    console.error('上传文件:', req.file);
    res.status(500).json({ message: '上传病历记录失败', error: error.message });
  }
});

// 获取用户的所有病历记录
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    const records = await Record.find({ userId })
      .sort({ uploadDate: -1 })
      .select('-file.path -textContent'); // 不返回文件路径和完整文本内容
    
    res.status(200).json({ records });
  } catch (error) {
    console.error('获取病历记录错误:', error);
    res.status(500).json({ message: '获取病历记录失败', error: error.message });
  }
});

// 获取单个病历记录详情
router.get('/:recordId', async (req, res) => {
  try {
    const { recordId } = req.params;
    const { userId } = req.query; // 从查询参数中获取用户ID
    
    if (!recordId || !mongoose.Types.ObjectId.isValid(recordId)) {
      return res.status(400).json({ message: '无效的病历ID格式' });
    }

    if (!userId) {
      return res.status(401).json({ message: '未提供用户ID' });
    }

    const record = await Record.findById(recordId);
    if (!record) {
      return res.status(404).json({ message: '病历记录不存在' });
    }

    // 验证用户权限
    if (record.userId.toString() !== userId) {
      return res.status(403).json({ message: '无权访问该病历记录' });
    }
    
    res.status(200).json({ 
      record: {
        ...record.toObject(),
        uploadDate: record.uploadDate.toISOString()
      }
    });
  } catch (error) {
    console.error('获取病历记录详情错误:', error);
    res.status(500).json({ message: '获取病历记录详情失败', error: error.message });
  }
});

// 删除病历记录
router.delete('/:recordId', async (req, res) => {
  try {
    const { recordId } = req.params;
    
    if (!mongoose.Types.ObjectId.isValid(recordId)) {
      return res.status(400).json({ message: '无效的病历ID格式' });
    }

    const record = await Record.findById(recordId);
    if (!record) {
      return res.status(404).json({ message: '病历记录不存在' });
    }
    
    // 如果有文件，删除文件
    if (record.file && record.file.path) {
      fs.unlink(record.file.path, (err) => {
        if (err) console.error('删除文件错误:', err);
      });
    }
    
    await Record.findByIdAndDelete(recordId);
    
    res.status(200).json({ message: '病历记录删除成功' });
  } catch (error) {
    console.error('删除病历记录错误:', error);
    res.status(500).json({ message: '删除病历记录失败', error: error.message });
  }
});

// 获取病历原始文件
router.get('/:recordId/file', async (req, res) => {
  try {
    const { recordId } = req.params;
    const { userId } = req.query; // 从查询参数中获取用户ID
    
    if (!recordId || !mongoose.Types.ObjectId.isValid(recordId)) {
      return res.status(400).json({ message: '无效的病历ID格式' });
    }

    if (!userId) {
      return res.status(401).json({ message: '未提供用户ID' });
    }
    
    const record = await Record.findById(recordId);
    
    if (!record || !record.file || !record.file.path) {
      return res.status(404).json({ message: '文件不存在' });
    }

    // 验证用户权限
    if (record.userId.toString() !== userId) {
      return res.status(403).json({ message: '无权访问该病历记录' });
    }

    // 使用record.file中的路径
    const filePath = record.file.path;
    
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: '文件不存在' });
    }

    // 设置响应头
    res.setHeader('Content-Type', record.file.mimetype);
    
    // 处理文件名编码，确保中文文件名能正确显示
    let fileName = record.file.originalName;
    // 如果文件名是URL编码的，先解码
    try {
      if (fileName.includes('%')) {
        fileName = decodeURIComponent(fileName);
      }
    } catch (e) {
      console.error('文件名解码错误:', e);
    }
    
    // 使用RFC 5987编码，支持UTF-8字符
    const encodedFilename = encodeURIComponent(fileName).replace(/['()]/g, escape);
    
    // 修复Content-Disposition头部，确保没有无效字符
    // 只使用filename*参数，避免在filename参数中使用可能导致问题的字符
    res.setHeader('Content-Disposition', `attachment; filename*=UTF-8''${encodedFilename}`);
    
    // 设置额外的响应头，帮助浏览器正确处理文件
    res.setHeader('Access-Control-Expose-Headers', 'Content-Disposition');
    res.setHeader('Cache-Control', 'no-cache');

    // 创建文件流
    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);

  } catch (error) {
    console.error('获取文件错误:', error);
    res.status(500).json({ message: '获取文件失败', error: error.message });
  }
});

module.exports = router;