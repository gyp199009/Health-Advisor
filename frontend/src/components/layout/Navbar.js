import React from 'react';
import { Layout, Menu, Button, Avatar, Dropdown, Space, Typography } from 'antd';
import { MenuFoldOutlined, MenuUnfoldOutlined, UserOutlined, LogoutOutlined, SettingOutlined, GlobalOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const { Header } = Layout;
const { Text } = Typography;

const Navbar = ({ user, onLogout, toggleSidebar, collapsed }) => {
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();

  // 用户下拉菜单项
  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: t('nav.profile'),
      onClick: () => navigate('/settings')
    },
    {
      key: 'settings',
      icon: <SettingOutlined />,
      label: t('nav.settings'),
      onClick: () => navigate('/settings')
    },
    {
      type: 'divider'
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: t('auth.logout'),
      onClick: onLogout
    }
  ];
  
  // 语言切换菜单项
  const languageMenuItems = [
    {
      key: 'zh',
      label: '中文',
      onClick: () => {
        i18n.changeLanguage('zh');
        localStorage.setItem('i18nextLng', 'zh');
      }
    },
    {
      key: 'en',
      label: 'English',
      onClick: () => {
        i18n.changeLanguage('en');
        localStorage.setItem('i18nextLng', 'en');
      }
    }
  ];

  return (
    <Header style={{ 
      padding: '0 16px', 
      background: '#fff', 
      boxShadow: '0 1px 4px rgba(0,21,41,.08)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }}>
      <div style={{ display: 'flex', alignItems: 'center' }}>
        <Button
          type="text"
          icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
          onClick={toggleSidebar}
          style={{ fontSize: '16px', width: 64, height: 64 }}
        />
        <div className="logo" style={{ marginLeft: '16px' }}>
          <Text strong style={{ fontSize: '18px', color: '#1890ff' }}>{t('app.title')}</Text>
        </div>
      </div>
      
      <div style={{ display: 'flex', alignItems: 'center' }}>
        <Dropdown menu={{ items: languageMenuItems }} placement="bottomRight">
          <Button type="text" icon={<GlobalOutlined />} style={{ marginRight: 16 }} />
        </Dropdown>
        <Dropdown menu={{ items: userMenuItems }} placement="bottomRight">
          <Space style={{ cursor: 'pointer' }}>
            <Avatar icon={<UserOutlined />} />
            <span>{user?.username || '用户'}</span>
          </Space>
        </Dropdown>
      </div>
    </Header>
  );
};

export default Navbar;