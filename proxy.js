const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();

// const API_TARGET = 'http://72.60.83.197:7000/';
const API_TARGET = 'http://localhost:7000/';

// فعل CORS لكل الطلبات
app.use(cors({
  origin: '*',
  methods: ['GET','POST','PUT','DELETE','OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// لو عايز explicit handling للـ OPTIONS requests
app.options(/.*/, cors());

// استخدم البروكسي
app.use('/api', createProxyMiddleware({
  target: API_TARGET,
  changeOrigin: true,
  pathRewrite: { '^/api': '' },
}));

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Proxy server running on http://localhost:${PORT}/api`);
});
