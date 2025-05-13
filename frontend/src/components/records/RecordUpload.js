import React, { useState } from 'react';
import { Form, Input, Button, Upload, Select, Typography, message, Card, Space, Divider } from 'antd';
import { UploadOutlined, InboxOutlined, FileTextOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';

const { Title, Paragraph, Text } = Typography;
const { TextArea } = Input;
const { Option } = Select;

const RecordUpload = ({ user }) => {
  const [form] = Form.useForm();
  const [fileList, setFileList] = useState([]);
  const [uploading, setUploading] = useState(false);
  const [uploadType, setUploadType] = useState('file'); // 'file' 或 'text'
  const navigate = useNavigate();

  // 处理文件上传
  const handleFileUpload = async (values) => {
    if (fileList.length === 0 && uploadType === 'file') {
      message.error('请选择要上传的文件');
      return;
    }

    try {
      setUploading(true);
      
      if (uploadType === 'file') {
        // 文件上传
        const formData = new FormData();
        const file = fileList[0].originFileObj || fileList[0];
        
        // 创建一个新的File对象，保留原始文件名的编码
        const originalFile = file;
        const renamedFile = new File([originalFile], encodeURIComponent(originalFile.name), {
          type: originalFile.type
        });
        
        formData.append('file', renamedFile);
        formData.append('userId', user.id);
        formData.append('recordType', values.recordType);
        formData.append('description', values.description);
        formData.append('originalFileName', originalFile.name); // 添加原始文件名作为单独的字段
        
        const response = await axios.post('/api/records/upload', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        });
        
        if (response.data && response.data.record) {
          message.success('病历上传成功');
          navigate('/records');
        }
      } else {
        // 文本记录
        if (!values.textContent || !values.textContent.trim()) {
          message.error('请输入病历内容');
          setUploading(false);
          return;
        }
        
        const response = await axios.post('/api/records/upload', {
          userId: user.id,
          recordType: values.recordType,
          description: values.description,
          textContent: values.textContent
        });
        
        if (response.data && response.data.record) {
          message.success('病历记录添加成功');
          navigate('/records');
        }
      }
    } catch (error) {
      console.error('上传病历错误:', error);
      const errorMessage = error.response?.data?.message || error.response?.data?.error || '上传病历失败，请稍后再试';
      message.error(errorMessage);
    } finally {
      setUploading(false);
    }
  };

  // 文件上传前的验证
  const beforeUpload = (file) => {
    const isValidType = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'image/jpg',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain'
    ].includes(file.type);
    
    if (!isValidType) {
      message.error('只能上传PDF、图片、Word或文本文件!');
    }
    
    const isLt10M = file.size / 1024 / 1024 < 10;
    if (!isLt10M) {
      message.error('文件大小不能超过10MB!');
    }
    
    if (isValidType && isLt10M) {
      setFileList([file]);
    }
    
    return false; // 阻止自动上传
  };

  // 文件列表变化
  const handleChange = ({ fileList }) => {
    setFileList(fileList);
  };

  // 切换上传类型
  const handleUploadTypeChange = (type) => {
    setUploadType(type);
    setFileList([]);
    form.resetFields(['textContent']);
  };

  return (
    <div>
      <Title level={3}>上传病历</Title>
      <Paragraph>上传您的病历记录，以便AI健康顾问能够提供更准确的健康建议。</Paragraph>
      
      <Card style={{ marginTop: '20px' }}>
        <div style={{ marginBottom: '20px' }}>
          <Text strong>选择上传方式：</Text>
          <Space style={{ marginLeft: '10px' }}>
            <Button 
              type={uploadType === 'file' ? 'primary' : 'default'}
              icon={<UploadOutlined />}
              onClick={() => handleUploadTypeChange('file')}
            >
              上传文件
            </Button>
            <Button 
              type={uploadType === 'text' ? 'primary' : 'default'}
              icon={<FileTextOutlined />}
              onClick={() => handleUploadTypeChange('text')}
            >
              文本记录
            </Button>
          </Space>
        </div>
        
        <Divider />
        
        <Form
          form={form}
          layout="vertical"
          onFinish={handleFileUpload}
          initialValues={{
            recordType: 'exam_report'
          }}
        >
          <Form.Item
            name="recordType"
            label="病历类型"
            rules={[{ required: true, message: '请选择病历类型' }]}
          >
            <Select>
              <Option value="exam_report">检查报告</Option>
              <Option value="diagnosis">诊断证明</Option>
              <Option value="medication">处方</Option>
              <Option value="case_summary">病例摘要</Option>
              <Option value="surgery_record">手术记录</Option>
              <Option value="other">其他</Option>
            </Select>
          </Form.Item>
          
          <Form.Item
            name="description"
            label="描述"
            rules={[{ required: true, message: '请输入病历描述' }]}
          >
            <Input placeholder="请简要描述此病历记录，如：2023年6月血常规检查" />
          </Form.Item>
          
          {uploadType === 'file' ? (
            <Form.Item label="上传文件">
              <Upload
                name="file"
                beforeUpload={beforeUpload}
                onChange={handleChange}
                fileList={fileList}
                maxCount={1}
              >
                <Button icon={<UploadOutlined />}>选择文件</Button>
                <Text type="secondary" style={{ marginLeft: '10px' }}>
                  支持PDF、图片、Word和文本文件，大小不超过10MB
                </Text>
              </Upload>
            </Form.Item>
          ) : (
            <Form.Item
              name="textContent"
              label="病历内容"
            >
              <TextArea 
                placeholder="请输入病历内容..."
                autoSize={{ minRows: 6, maxRows: 12 }}
              />
            </Form.Item>
          )}
          
          <Form.Item>
            <Button type="primary" htmlType="submit" loading={uploading}>
              {uploadType === 'file' ? '上传病历' : '保存记录'}
            </Button>
            <Button 
              style={{ marginLeft: '10px' }} 
              onClick={() => navigate('/records')}
            >
              取消
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
};

export default RecordUpload;