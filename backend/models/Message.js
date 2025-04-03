const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  conversationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  content: {
    type: String,
    required: true
  },
  role: {
    type: String,
    enum: ['user', 'assistant', 'system'],
    required: true
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  attachments: [{
    recordId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Record'
    }
  }]
});

module.exports = mongoose.model('Message', MessageSchema);