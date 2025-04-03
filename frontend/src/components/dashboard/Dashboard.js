import React, { useState, useEffect } from 'react';
import { Row, Col, Card, Statistic, Button, List, Typography, Spin, Empty } from 'antd';
import { MessageOutlined, FileTextOutlined, PlusOutlined, AreaChartOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';

const { Title, Paragraph } = Typography;

const Dashboard = ({ user }) => {
  const [loading, setLoading] = useState(true);
  const [recentRecords, setRecentRecords] = useState([]);
  const [recentConversations, setRecentConversations] = useState([]);
  const [stats, setStats] = useState({
    totalRecords: 0,
    totalConversations: 0
  });
  const navigate = useNavigate();

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        
        // 获取最近的病历记录
        const recordsResponse = await axios.get(`/api/records/user/${user.id}`);
        setRecentRecords(recordsResponse.data.records.slice(0, 5));
        
        // 获取最近的对话
        const conversationsResponse = await axios.get(`/api/chat/conversations/user/${user.id}`);
        setRecentConversations(conversationsResponse.data.conversations.slice(0, 5));
        
        // 设置统计数据
        setStats({
          totalRecords: recordsResponse.data.records.length,
          totalConversations: conversationsResponse.data.conversations.length
        });
      } catch (error) {
        console.error('获取仪表盘数据错误:', error);
      } finally {
        setLoading(false);
      }
    };
    
    fetchDashboardData();
  }, [user.id]);

  return (
    <div>
      <Title level={2}>欢迎，{user.username}</Title>
      <Paragraph>这是您的健康管理仪表盘，您可以在这里查看健康数据概览和快速访问功能。</Paragraph>
      
      {loading ? (
        <div style={{ textAlign: 'center', margin: '50px 0' }}>
          <Spin size="large" />
        </div>
      ) : (
        <>
          {/* 统计卡片 */}
          <Row gutter={16} style={{ marginBottom: 24 }}>
            <Col xs={24} sm={12} md={8} lg={8}>
              <Card className="stat-card">
                <Statistic 
                  title="病历记录" 
                  value={stats.totalRecords} 
                  prefix={<FileTextOutlined />} 
                />
                <Button 
                  type="link" 
                  onClick={() => navigate('/records')}
                >
                  查看全部
                </Button>
              </Card>
            </Col>
            <Col xs={24} sm={12} md={8} lg={8}>
              <Card className="stat-card">
                <Statistic 
                  title="健康咨询" 
                  value={stats.totalConversations} 
                  prefix={<MessageOutlined />} 
                />
                <Button 
                  type="link" 
                  onClick={() => navigate('/chat')}
                >
                  开始咨询
                </Button>
              </Card>
            </Col>
            <Col xs={24} sm={12} md={8} lg={8}>
              <Card className="stat-card">
                <Statistic 
                  title="健康趋势" 
                  value="查看" 
                  prefix={<AreaChartOutlined />} 
                />
                <Button 
                  type="link" 
                  onClick={() => navigate('/analytics')}
                  disabled
                >
                  即将推出
                </Button>
              </Card>
            </Col>
          </Row>
          
          {/* 快速操作 */}
          <Row gutter={16} style={{ marginBottom: 24 }}>
            <Col span={24}>
              <Card title="快速操作">
                <Row gutter={16}>
                  <Col xs={12} sm={8} md={6}>
                    <Button 
                      type="primary" 
                      icon={<MessageOutlined />} 
                      onClick={() => navigate('/chat')}
                      block
                    >
                      开始咨询
                    </Button>
                  </Col>
                  <Col xs={12} sm={8} md={6}>
                    <Button 
                      type="primary" 
                      icon={<PlusOutlined />} 
                      onClick={() => navigate('/records/upload')}
                      block
                    >
                      上传病历
                    </Button>
                  </Col>
                </Row>
              </Card>
            </Col>
          </Row>
          
          {/* 最近记录和对话 */}
          <Row gutter={16}>
            <Col xs={24} md={12}>
              <Card title="最近病历记录" extra={<Button type="link" onClick={() => navigate('/records')}>查看全部</Button>}>
                {recentRecords.length > 0 ? (
                  <List
                    itemLayout="horizontal"
                    dataSource={recentRecords}
                    renderItem={record => (
                      <List.Item
                        actions={[<Button type="link" onClick={() => navigate(`/records/${record._id}`)}>查看</Button>]}
                      >
                        <List.Item.Meta
                          title={record.description || `${record.recordType} 记录`}
                          description={new Date(record.uploadDate).toLocaleString()}
                        />
                      </List.Item>
                    )}
                  />
                ) : (
                  <Empty description="暂无病历记录" />
                )}
              </Card>
            </Col>
            <Col xs={24} md={12}>
              <Card title="最近健康咨询" extra={<Button type="link" onClick={() => navigate('/chat')}>查看全部</Button>}>
                {recentConversations.length > 0 ? (
                  <List
                    itemLayout="horizontal"
                    dataSource={recentConversations}
                    renderItem={conversation => (
                      <List.Item
                        actions={[<Button type="link" onClick={() => navigate(`/chat/${conversation.id}`)}>继续</Button>]}
                      >
                        <List.Item.Meta
                          title={conversation.title}
                          description={new Date(conversation.lastUpdated).toLocaleString()}
                        />
                      </List.Item>
                    )}
                  />
                ) : (
                  <Empty description="暂无健康咨询记录" />
                )}
              </Card>
            </Col>
          </Row>
        </>
      )}
    </div>
  );
};

export default Dashboard;