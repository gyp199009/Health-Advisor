import React, { useState } from 'react';
import { Form, Input, Button, Typography, Card, Divider, message } from 'antd';
import { UserOutlined, LockOutlined, MailOutlined, PhoneOutlined, UserAddOutlined } from '@ant-design/icons';
import { Link, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useTranslation } from 'react-i18next';

const { Title, Paragraph } = Typography;

const Register = () => {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { t } = useTranslation();

  const handleRegister = async (values) => {
    if (values.password !== values.confirmPassword) {
      message.error(t('auth.passwordNotMatch'));
      return;
    }

    try {
      setLoading(true);
      const response = await axios.post('/api/auth/register', {
        username: values.username,
        password: values.password,
        email: values.email,
        phone: values.phone
      });
      
      message.success(t('auth.registerSuccess'));
      navigate('/login');
    } catch (error) {
      console.error('注册错误:', error);
      if (error.response && error.response.status === 409) {
        message.error(t('auth.userExists'));
      } else {
        message.error(t('auth.registerFailed'));
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '400px', margin: '0 auto', padding: '40px 0' }}>
      <Card className="register-card" bordered={false} style={{ boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}>
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <Title level={2} style={{ color: '#1890ff' }}>{t('auth.register')}</Title>
          <Paragraph>{t('auth.registerDescription')}</Paragraph>
        </div>
        
        <Form
          name="register"
          onFinish={handleRegister}
          size="large"
          scrollToFirstError
        >
          <Form.Item
            name="username"
            rules={[
              { required: true, message: t('auth.usernameRequired') },
              { min: 3, message: t('auth.usernameMinLength') }
            ]}
          >
            <Input 
              prefix={<UserOutlined />} 
              placeholder={t('auth.username')}
            />
          </Form.Item>

          <Form.Item
            name="password"
            rules={[
              { required: true, message: t('auth.passwordRequired') },
              { min: 6, message: t('auth.passwordMinLength') }
            ]}
          >
            <Input.Password
              prefix={<LockOutlined />}
              placeholder={t('auth.password')}
            />
          </Form.Item>

          <Form.Item
            name="confirmPassword"
            rules={[
              { required: true, message: t('auth.confirmPasswordRequired') },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('password') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error(t('auth.passwordNotMatch')));
                },
              }),
            ]}
          >
            <Input.Password
              prefix={<LockOutlined />}
              placeholder={t('auth.confirmPassword')}
            />
          </Form.Item>

          <Form.Item
            name="email"
            rules={[
              { required: true, message: t('auth.emailRequired') },
              { type: 'email', message: t('auth.invalidEmail') }
            ]}
          >
            <Input 
              prefix={<MailOutlined />} 
              placeholder={t('auth.email')}
            />
          </Form.Item>

          <Form.Item
            name="phone"
            rules={[
              { required: true, message: t('auth.phoneRequired') },
              { pattern: /^1[3-9]\d{9}$/, message: t('auth.invalidPhone') }
            ]}
          >
            <Input 
              prefix={<PhoneOutlined />} 
              placeholder={t('auth.phone')}
            />
          </Form.Item>

          <Form.Item>
            <Button 
              type="primary" 
              htmlType="submit" 
              block 
              icon={<UserAddOutlined />}
              loading={loading}
            >
              {t('auth.register')}
            </Button>
          </Form.Item>
          
          <Divider plain>{t('common.or')}</Divider>
          
          <div style={{ textAlign: 'center' }}>
            <Link to="/login">{t('auth.haveAccount')}</Link>
          </div>
        </Form>
      </Card>
    </div>
  );
};

export default Register;