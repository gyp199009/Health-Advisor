import React, { useState } from 'react';
import { Card, Form, Input, Button, Switch, Divider, Typography, message, Tabs, Avatar, Upload, Radio } from 'antd';
import { UserOutlined, LockOutlined, MailOutlined, UploadOutlined, SaveOutlined, GlobalOutlined } from '@ant-design/icons';
import axios from 'axios';
import { useTranslation } from 'react-i18next';
import LanguageSettings from './LanguageSettings';

const { Title, Paragraph } = Typography;
const { TabPane } = Tabs;

const Settings = ({ user, setUser, darkMode, toggleDarkMode }) => {
  const { t } = useTranslation();
  const [profileForm] = Form.useForm();
  const [passwordForm] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const [avatarUrl, setAvatarUrl] = useState(user.avatarUrl || '');

  // 初始化表单数据
  React.useEffect(() => {
    profileForm.setFieldsValue({
      username: user.username,
      email: user.email,
      phone: user.phone || '',
      fullName: user.fullName || ''
    });
  }, [user, profileForm]);

  // 更新个人资料
  const handleUpdateProfile = async (values) => {
    try {
      setLoading(true);
      const response = await axios.put(`/api/users/${user.id}`, {
        ...values,
        avatarUrl
      });
      
      if (response.data && response.data.user) {
        // 更新本地用户数据
        const updatedUser = { ...user, ...response.data.user };
        setUser(updatedUser);
        localStorage.setItem('user', JSON.stringify(updatedUser));
        
        message.success('个人资料已更新');
      }
    } catch (error) {
      console.error('更新个人资料错误:', error);
      message.error('更新个人资料失败，请稍后再试');
    } finally {
      setLoading(false);
    }
  };

  // 修改密码
  const handleChangePassword = async (values) => {
    try {
      setLoading(true);
      const response = await axios.put(`/api/users/${user.id}/password`, {
        currentPassword: values.currentPassword,
        newPassword: values.newPassword
      });
      
      if (response.data && response.data.success) {
        message.success('密码已成功修改');
        passwordForm.resetFields();
      }
    } catch (error) {
      console.error('修改密码错误:', error);
      message.error('修改密码失败，请确认当前密码是否正确');
    } finally {
      setLoading(false);
    }
  };

  // 头像上传前处理
  const beforeUpload = (file) => {
    const isJpgOrPng = file.type === 'image/jpeg' || file.type === 'image/png';
    if (!isJpgOrPng) {
      message.error('只能上传JPG/PNG格式的图片!');
    }
    const isLt2M = file.size / 1024 / 1024 < 2;
    if (!isLt2M) {
      message.error('图片大小不能超过2MB!');
    }
    return isJpgOrPng && isLt2M;
  };

  // 头像上传
  const handleAvatarUpload = async (info) => {
    if (info.file.status === 'uploading') {
      return;
    }
    if (info.file.status === 'done') {
      // 获取上传后的URL
      setAvatarUrl(info.file.response.url);
      message.success('头像上传成功');
    }
  };

  return (
    <div>
      <Title level={2}>{t('settings.title')}</Title>
      <Paragraph>{t('common.loading')}</Paragraph>
      
      <Tabs defaultActiveKey="profile">
        <TabPane tab={t('settings.profile')} key="profile">
          <Card>
            <div style={{ display: 'flex', marginBottom: '24px' }}>
              <Avatar 
                size={64} 
                icon={<UserOutlined />} 
                src={avatarUrl}
                style={{ marginRight: '16px' }}
              />
              <Upload
                name="avatar"
                action="/api/users/avatar"
                beforeUpload={beforeUpload}
                onChange={handleAvatarUpload}
                showUploadList={false}
              >
                <Button icon={<UploadOutlined />}>更换头像</Button>
              </Upload>
            </div>
            
            <Form
              form={profileForm}
              layout="vertical"
              onFinish={handleUpdateProfile}
            >
              <Form.Item
                name="username"
                label={t('auth.username')}
                rules={[{ required: true, message: '请输入用户名' }]}
              >
                <Input prefix={<UserOutlined />} placeholder={t('auth.username')} />
              </Form.Item>
              
              <Form.Item
                name="email"
                label={t('auth.email')}
                rules={[
                  { required: true, message: '请输入邮箱' },
                  { type: 'email', message: '请输入有效的邮箱地址' }
                ]}
              >
                <Input prefix={<MailOutlined />} placeholder={t('auth.email')} />
              </Form.Item>
              
              <Form.Item
                name="fullName"
                label={t('auth.fullName')}
              >
                <Input placeholder={t('auth.fullName')} />
              </Form.Item>
              
              <Form.Item
                name="phone"
                label={t('auth.phone')}
              >
                <Input placeholder={t('auth.phone')} />
              </Form.Item>
              
              <Form.Item>
                <Button 
                  type="primary" 
                  htmlType="submit" 
                  loading={loading}
                  icon={<SaveOutlined />}
                >
                  {t('settings.save')}
                </Button>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>
        
        <TabPane tab={t('settings.account')} key="security">
          <Card>
            <Title level={4}>{t('settings.changePassword')}</Title>
            <Form
              form={passwordForm}
              layout="vertical"
              onFinish={handleChangePassword}
            >
              <Form.Item
                name="currentPassword"
                label={t('settings.currentPassword')}
                rules={[{ required: true, message: '请输入当前密码' }]}
              >
                <Input.Password prefix={<LockOutlined />} placeholder={t('settings.currentPassword')} />
              </Form.Item>
              
              <Form.Item
                name="newPassword"
                label={t('settings.newPassword')}
                rules={[
                  { required: true, message: '请输入新密码' },
                  { min: 6, message: '密码长度不能少于6个字符' }
                ]}
              >
                <Input.Password prefix={<LockOutlined />} placeholder={t('settings.newPassword')} />
              </Form.Item>
              
              <Form.Item
                name="confirmPassword"
                label={t('settings.confirmPassword')}
                dependencies={['newPassword']}
                rules={[
                  { required: true, message: '请确认新密码' },
                  ({ getFieldValue }) => ({
                    validator(_, value) {
                      if (!value || getFieldValue('newPassword') === value) {
                        return Promise.resolve();
                      }
                      return Promise.reject(new Error('两次输入的密码不一致'));
                    },
                  }),
                ]}
              >
                <Input.Password prefix={<LockOutlined />} placeholder={t('settings.confirmPassword')} />
              </Form.Item>
              
              <Form.Item>
                <Button 
                  type="primary" 
                  htmlType="submit" 
                  loading={loading}
                >
                  {t('settings.changePassword')}
                </Button>
              </Form.Item>
            </Form>
          </Card>
        </TabPane>
        
        <TabPane tab={t('settings.appearance')} key="preferences">
          <Card>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <Title level={4}>{t('settings.darkMode')}</Title>
                <Paragraph>{t('settings.appearance')}</Paragraph>
              </div>
              <Switch 
                checked={darkMode} 
                onChange={toggleDarkMode} 
                checkedChildren="开" 
                unCheckedChildren="关" 
              />
            </div>
            
            <Divider />
            
            {/* 可以添加更多偏好设置选项 */}
          </Card>
        </TabPane>
        <TabPane tab={t('settings.language')} key="language">
          <LanguageSettings />
        </TabPane>
      </Tabs>
    </div>
  );
};

export default Settings;