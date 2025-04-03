import React, { useState, useEffect, useRef } from 'react';
import { Input, Button, Typography, Spin, Divider, Avatar, message, Upload, Card, Modal, List, Tag, Select } from 'antd';
import { SendOutlined, UserOutlined, RobotOutlined, PaperClipOutlined, FileTextOutlined, FileImageOutlined, FilePdfOutlined, FileOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';
import { useParams, useNavigate } from 'react-router-dom';
import ReactMarkdown from 'react-markdown';
import axios from 'axios';

const { Title, Paragraph, Text } = Typography;
const { TextArea } = Input;

const ChatWindow = ({ user }) => {
  const { conversationId } = useParams();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [conversation, setConversation] = useState(null);
  const [models, setModels] = useState([]);
  const [selectedModel, setSelectedModel] = useState('volcengine');
  const [loadingModels, setLoadingModels] = useState(true);
  const messagesEndRef = useRef(null);
  const [textRecordModalVisible, setTextRecordModalVisible] = useState(false);
  const [textRecordContent, setTextRecordContent] = useState('');
  const [textRecordDescription, setTextRecordDescription] = useState('');
  const [userRecords, setUserRecords] = useState([]);
  const [recordsModalVisible, setRecordsModalVisible] = useState(false);

  // 加载AI模型列表
  useEffect(() => {
    const fetchModels = async () => {
      try {
        const response = await axios.get('/api/chat/models');
        setModels(response.data.models);
      } catch (error) {
        console.error('获取AI模型列表错误:', error);
        message.error(t('chat.modelLoadError'));
      } finally {
        setLoadingModels(false);
      }
    };

    fetchModels();
  }, []);

  // 加载对话信息和消息历史
  useEffect(() => {
    const fetchConversationData = async () => {
      try {
        setLoading(true);
        
        // 获取对话信息
        const conversationsResponse = await axios.get(`/api/chat/conversations/user/${user.id}`);
        const currentConversation = conversationsResponse.data.conversations.find(
          conv => conv._id === conversationId
        );
        
        if (!currentConversation) {
          message.error('对话不存在或已被删除');
          navigate('/chat');
          return;
        }
        
        setConversation(currentConversation);
        
        // 获取消息历史
        const messagesResponse = await axios.get(`/api/chat/conversations/${conversationId}/messages`);
        setMessages(messagesResponse.data.messages);
        
        // 获取用户的病历记录
        const recordsResponse = await axios.get(`/api/records/user/${user.id}`);
        setUserRecords(recordsResponse.data.records);
      } catch (error) {
        console.error('获取对话数据错误:', error);
        message.error('获取对话数据失败，请稍后再试');
      } finally {
        setLoading(false);
      }
    };
    
    if (conversationId) {
      fetchConversationData();
    }
  }, [conversationId, user.id, navigate]);

  // 滚动到最新消息
  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  // 发送消息
  const handleSendMessage = async () => {
    if (!inputMessage.trim()) return;
    
    try {
      setSending(true);
      
      const response = await axios.post(`/api/chat/conversations/${conversationId}/messages`, {
        userId: user.id,
        content: inputMessage,
        modelType: selectedModel
      });
      
      if (response.data) {
        // 添加用户消息和AI回复到消息列表
        setMessages(prevMessages => [
          ...prevMessages,
          {
            _id: response.data.userMessage.id,
            content: response.data.userMessage.content,
            role: 'user',
            timestamp: response.data.userMessage.timestamp
          },
          {
            _id: response.data.aiMessage.id,
            content: response.data.aiMessage.content,
            role: 'assistant',
            timestamp: response.data.aiMessage.timestamp,
            error: response.data.aiMessage.error
          }
        ]);
        
        setInputMessage('');
      } else {
        message.error('发送消息失败');
      }
    } catch (error) {
      console.error('发送消息错误:', error);
      message.error('发送消息失败，请稍后再试');
    } finally {
      setSending(false);
    }
  };

  // 格式化时间
  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  // 上传病历附件
  const handleAttachRecord = async (file) => {
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('userId', user.id);
      formData.append('recordType', '聊天上传');
      formData.append('description', `在对话"${conversation?.title || '健康咨询'}"中上传`);
      
      message.loading({ content: '正在上传病历...', key: 'uploadRecord' });
      
      const response = await axios.post('/api/records/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      
      if (response.data && response.data.record) {
        message.success({ content: '病历上传成功，AI将在回复中考虑此病历资料', key: 'uploadRecord', duration: 3 });
        
        // 添加系统消息通知用户病历已上传
        const systemMsg = {
          _id: Date.now().toString(),
          content: `病历"${response.data.record.description || response.data.record.recordType}"已上传，AI将在回复中考虑此信息`,
          role: 'system',
          timestamp: new Date().toISOString()
        };
        
        setMessages(prevMessages => [...prevMessages, systemMsg]);
        
        // 更新病历列表
        const recordsResponse = await axios.get(`/api/records/user/${user.id}`);
        setUserRecords(recordsResponse.data.records);
      }
      
      return false; // 阻止默认上传行为
    } catch (error) {
      console.error('上传病历错误:', error);
      message.error({ content: '上传病历失败，请稍后再试', key: 'uploadRecord' });
      return false;
    }
  };
  
  // 添加文本病历
  const handleAddTextRecord = async () => {
    if (!textRecordContent.trim()) {
      message.error('病历内容不能为空');
      return;
    }
    
    try {
      message.loading({ content: '正在添加病历...', key: 'addTextRecord' });
      
      const response = await axios.post('/api/records/upload', {
        userId: user.id,
        recordType: '文本记录',
        description: textRecordDescription || `在对话"${conversation?.title || '健康咨询'}"中添加的文本记录`,
        textContent: textRecordContent
      });
      
      if (response.data && response.data.record) {
        message.success({ content: '病历添加成功，AI将在回复中考虑此病历资料', key: 'addTextRecord', duration: 3 });
        
        // 添加系统消息通知用户病历已添加
        const systemMsg = {
          _id: Date.now().toString(),
          content: `病历"${response.data.record.description || '文本记录'}"已添加，AI将在回复中考虑此信息`,
          role: 'system',
          timestamp: new Date().toISOString()
        };
        
        setMessages(prevMessages => [...prevMessages, systemMsg]);
        
        // 更新病历列表
        const recordsResponse = await axios.get(`/api/records/user/${user.id}`);
        setUserRecords(recordsResponse.data.records);
        
        // 关闭模态框并清空输入
        setTextRecordModalVisible(false);
        setTextRecordContent('');
        setTextRecordDescription('');
      }
    } catch (error) {
      console.error('添加文本病历错误:', error);
      message.error({ content: '添加病历失败，请稍后再试', key: 'addTextRecord' });
    }
  };
  
  // 显示病历列表
  const showRecordsList = () => {
    setRecordsModalVisible(true);
  };
  
  // 获取文件图标
  const getFileIcon = (mimetype) => {
    if (!mimetype) return <FileOutlined />;
    
    if (mimetype.includes('image')) {
      return <FileImageOutlined />;
    } else if (mimetype.includes('pdf')) {
      return <FilePdfOutlined />;
    } else if (mimetype.includes('text')) {
      return <FileTextOutlined />;
    } else {
      return <FileOutlined />;
    }
  };

  return (
    <div>
      {loading ? (
        <div style={{ textAlign: 'center', margin: '50px 0' }}>
          <Spin size="large" />
        </div>
      ) : (
        <>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <Title level={3}>{conversation?.title || '健康咨询'}</Title>
            <Button onClick={() => navigate('/chat')}>返回列表</Button>
          </div>
          
          <Divider />
          
          <div className="chat-container">
            <div className="messages-container">
              {messages.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '40px 0' }}>
                  <RobotOutlined style={{ fontSize: '48px', color: '#1890ff', marginBottom: '16px' }} />
                  <Paragraph>您好！我是您的AI健康顾问，请告诉我您的健康问题，我会基于您的病历资料给出专业建议。</Paragraph>
                </div>
              ) : (
                messages.map(msg => (
                  <div 
                    key={msg._id} 
                    className={`message ${msg.role === 'user' ? 'message-user' : 'message-ai'}`}
                  >
                    <div style={{ display: 'flex', alignItems: 'flex-start' }}>
                      {msg.role !== 'user' && (
                        <Avatar 
                          icon={<RobotOutlined />} 
                          style={{ marginRight: '8px', backgroundColor: '#1890ff' }} 
                        />
                      )}
                      <div style={{ flex: 1 }}>
                        {msg.role === 'assistant' ? (
                          <ReactMarkdown>{msg.content}</ReactMarkdown>
                        ) : (
                          <Text>{msg.content}</Text>
                        )}
                        <div className="message-time">
                          {msg.role === 'user' ? '您' : 'AI顾问'} · {formatTime(msg.timestamp)}
                        </div>
                      </div>
                      {msg.role === 'user' && (
                        <Avatar 
                          icon={<UserOutlined />} 
                          style={{ marginLeft: '8px', backgroundColor: '#52c41a' }} 
                        />
                      )}
                    </div>
                  </div>
                ))
              )}
              <div ref={messagesEndRef} />
            </div>
            
            <Card className="message-input-container">
              <div style={{ marginBottom: '16px' }}>
                <Select
                  loading={loadingModels}
                  value={selectedModel}
                  onChange={setSelectedModel}
                  style={{ width: '200px' }}
                  placeholder={t('chat.selectModel')}
                >
                  {models.map(model => (
                    <Select.Option key={model.id} value={model.id}>
                      {t(`chat.models.${model.id}`)}
                    </Select.Option>
                  ))}
                </Select>
              </div>
              <div className="message-input">
                <TextArea
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  placeholder="输入您的健康问题..."
                  autoSize={{ minRows: 2, maxRows: 6 }}
                  onPressEnter={(e) => {
                    if (!e.shiftKey) {
                      e.preventDefault();
                      handleSendMessage();
                    }
                  }}
                  disabled={sending}
                />
                <div style={{ marginTop: '8px', display: 'flex', justifyContent: 'space-between' }}>
                  <div>
                    <Upload
                      beforeUpload={handleAttachRecord}
                      showUploadList={false}
                      accept=".jpg,.jpeg,.png,.pdf,.txt,.doc,.docx"
                    >
                      <Button icon={<PaperClipOutlined />} style={{ marginRight: '8px' }}>上传病历文件</Button>
                    </Upload>
                    <Button 
                      icon={<FileTextOutlined />} 
                      onClick={() => setTextRecordModalVisible(true)}
                      style={{ marginRight: '8px' }}
                    >
                      添加文本病历
                    </Button>
                    <Button 
                      icon={<FileOutlined />} 
                      onClick={showRecordsList}
                    >
                      查看病历列表
                    </Button>
                  </div>
                  <Button
                    type="primary"
                    icon={<SendOutlined />}
                    onClick={handleSendMessage}
                    loading={sending}
                    disabled={!inputMessage.trim()}
                  >
                    发送
                  </Button>
                </div>
              </div>
            </Card>
          </div>
        </>
      )}
      
      {/* 添加文本病历的模态框 */}
      <Modal
        title="添加文本病历"
        open={textRecordModalVisible}
        onOk={handleAddTextRecord}
        onCancel={() => setTextRecordModalVisible(false)}
        okText="添加"
        cancelText="取消"
      >
        <div style={{ marginBottom: '16px' }}>
          <Input 
            placeholder="病历描述（选填）" 
            value={textRecordDescription}
            onChange={(e) => setTextRecordDescription(e.target.value)}
            style={{ marginBottom: '8px' }}
          />
          <TextArea
            placeholder="请输入病历内容..."
            value={textRecordContent}
            onChange={(e) => setTextRecordContent(e.target.value)}
            autoSize={{ minRows: 6, maxRows: 12 }}
          />
        </div>
      </Modal>
      
      {/* 病历列表模态框 */}
      <Modal
        title="病历记录列表"
        open={recordsModalVisible}
        onCancel={() => setRecordsModalVisible(false)}
        footer={null}
        width={700}
      >
        {userRecords.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '20px 0' }}>
            <p>暂无病历记录</p>
          </div>
        ) : (
          <List
            itemLayout="horizontal"
            dataSource={userRecords}
            renderItem={record => (
              <List.Item>
                <List.Item.Meta
                  avatar={getFileIcon(record.file?.mimetype)}
                  title={
                    <div>
                      {record.description || record.recordType}
                      <Tag color="blue" style={{ marginLeft: '8px' }}>{record.recordType}</Tag>
                    </div>
                  }
                  description={
                    <div>
                      <p>上传时间: {new Date(record.uploadDate).toLocaleString()}</p>
                      {record.file && (
                        <p>文件: {record.file.originalName || '无文件名'}</p>
                      )}
                    </div>
                  }
                />
              </List.Item>
            )}
          />
        )}
      </Modal>
    </div>
  );
};

export default ChatWindow;