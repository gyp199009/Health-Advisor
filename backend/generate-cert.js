/**
 * 生成自签名SSL证书的脚本
 * 运行方式: node generate-cert.js
 */

const fs = require('fs');
const path = require('path');

// 证书存放目录
const certDir = path.join(__dirname, 'certificates');

// 确保证书目录存在
if (!fs.existsSync(certDir)) {
  fs.mkdirSync(certDir, { recursive: true });
  console.log(`创建证书目录: ${certDir}`);
}

// 证书文件路径
const keyPath = path.join(certDir, 'key.pem');
const certPath = path.join(certDir, 'cert.pem');

// 检查证书是否已存在
if (fs.existsSync(keyPath) && fs.existsSync(certPath)) {
  console.log('证书文件已存在。如需重新生成，请先删除现有证书文件。');
  process.exit(0);
}

console.log('开始生成自签名SSL证书...');

try {
  // 使用Node.js内置模块生成自签名证书
  const forge = require('node-forge');
  
  // 生成RSA密钥对
  console.log('生成RSA密钥对...');
  const keys = forge.pki.rsa.generateKeyPair(2048);
  
  // 创建证书
  console.log('创建X.509证书...');
  const cert = forge.pki.createCertificate();
  cert.publicKey = keys.publicKey;
  cert.serialNumber = '01';
  cert.validity.notBefore = new Date();
  cert.validity.notAfter = new Date();
  cert.validity.notAfter.setFullYear(cert.validity.notBefore.getFullYear() + 1); // 1年有效期
  
  // 设置证书主题和颁发者信息
  const attrs = [
    { name: 'commonName', value: 'localhost' },
    { name: 'organizationName', value: 'Health Advisor Development' },
    { name: 'organizationalUnitName', value: 'Development' },
    { name: 'localityName', value: 'Local' },
    { name: 'countryName', value: 'CN' },
    { shortName: 'ST', value: 'State' }
  ];
  
  cert.setSubject(attrs);
  cert.setIssuer(attrs); // 自签名证书，颁发者和主题相同
  
  // 设置证书扩展
  cert.setExtensions([
    {
      name: 'basicConstraints',
      cA: false
    },
    {
      name: 'keyUsage',
      digitalSignature: true,
      keyEncipherment: true,
      dataEncipherment: true
    },
    {
      name: 'extKeyUsage',
      serverAuth: true,
      clientAuth: true
    },
    {
      name: 'subjectAltName',
      altNames: [
        {
          type: 2, // DNS
          value: 'localhost'
        },
        {
          type: 7, // IP
          ip: '127.0.0.1'
        }
      ]
    }
  ]);
  
  // 使用私钥签名证书
  cert.sign(keys.privateKey, forge.md.sha256.create());
  
  // 转换为PEM格式
  const privateKeyPem = forge.pki.privateKeyToPem(keys.privateKey);
  const certPem = forge.pki.certificateToPem(cert);
  
  // 将私钥和证书写入文件
  fs.writeFileSync(keyPath, privateKeyPem);
  fs.writeFileSync(certPath, certPem);
  
  console.log('\n证书生成成功！');
  console.log(`密钥文件: ${keyPath}`);
  console.log(`证书文件: ${certPath}`);
  console.log('\n现在可以启动服务器，将自动启用HTTPS。');
  console.log('\n注意：这是一个自签名证书，仅用于开发测试。');
  console.log('在生产环境中，请使用正规的SSL证书。');
} catch (error) {
  console.error('生成证书时出错:', error.message);
  console.log('\n请确保已安装所需的依赖：npm install node-forge');
}