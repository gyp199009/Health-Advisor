const mongoose = require('mongoose');

const ConversationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  title: {
    type: String,
    required: true,
    default: '新对话'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  isArchived: {
    type: Boolean,
    default: false
  }
});

module.exports = mongoose.model('Conversation', ConversationSchema);