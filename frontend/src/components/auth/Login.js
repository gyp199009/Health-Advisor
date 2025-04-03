import React, { useState } from 'react';
import { Form, Input, Button, Typography, Card, Divider, message } from 'antd';
import { UserOutlined, LockOutlined, LoginOutlined } from '@ant-design/icons';
import { Link } from 'react-router-dom';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

const { Title, Paragraph } = Typography;

const Login = ({ onLogin }) => {
  const [loading, setLoading] = useState(false);
  const { t } = useTranslation();

  const handleLogin = async (values) => {
    try {
      setLoading(true);
      const response = await axios.post('/api/auth/login', values);
      
      if (response.data && response.data.user) {
        onLogin(response.data.user);
      } else {
        message.error(t('auth.usernameOrPasswordError'));
      }
    } catch (error) {
      console.error('登录错误:', error);
      if (error.response && error.response.status === 401) {
        message.error(t('auth.usernameOrPasswordError'));
      } else {
        message.error(t('auth.loginFailed'));
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '400px', margin: '0 auto', padding: '40px 0' }}>
      <Card className="login-card" bordered={false} style={{ boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}>
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <Title level={2} style={{ color: '#1890ff' }}>{t('app.title')}</Title>
          <Paragraph>{t('auth.loginDescription')}</Paragraph>
        </div>
        
        <Form
          name="login"
          initialValues={{ remember: true }}
          onFinish={handleLogin}
          size="large"
        >
          <Form.Item
            name="username"
            rules={[{ required: true, message: t('auth.usernameRequired') }]}
          >
            <Input 
              prefix={<UserOutlined />} 
              placeholder={t('auth.username')}
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[{ required: true, message: t('auth.passwordRequired') }]}
          >
            <Input.Password
              prefix={<LockOutlined />}
              placeholder={t('auth.password')}
            />
          </Form.Item>

          <Form.Item>
            <Button 
              type="primary" 
              htmlType="submit" 
              block 
              icon={<LoginOutlined />}
              loading={loading}
            >
              {t('auth.login')}
            </Button>
          </Form.Item>
          
          <Divider plain>{t('common.or')}</Divider>
          
          <div style={{ textAlign: 'center' }}>
            <Link to="/register">{t('auth.register')}</Link>
          </div>
        </Form>
      </Card>
    </div>
  );
};

export default Login;