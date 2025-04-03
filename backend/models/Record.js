const mongoose = require('mongoose');

const RecordSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  recordType: {
    type: String,
    required: true,
    enum: ['lab_report', 'exam_report', 'imaging', 'outpatient', 'inpatient', 'surgery', 'medication', 'other', 'diagnosis', 'text', 'chat_upload'],
    default: 'other'
  },
  description: {
    type: String,
    default: ''
  },
  file: {
    filename: String,
    originalName: String,
    path: String,
    mimetype: String,
    size: Number
  },
  textContent: {
    type: String,
    required: true
  },
  uploadDate: {
    type: Date,
    default: Date.now
  },
  tags: [{
    type: String
  }]
});

// 创建文本索引以支持搜索
RecordSchema.index({ textContent: 'text', description: 'text' });

module.exports = mongoose.model('Record', RecordSchema);