# 健康顾问系统 - HTTPS 配置指南

本文档提供了如何将后端服务升级为HTTPS的详细步骤，以及如何配置前端应用以连接HTTPS服务器。

## 已完成的更改

1. 服务器代码已更新，支持同时运行HTTP和HTTPS服务器
2. 添加了自动检测证书文件的功能
3. 创建了证书生成脚本
4. 添加了Flutter应用的自签名证书支持

## 配置HTTPS的步骤

### 1. 生成SSL证书

您可以使用以下两种方法之一生成SSL证书：

#### 方法一：使用提供的脚本（推荐）

```bash
node generate-cert.js
```

这将在`certificates`目录中生成自签名证书文件。

#### 方法二：手动使用OpenSSL

```bash
openssl req -x509 -newkey rsa:4096 -keyout ./certificates/key.pem -out ./certificates/cert.pem -days 365 -nodes
```

### 2. 配置环境变量（可选）

在`.env`文件中，您可以自定义HTTP和HTTPS端口：

```
HTTP_PORT=5000
HTTPS_PORT=5443
```

如果不设置，将使用默认值（HTTP: 5000, HTTPS: 5443）。

### 3. 管理服务器

我们提供了服务器管理脚本，可以方便地启动、停止和重启服务器：

```bash
# 启动服务器
node manage-server.js start

# 停止服务器
node manage-server.js stop

# 重启服务器
node manage-server.js restart

# 查看服务器状态
node manage-server.js status
```

服务器将同时在HTTP和HTTPS端口上运行。

### 4. 测试HTTPS连接

使用以下命令测试HTTPS连接是否正常工作：

```bash
node test-https.js
```

这将尝试连接到HTTPS服务器并显示连接状态。

## 注意事项

1. **自签名证书警告**：使用自签名证书时，浏览器会显示安全警告。这在开发环境中是正常的，但在生产环境中应使用受信任的证书。

2. **移动应用连接**：在移动应用中连接HTTPS服务器时，我们已添加了自签名证书支持。在开发环境中，应用会自动信任自签名证书。在生产环境中，应使用受信任的证书。

3. **生产环境**：在生产环境中，建议使用Let's Encrypt等服务获取免费的受信任证书。

## 配置Flutter应用

### 1. 自签名证书支持

我们已经在Flutter应用中添加了自签名证书支持，通过以下步骤实现：

1. 创建了`certificate_helper.dart`工具类，用于处理自签名证书
2. 在`main.dart`中初始化证书帮助类

```dart
// main.dart
import 'utils/certificate_helper.dart';

void main() {
  // 允许自签名证书（开发环境）
  CertificateHelper.allowSelfSignedCertificates();
  
  runApp(const HealthAdvisorApp());
}
```

### 2. 配置API地址

在`api_service.dart`文件中，您需要根据实际环境配置API地址：

```dart
// 开发环境（本地测试）
static const String _baseUrl = 'https://192.168.x.x:5443/api'; // 替换为您的本地IP地址

// 或者使用localhost（模拟器）
// static const String _baseUrl = 'https://10.0.2.2:5443/api'; // Android模拟器
// static const String _baseUrl = 'https://localhost:5443/api'; // iOS模拟器
```

### 3. 生产环境配置

在生产环境中，您应该：

1. 使用受信任的SSL证书
2. 移除`CertificateHelper.allowSelfSignedCertificates()`调用
3. 更新API地址为生产服务器地址

## 故障排除

- **证书生成失败**：确保已安装node-forge依赖（`npm install node-forge`）或OpenSSL并添加到系统PATH中。Windows用户可以从[slproweb.com](https://slproweb.com/products/Win32OpenSSL.html)下载安装OpenSSL。

- **HTTPS服务器未启动**：检查证书文件是否正确生成在`certificates`目录中。

- **连接被拒绝**：确保防火墙允许指定的HTTPS端口（默认5443）。

- **Flutter应用无法连接**：
  - 检查API地址是否正确配置
  - 确认证书帮助类已正确初始化
  - 在真机测试时，确保设备和服务器在同一网络中