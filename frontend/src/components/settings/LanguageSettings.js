import React from 'react';
import { Card, Radio, Typography, Space } from 'antd';
import { GlobalOutlined } from '@ant-design/icons';
import { useTranslation } from 'react-i18next';

const { Title, Paragraph } = Typography;

const LanguageSettings = () => {
  const { t, i18n } = useTranslation();
  
  const handleLanguageChange = (e) => {
    const lang = e.target.value;
    i18n.changeLanguage(lang);
    localStorage.setItem('i18nextLng', lang);
  };

  return (
    <Card title={<><GlobalOutlined /> {t('settings.language')}</>} style={{ marginBottom: 24 }}>
      <Paragraph>{t('settings.language')}</Paragraph>
      
      <Radio.Group 
        value={i18n.language} 
        onChange={handleLanguageChange}
        style={{ marginTop: 16 }}
      >
        <Space direction="vertical">
          <Radio value="zh">{t('settings.languageOptions.zh')}</Radio>
          <Radio value="en">{t('settings.languageOptions.en')}</Radio>
        </Space>
      </Radio.Group>
    </Card>
  );
};

export default LanguageSettings;