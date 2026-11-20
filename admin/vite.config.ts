import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  // 打包产物由后端托管在 /admin-ui/ 下，资源路径必须带这个前缀
  base: '/admin-ui/',
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 5173,
    host: '0.0.0.0',
    proxy: {
      '/admin': {
        target: 'http://127.0.0.1:8080',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    // 本机 esbuild 临时文件清理被占用时会报错，跳过降级与压缩（本地后台无需极致体积）
    target: 'esnext',
    minify: false
  }
})
