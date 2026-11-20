<template>
  <div class="login-wrap">
    <div class="login-box">
      <h2>悬赏平台 · 管理后台</h2>
      <p class="sub">本地开发环境</p>
      <el-form :model="form" @keyup.enter="submit">
        <el-form-item>
          <el-input v-model="form.username" placeholder="账号" size="large" :prefix-icon="User" />
        </el-form-item>
        <el-form-item>
          <el-input
            v-model="form.password"
            type="password"
            placeholder="密码"
            size="large"
            show-password
            :prefix-icon="Lock"
          />
        </el-form-item>
        <el-button type="primary" size="large" style="width: 100%" :loading="loading" @click="submit">
          登 录
        </el-button>
      </el-form>
      <p class="tip">默认账号 admin / admin123</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import request from '@/api/request'

const router = useRouter()
const loading = ref(false)
const form = reactive({ username: 'admin', password: 'admin123' })

async function submit() {
  if (!form.username || !form.password) {
    ElMessage.warning('请输入账号和密码')
    return
  }
  loading.value = true
  try {
    const data: any = await request.post('/auth/login', form)
    localStorage.setItem('admin_token', data.data.token)
    localStorage.setItem('admin_name', data.data.realName || form.username)
    router.push('/dashboard')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrap {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at 30% 20%, #1f2430, #0b0d12 60%);
}
.login-box {
  width: 360px;
  padding: 36px 32px 28px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(20px);
}
h2 {
  color: #f3d9a4;
  margin: 0 0 4px;
  font-size: 20px;
}
.sub {
  color: #6b7280;
  font-size: 12px;
  margin: 0 0 24px;
}
.tip {
  color: #6b7280;
  font-size: 12px;
  text-align: center;
  margin: 16px 0 0;
}
</style>
