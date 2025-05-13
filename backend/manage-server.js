/**
 * 服务器管理脚本
 * 用于启动、停止和重启服务器
 */

const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

// 获取环境变量
require('dotenv').config();
const HTTP_PORT = process.env.HTTP_PORT || 5000;
const HTTPS_PORT = process.env.HTTPS_PORT || 5443;

// 检查证书是否存在
const certDir = path.join(__dirname, 'certificates');
const keyPath = path.join(certDir, 'key.pem');
const certPath = path.join(certDir, 'cert.pem');
const hasCertificates = fs.existsSync(keyPath) && fs.existsSync(certPath);

// 命令行参数
const args = process.argv.slice(2);
const command = args[0] || 'help';

/**
 * 查找并终止占用指定端口的进程
 */
function killProcessOnPort(port) {
  return new Promise((resolve, reject) => {
    const isWindows = os.platform() === 'win32';
    const cmd = isWindows
      ? `netstat -ano | findstr :${port}`
      : `lsof -i :${port} | grep LISTEN`;

    exec(cmd, (error, stdout) => {
      if (error) {
        console.log(`没有进程占用端口 ${port}`);
        resolve(false);
        return;
      }

      if (!stdout) {
        console.log(`没有进程占用端口 ${port}`);
        resolve(false);
        return;
      }

      console.log(`发现占用端口 ${port} 的进程:`);
      console.log(stdout);

      // 提取PID
      let pid;
      if (isWindows) {
        const matches = stdout.match(/\s+([0-9]+)\s*$/m);
        pid = matches && matches[1];
      } else {
        const matches = stdout.match(/\s+([0-9]+)\s+/m);
        pid = matches && matches[1];
      }

      if (!pid) {
        console.log(`无法确定占用端口 ${port} 的进程ID`);
        resolve(false);
        return;
      }

      console.log(`正在终止进程 PID: ${pid}...`);
      const killCmd = isWindows ? `taskkill /F /PID ${pid}` : `kill -9 ${pid}`;

      exec(killCmd, (killError) => {
        if (killError) {
          console.error(`无法终止进程 ${pid}: ${killError.message}`);
          resolve(false);
          return;
        }

        console.log(`成功终止进程 PID: ${pid}`);
        resolve(true);
      });
    });
  });
}

/**
 * 启动服务器
 */
async function startServer() {
  console.log('正在启动服务器...');
  
  // 检查端口占用
  await killProcessOnPort(HTTP_PORT);
  if (hasCertificates) {
    await killProcessOnPort(HTTPS_PORT);
  }
  
  // 启动服务器
  const child = exec('npm start', (error) => {
    if (error) {
      console.error(`启动服务器失败: ${error.message}`);
      return;
    }
  });
  
  child.stdout.pipe(process.stdout);
  child.stderr.pipe(process.stderr);
  
  console.log(`服务器启动命令已执行，HTTP端口: ${HTTP_PORT}`);
  if (hasCertificates) {
    console.log(`HTTPS端口: ${HTTPS_PORT}`);
  } else {
    console.log('未找到SSL证书，HTTPS服务器未启动。请运行 node generate-cert.js 生成证书。');
  }
}

/**
 * 停止服务器
 */
async function stopServer() {
  console.log('正在停止服务器...');
  let stopped = false;
  
  // 停止HTTP服务器
  const httpStopped = await killProcessOnPort(HTTP_PORT);
  if (httpStopped) stopped = true;
  
  // 停止HTTPS服务器
  if (hasCertificates) {
    const httpsStopped = await killProcessOnPort(HTTPS_PORT);
    if (httpsStopped) stopped = true;
  }
  
  if (stopped) {
    console.log('服务器已停止');
  } else {
    console.log('没有找到正在运行的服务器进程');
  }
}

/**
 * 重启服务器
 */
async function restartServer() {
  console.log('正在重启服务器...');
  await stopServer();
  await startServer();
}

/**
 * 显示帮助信息
 */
function showHelp() {
  console.log('\n健康顾问系统 - 服务器管理工具\n');
  console.log('用法: node manage-server.js [命令]\n');
  console.log('可用命令:');
  console.log('  start    - 启动服务器');
  console.log('  stop     - 停止服务器');
  console.log('  restart  - 重启服务器');
  console.log('  status   - 检查服务器状态');
  console.log('  help     - 显示此帮助信息\n');
}

/**
 * 检查服务器状态
 */
async function checkStatus() {
  console.log('\n检查服务器状态...');
  
  // 检查HTTP服务器
  const isWindows = os.platform() === 'win32';
  const httpCmd = isWindows
    ? `netstat -ano | findstr :${HTTP_PORT}`
    : `lsof -i :${HTTP_PORT} | grep LISTEN`;
  
  exec(httpCmd, (error, stdout) => {
    if (error || !stdout) {
      console.log(`HTTP服务器 (端口 ${HTTP_PORT}): 未运行`);
    } else {
      console.log(`HTTP服务器 (端口 ${HTTP_PORT}): 运行中`);
    }
    
    // 检查HTTPS服务器
    if (hasCertificates) {
      const httpsCmd = isWindows
        ? `netstat -ano | findstr :${HTTPS_PORT}`
        : `lsof -i :${HTTPS_PORT} | grep LISTEN`;
      
      exec(httpsCmd, (error, stdout) => {
        if (error || !stdout) {
          console.log(`HTTPS服务器 (端口 ${HTTPS_PORT}): 未运行`);
        } else {
          console.log(`HTTPS服务器 (端口 ${HTTPS_PORT}): 运行中`);
        }
        
        console.log('\n证书状态:');
        console.log(`  密钥文件: ${fs.existsSync(keyPath) ? '存在' : '不存在'}`);
        console.log(`  证书文件: ${fs.existsSync(certPath) ? '存在' : '不存在'}`);
        
        console.log('\n提示:');
        console.log('  - 使用 "node manage-server.js start" 启动服务器');
        console.log('  - 使用 "node manage-server.js stop" 停止服务器');
        console.log('  - 使用 "node test-https.js" 测试HTTPS连接');
      });
    } else {
      console.log(`HTTPS服务器: 未配置 (缺少证书文件)`);
      console.log('\n证书状态:');
      console.log(`  密钥文件: ${fs.existsSync(keyPath) ? '存在' : '不存在'}`);
      console.log(`  证书文件: ${fs.existsSync(certPath) ? '存在' : '不存在'}`);
      console.log('\n提示:');
      console.log('  - 使用 "node generate-cert.js" 生成SSL证书');
    }
  });
}

// 执行命令
switch (command) {
  case 'start':
    startServer();
    break;
  case 'stop':
    stopServer();
    break;
  case 'restart':
    restartServer();
    break;
  case 'status':
    checkStatus();
    break;
  case 'help':
  default:
    showHelp();
    break;
}