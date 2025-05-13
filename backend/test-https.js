/**
 * HTTPS连接测试脚本
 * 用于测试HTTPS服务器是否正常工作
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// 证书目录
const certDir = path.join(__dirname, 'certificates');
const certPath = path.join(certDir, 'cert.pem');

// 检查证书是否存在
if (!fs.existsSync(certPath)) {
  console.log('错误：未找到证书文件。请先运行 node generate-cert.js 生成证书。');
  process.exit(1);
}

// 获取HTTPS端口
require('dotenv').config();
const HTTPS_PORT = process.env.HTTPS_PORT || 5443;

// 创建HTTPS请求选项
const options = {
  hostname: 'localhost',
  port: HTTPS_PORT,
  path: '/api',
  method: 'GET',
  rejectUnauthorized: false // 允许自签名证书（仅用于测试）
};

console.log(`正在测试HTTPS连接 (https://localhost:${HTTPS_PORT}/api)...`);

// 发送HTTPS请求
const req = https.request(options, (res) => {
  console.log(`状态码: ${res.statusCode}`);
  
  if (res.statusCode === 200 || res.statusCode === 404) {
    console.log('✅ HTTPS服务器工作正常！');
    console.log('\n提示：');
    console.log('1. 在浏览器中访问 https://localhost:5443 测试Web界面');
    console.log('2. 在Flutter应用中使用以下API地址:');
    console.log(`   - 本机测试: https://localhost:${HTTPS_PORT}/api`);
    console.log(`   - 模拟器测试: https://10.0.2.2:${HTTPS_PORT}/api (Android)`);
    console.log(`   - 真机测试: https://<您的本地IP>:${HTTPS_PORT}/api`);
  } else {
    console.log('❌ HTTPS服务器返回了非预期的状态码');
  }
});

req.on('error', (e) => {
  console.error('❌ HTTPS连接失败:', e.message);
  console.log('\n可能的原因:');
  console.log('1. 服务器未启动');
  console.log('2. 端口被占用');
  console.log('3. 证书配置错误');
  console.log('\n请尝试:');
  console.log('1. 确保服务器已启动: npm start');
  console.log('2. 检查端口是否被占用，可以在.env文件中修改端口');
  console.log('3. 重新生成证书: node generate-cert.js (先删除旧证书)');
});

req.end();