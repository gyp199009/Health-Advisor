import React, { useState, useEffect } from 'react';
import { List, Card, Button, Typography, Spin, Empty, Popconfirm, Tag, message } from 'antd';
import { PlusOutlined, DeleteOutlined, EyeOutlined, FileTextOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';

const { Title, Paragraph, Text } = Typography;

const RecordsList = ({ user }) => {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  // 加载病历列表
  useEffect(() => {
    const fetchRecords = async () => {
      try {
        setLoading(true);
        const response = await axios.get(`/api/records/user/${user.id}`);
        setRecords(response.data.records);
      } catch (error) {
        console.error('获取病历列表错误:', error);
        message.error('获取病历列表失败，请稍后再试');
      } finally {
        setLoading(false);
      }
    };
    
    fetchRecords();
  }, [user.id]);

  // 删除病历
  const handleDeleteRecord = async (recordId) => {
    try {
      await axios.delete(`/api/records/${recordId}`);
      setRecords(prevRecords => 
        prevRecords.filter(record => record._id !== recordId)
      );
      message.success('病历已删除');
    } catch (error) {
      console.error('删除病历错误:', error);
      message.error('删除病历失败，请稍后再试');
    }
  };

  // 查看病历详情
  const viewRecordDetail = (recordId) => {
    navigate(`/records/${recordId}`);
  };

  // 格式化日期
  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  // 获取文件类型图标
  const getFileTypeIcon = (recordType) => {
    return <FileTextOutlined />;
  };

  // 获取记录类型中文名称和标签颜色
  const getRecordTypeInfo = (recordType) => {
    const typeMap = {
      'exam_report': { label: '检查报告', color: 'blue' },
      'diagnosis': { label: '诊断证明', color: 'green' },
      'medication': { label: '处方', color: 'orange' },
      'case_summary': { label: '病例摘要', color: 'purple' },
      'surgery_record': { label: '手术记录', color: 'red' },
      'other': { label: '其他', color: 'default' }
    };
    
    return typeMap[recordType] || { label: recordType, color: 'default' };
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <Title level={2}>病历管理</Title>
        <Button 
          type="primary" 
          icon={<PlusOutlined />} 
          onClick={() => navigate('/records/upload')}
        >
          上传病历
        </Button>
      </div>
      
      <Paragraph>管理您的病历记录，上传新的病历或查看已有病历。</Paragraph>
      
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
          dataSource={records}
          locale={{ emptyText: <Empty description="暂无病历记录" /> }}
          renderItem={record => (
            <List.Item>
              <Card
                title={
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    {getFileTypeIcon(record.recordType)}
                    <span style={{ marginLeft: '8px' }}>{record.description}</span>
                  </div>
                }
                actions={[
                  <Button 
                    type="text" 
                    icon={<EyeOutlined />} 
                    onClick={() => viewRecordDetail(record._id)}
                  >
                    查看详情
                  </Button>,
                  <Popconfirm
                    title="确定要删除这个病历记录吗？"
                    onConfirm={() => handleDeleteRecord(record._id)}
                    okText="确定"
                    cancelText="取消"
                  >
                    <Button 
                      type="text" 
                      icon={<DeleteOutlined />} 
                      danger
                    >
                      删除
                    </Button>
                  </Popconfirm>
                ]}
                style={{ height: '100%' }}
              >
                <div style={{ marginBottom: '12px' }}>
                  <Tag color={getRecordTypeInfo(record.recordType).color}>{getRecordTypeInfo(record.recordType).label}</Tag>
                  <p><strong>上传时间:</strong> {new Date(record.uploadDate).toLocaleString()}</p>
                  {record.fileUrl && (
                    <p><strong>文件类型:</strong> {record.fileType}</p>
                  )}
                </div>
              </Card>
            </List.Item>
          )}
        />
      )}
    </div>
  );
};

export default RecordsList;