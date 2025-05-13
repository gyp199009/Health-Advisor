import React, { useState, useEffect } from 'react';
import { Card, Typography, Button, Spin, Empty, message, Tag, Divider, Tooltip } from 'antd';
import { ArrowLeftOutlined, DownloadOutlined, FileTextOutlined, FilePdfOutlined, FileImageOutlined, FileOutlined, EyeOutlined } from '@ant-design/icons';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import FileViewer from './FileViewer';

const { Title, Paragraph, Text } = Typography;

const RecordDetail = ({ user }) => {
  const { recordId } = useParams();
  const navigate = useNavigate();
  const [record, setRecord] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filePreviewVisible, setFilePreviewVisible] = useState(false);

  // 加载病历详情
  useEffect(() => {
    const fetchRecordDetail = async () => {
      try {
        setLoading(true);
        const response = await axios.get(`/api/records/${recordId}?userId=${user.id}`);
        
        if (response.data && response.data.record) {
          setRecord(response.data.record);
        } else {
          message.error('获取病历详情失败');
          navigate('/records');
        }
      } catch (error) {
        console.error('获取病历详情错误:', error);
        message.error('获取病历详情失败，请稍后再试');
        navigate('/records');
      } finally {
        setLoading(false);
      }
    };
    
    if (recordId && user) {
      fetchRecordDetail();
    }
  }, [recordId, navigate, user]);

  // 格式化日期
  const formatDate = (dateString) => {
    const date = new Date(dateString);
    return date.toLocaleString();
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

  // 获取文件类型图标
  const getFileTypeIcon = (fileType) => {
    if (!fileType) return <FileTextOutlined />;
    
    if (fileType.includes('pdf')) {
      return <FilePdfOutlined />;
    } else if (fileType.includes('image')) {
      return <FileImageOutlined />;
    } else {
      return <FileOutlined />;
    }
  };

  // 处理文件预览
  const handlePreview = () => {
    if (record.file) {
      setFilePreviewVisible(true);
    } else {
      message.warning('无法预览，文件不存在');
    }
  };

  // 处理文件下载
  const handleDownload = async () => {
    if (record.file) {
      try {
        const response = await axios.get(`/api/records/${recordId}/file?userId=${user.id}`, {
          responseType: 'blob'
        });
        
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', record.file.originalName || '病历文件');
        document.body.appendChild(link);
        link.click();
        link.remove();
        window.URL.revokeObjectURL(url);
        message.success('文件下载成功');
      } catch (error) {
        console.error('下载文件错误:', error);
        message.error('下载文件失败，请稍后再试');
      }
    } else {
      message.warning('无法下载，文件不存在');
    }
  };

  // 返回病历列表
  const goBack = () => {
    navigate('/records');
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', margin: '50px 0' }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!record) {
    return (
      <Empty 
        description="未找到病历记录" 
        style={{ margin: '50px 0' }}
      />
    );
  }

  // 处理文件名称，防止乱码
  const formatFileName = (fileName) => {
    if (!fileName) return '病历文件';
    
    try {
      // 尝试解码文件名
      const decodedName = decodeURIComponent(fileName);
      return decodedName;
    } catch (error) {
      console.error('文件名解码错误:', error);
      return fileName || '病历文件';
    }
  };

  return (
    <div>
      <Button 
        icon={<ArrowLeftOutlined />} 
        onClick={goBack}
        style={{ marginBottom: '20px' }}
      >
        返回病历列表
      </Button>
      
      <Card>
        <Title level={3}>{record.description}</Title>
        
        <div style={{ margin: '20px 0' }}>
          <Tag color={getRecordTypeInfo(record.recordType).color}>{getRecordTypeInfo(record.recordType).label}</Tag>
          <Text type="secondary" style={{ marginLeft: '10px' }}>
            上传时间: {new Date(record.uploadDate).toLocaleString()}
          </Text>
        </div>
        
        <Divider />

        {record.file && (
          <div style={{ margin: '19px 0' }}>
            <Title level={3}>病历文件</Title>
            <Card>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                {getFileTypeIcon(record.file.mimetype)}
                <Tooltip title={formatFileName(record.file.originalName)}>
                  <Text 
                    style={{ 
                      marginLeft: '9px',
                      maxWidth: '299px',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap'
                    }}
                  >
                    {formatFileName(record.file.originalName)}
                  </Text>
                </Tooltip>
              </div>
              
              <div style={{ marginTop: '19px' }}>
                <div style={{ display: 'flex', gap: '9px' }}>
                  <Button 
                    type="primary" 
                    icon={<EyeOutlined />}
                    onClick={handlePreview}
                  >
                    在线预览
                  </Button>
                  <Button 
                    icon={<DownloadOutlined />}
                    onClick={handleDownload}
                  >
                    下载
                  </Button>
                </div>
              </div>
            </Card>
          </div>
        )}
        
        {/* 修改这部分，不再使用三元运算符，而是分别判断是否显示文本内容和文件 */}
        {record.textContent && (
          <div style={{ margin: '20px 0' }}>
            <Title level={4}>病历内容</Title>
            <Card style={{ background: '#f5f5f5' }}>
              <pre style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
                {record.textContent}
              </pre>
            </Card>
          </div>
        )}    
        
        {!record.textContent && !record.file && (
          <Empty description="无病历内容" />
        )}
      </Card>
      
      <FileViewer
        visible={filePreviewVisible}
        fileUrl={record?.file ? `/api/records/${recordId}/file?userId=${user.id}` : null}
        fileType={record?.file?.mimetype}
        fileName={formatFileName(record?.file?.originalName)}
        onClose={() => setFilePreviewVisible(false)}
      />
    </div>
  );
};

export default RecordDetail;