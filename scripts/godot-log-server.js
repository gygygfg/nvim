#!/usr/bin/env node
/**
 * Godot Web 日志服务器
 * 
 * 功能：
 * 1. 提供静态文件服务（替代 http-server）
 * 2. 提供 POST /log 端点，接收浏览器端发来的 console 日志
 * 3. 收到的日志实时输出到 stdout，供 Neovim 悬浮窗捕获显示
 * 
 * 使用方式（由 GodotExportWeb 命令自动启动）：
 *   node godot-log-server.js <静态文件目录> <端口>
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const serveDir = process.argv[2] || '.';
const port = parseInt(process.argv[3], 10) || 8080;

// MIME 类型映射
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.pck': 'application/octet-stream',
};

function getMimeType(ext) {
  return MIME_TYPES[ext] || 'application/octet-stream';
}

const server = http.createServer((req, res) => {
  // ========== CORS 头 ==========
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // ========== POST /log — 接收浏览器日志 ==========
  if (req.method === 'POST' && req.url === '/log') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const data = JSON.parse(body);
        const level = data.level || 'log';
        const msg = data.message || '';
        const timestamp = new Date().toLocaleTimeString();

        // 格式化日志行，添加时间戳和级别前缀
        const formatted = `[${timestamp}] [${level.toUpperCase()}] ${msg}`;
        
        // 写入 stdout（Neovim 的 job 会捕获此输出）
        process.stdout.write(formatted + '\n');

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok' }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'error', message: e.message }));
      }
    });
    return;
  }

  // ========== GET — 静态文件服务 ==========
  let filePath = req.url === '/' ? '/index.html' : req.url;
  // URL 解码并规范化
  filePath = path.normalize(path.join(serveDir, decodeURIComponent(filePath)));

  // 安全检查：确保不跳出 serveDir
  if (!filePath.startsWith(path.resolve(serveDir))) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404);
        res.end('Not Found');
      } else {
        res.writeHead(500);
        res.end('Internal Server Error');
      }
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const mimeType = getMimeType(ext);
    res.writeHead(200, { 'Content-Type': mimeType });
    res.end(data);
  });
});

server.listen(port, '0.0.0.0', () => {
  console.log(`[Godot Log Server] 服务已启动: http://localhost:${port}`);
  console.log(`[Godot Log Server] 静态文件目录: ${path.resolve(serveDir)}`);
  console.log(`[Godot Log Server] 游戏运行时 print() 日志将自动显示在此窗口`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
});
