import React, { useState, useEffect } from 'react';
import { Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { Layout, ConfigProvider, theme, message } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import enUS from 'antd/locale/en_US';
import { useTranslation } from 'react-i18next';
import './i18n';
import './App.css';

// 组件导入
import Login from './components/auth/Login';
import Register from './components/auth/Register';
import Dashboard from './components/dashboard/Dashboard';
import Navbar from './components/layout/Navbar';
import Sidebar from './components/layout/Sidebar';
import RecordsList from './components/records/RecordsList';
import RecordUpload from './components/records/RecordUpload';
import RecordDetail from './components/records/RecordDetail';
import ChatList from './components/chat/ChatList';
import ChatWindow from './components/chat/ChatWindow';
import Settings from './components/settings/Settings';
import NotFound from './components/common/NotFound';

const { Content } = Layout;

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [collapsed, setCollapsed] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();

  // 检查用户是否已登录
  useEffect(() => {
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      try {
        setUser(JSON.parse(storedUser));
      } catch (error) {
        console.error('解析用户数据错误:', error);
        localStorage.removeItem('user');
      }
    }
    setLoading(false);
  }, []);

  // 处理登录
  const handleLogin = (userData) => {
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
    message.success(t('auth.loginSuccess'));
    navigate('/dashboard');
  };

  // 处理注销
  const handleLogout = () => {
    setUser(null);
    localStorage.removeItem('user');
    message.success(t('auth.logoutSuccess'));
    navigate('/login');
  };

  // 切换侧边栏
  const toggleSidebar = () => {
    setCollapsed(!collapsed);
  };

  // 切换暗黑模式
  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
  };

  // 受保护的路由组件
  const ProtectedRoute = ({ children }) => {
    if (loading) return <div>{t('app.loading')}</div>;
    if (!user) return <Navigate to="/login" />;
    return children;
  };

  // 根据当前语言选择Ant Design的语言包
  const getAntdLocale = () => {
    return i18n.language === 'en' ? enUS : zhCN;
  };

  return (
    <ConfigProvider
      locale={getAntdLocale()}
      theme={{
        algorithm: darkMode ? theme.darkAlgorithm : theme.defaultAlgorithm,
        token: {
          colorPrimary: '#1890ff',
        },
      }}
    >
      <Layout style={{ minHeight: '100vh' }}>
        {user && (
          <>
            <Navbar user={user} onLogout={handleLogout} toggleSidebar={toggleSidebar} />
            <Layout>
              <Sidebar collapsed={collapsed} darkMode={darkMode} />
              <Layout style={{ padding: '0 24px 24px' }}>
                <Content
                  style={{
                    margin: '24px 16px',
                    padding: 24,
                    minHeight: 280,
                    background: darkMode ? '#141414' : '#fff',
                    borderRadius: '4px',
                  }}
                >
                  <Routes>
                    <Route path="/" element={<Navigate to="/dashboard" />} />
                    <Route
                      path="/dashboard"
                      element={
                        <ProtectedRoute>
                          <Dashboard user={user} />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/records"
                      element={
                        <ProtectedRoute>
                          <RecordsList user={user} />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/records/upload"
                      element={
                        <ProtectedRoute>
                          <RecordUpload user={user} />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/records/:recordId"
                      element={
                        <ProtectedRoute>
                          <RecordDetail user={user} />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/chat"
                      element={
                        <ProtectedRoute>
                          <ChatList user={user} />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/chat/:conversationId"
                      element={
                        <ProtectedRoute>
                          <ChatWindow user={user} />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="/settings"
                      element={
                        <ProtectedRoute>
                          <Settings 
                            user={user} 
                            setUser={setUser} 
                            darkMode={darkMode} 
                            toggleDarkMode={toggleDarkMode} 
                          />
                        </ProtectedRoute>
                      }
                    />
                    <Route path="*" element={<NotFound />} />
                  </Routes>
                </Content>
              </Layout>
            </Layout>
          </>
        )}

        {loading ? (
          <Content style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh' }}>
            <div>{t('app.loading')}</div>
          </Content>
        ) : !user && (
          <Content style={{ padding: '50px 50px', maxWidth: '1200px', margin: '0 auto' }}>
            <Routes>
              <Route path="/" element={<Navigate to="/login" />} />
              <Route path="/login" element={<Login onLogin={handleLogin} />} />
              <Route path="/register" element={<Register />} />
              <Route path="*" element={<Navigate to="/login" />} />
            </Routes>
          </Content>
        )}
      </Layout>
    </ConfigProvider>
  );
}

export default App;