import React, { useState, useEffect } from 'react';
import { List, Card, Button, Typography, Spin, Empty, Popconfirm, Input, message } from 'antd';
import { PlusOutlined, DeleteOutlined, EditOutlined, MessageOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

const { Title, Paragraph } = Typography;

const ChatList = ({ user }) => {
  const [conversations, setConversations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState(null);
  const [editTitle, setEditTitle] = useState('');
  const navigate = useNavigate();
  const { t } = useTranslation();

  // 加载对话列表
  useEffect(() => {
    const fetchConversations = async () => {
      try {
        setLoading(true);
        const response = await axios.get(`/api/chat/conversations/user/${user.id}`);
        setConversations(response.data.conversations);
      } catch (error) {
        console.error('Fetch conversations error:', error);
        message.error(t('chat.fetchError'));
      } finally {
        setLoading(false);
      }
    };
    
    fetchConversations();
  }, [user.id]);

  // 创建新对话
  const handleCreateConversation = async () => {
    try {
      const response = await axios.post('/api/chat/conversations', {
        userId: user.id,
        title: `${t('chat.newChat')} ${new Date().toLocaleString()}`
      });
      
      if (response.data && response.data.conversation) {
        navigate(`/chat/${response.data.conversation.id}`);
      } else {
        message.error(t('chat.createError'));
      }
    } catch (error) {
      console.error('Create conversation error:', error);
      message.error(t('chat.createError'));
    }
  };

  // 删除对话
  const handleDeleteConversation = async (conversationId) => {
    try {
      await axios.delete(`/api/chat/conversations/${conversationId}`);
      setConversations(prevConversations => 
        prevConversations.filter(conv => conv._id !== conversationId)
      );
      message.success(t('chat.deleteSuccess'));
    } catch (error) {
      console.error('Delete conversation error:', error);
      message.error(t('chat.deleteError'));
    }
  };

  // 开始编辑对话标题
  const startEditing = (conversation) => {
    setEditingId(conversation._id);
    setEditTitle(conversation.title);
  };

  // 保存编辑后的标题
  const saveTitle = async (conversationId) => {
    if (!editTitle.trim()) {
      message.error(t('chat.titleRequired'));
      return;
    }
    
    try {
      const response = await axios.put(`/api/chat/conversations/${conversationId}`, {
        title: editTitle
      });
      
      if (response.data && response.data.conversation) {
        setConversations(prevConversations => 
          prevConversations.map(conv => 
            conv._id === conversationId ? { ...conv, title: editTitle } : conv
          )
        );
        message.success(t('chat.updateSuccess'));
      } else {
        message.error(t('chat.updateError'));
      }
    } catch (error) {
      console.error('Update title error:', error);
      message.error(t('chat.updateError'));
    } finally {
      setEditingId(null);
      setEditTitle('');
    }
  };

  // 格式化日期
  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <Title level={2}>{t('nav.chat')}</Title>
        <Button 
          type="primary" 
          icon={<PlusOutlined />} 
          onClick={handleCreateConversation}
        >
          {t('chat.newChat')}
        </Button>
      </div>
      
      <Paragraph>{t('chat.description')}</Paragraph>
      
      {loading ? (
        <div style={{ textAlign: 'center', margin: '50px 0' }}>
          <Spin size="large" />
        </div>
      ) : (
        <List
          grid={{ 
            gutter: 16,
            xs: 1,
            sm: 1,
            md: 2,
            lg: 3,
            xl: 3,
            xxl: 4
          }}
          dataSource={conversations}
          locale={{ emptyText: <Empty description={t('chat.noChats')} /> }}
          renderItem={conversation => (
            <List.Item>
              <Card
                title={
                  editingId === conversation._id ? (
                    <Input 
                      value={editTitle} 
                      onChange={e => setEditTitle(e.target.value)} 
                      onPressEnter={() => saveTitle(conversation._id)}
                      onBlur={() => saveTitle(conversation._id)}
                      autoFocus
                    />
                  ) : (
                    conversation.title
                  )
                }
                actions={[
                  <Button 
                    type="text" 
                    icon={<MessageOutlined />} 
                    onClick={() => navigate(`/chat/${conversation._id}`)}
                  >
                    {t('chat.continue')}
                  </Button>,
                  <Button 
                    type="text" 
                    icon={<EditOutlined />} 
                    onClick={() => startEditing(conversation)}
                  >
                    {t('common.rename')}
                  </Button>,
                  <Popconfirm
                    title={t('chat.confirmDelete')}
                    onConfirm={() => handleDeleteConversation(conversation._id)}
                    okText={t('common.confirm')}
                    cancelText={t('common.cancel')}
                  >
                    <Button 
                      type="text" 
                      icon={<DeleteOutlined />} 
                      danger
                    >
                      {t('common.delete')}
                    </Button>
                  </Popconfirm>
                ]}
                style={{ height: '100%' }}
              >
                <div style={{ marginBottom: '12px' }}>
                  <p><strong>{t('chat.createdAt')}:</strong> {formatDate(conversation.createdAt)}</p>
                  <p><strong>{t('chat.lastUpdated')}:</strong> {formatDate(conversation.lastUpdated)}</p>
                </div>
              </Card>
            </List.Item>
          )}
        />
      )}
    </div>
  );
};

export default ChatList;