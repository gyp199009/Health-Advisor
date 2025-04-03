import React from 'react';
import { Layout, Menu } from 'antd';
import { DashboardOutlined, MessageOutlined, FileTextOutlined, SettingOutlined } from '@ant-design/icons';
import { useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const { Sider } = Layout;

const Sidebar = ({ collapsed, darkMode }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const { t } = useTranslation();
  
  // 获取当前路径的第一段作为选中的菜单项
  const selectedKey = '/' + (location.pathname.split('/')[1] || 'dashboard');

  // 菜单项配置
  const menuItems = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: t('nav.dashboard'),
      onClick: () => navigate('/dashboard')
    },
    {
      key: '/chat',
      icon: <MessageOutlined />,
      label: t('nav.chat'),
      onClick: () => navigate('/chat')
    },
    {
      key: '/records',
      icon: <FileTextOutlined />,
      label: t('nav.records'),
      onClick: () => navigate('/records')
    },
    {
      key: '/settings',
      icon: <SettingOutlined />,
      label: t('nav.settings'),
      onClick: () => navigate('/settings')
    }
  ];

  return (
    <Sider 
      trigger={null} 
      collapsible 
      collapsed={collapsed}
      theme={darkMode ? 'dark' : 'light'}
      style={{ 
        overflow: 'auto',
        height: '100vh',
        position: 'sticky',
        top: 0,
        left: 0
      }}
    >
      <div className="logo" style={{ 
        height: '64px', 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center',
        color: darkMode ? '#fff' : '#1890ff',
        fontWeight: 'bold',
        fontSize: collapsed ? '16px' : '18px'
      }}>
        {/* {collapsed ? 'HA' : t('app.title')} */}
      </div>
      <Menu
        theme={darkMode ? 'dark' : 'light'}
        mode="inline"
        selectedKeys={[selectedKey]}
        items={menuItems}
      />
    </Sider>
  );
};

export default Sidebar;