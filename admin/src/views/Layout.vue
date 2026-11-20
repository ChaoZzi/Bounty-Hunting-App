<template>
  <el-container style="height: 100%">
    <el-aside width="208px" class="aside">
      <div class="logo">悬赏 · 管理后台</div>
      <el-menu :default-active="route.path" router class="menu" background-color="#12141a" text-color="#a8adb8" active-text-color="#d9b678">
        <el-menu-item index="/dashboard">
          <el-icon><DataLine /></el-icon>
          <span>数据总览</span>
        </el-menu-item>
        <el-menu-item index="/tasks">
          <el-icon><Tickets /></el-icon>
          <span>任务审核</span>
        </el-menu-item>
        <el-menu-item index="/withdraws">
          <el-icon><Wallet /></el-icon>
          <span>提现审核</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <span class="title">{{ route.meta.title || '' }}</span>
        <el-button link @click="logout">退出登录</el-button>
      </el-header>
      <el-main>
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { useRoute, useRouter } from 'vue-router'
import { DataLine, Tickets, Wallet } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()

function logout() {
  localStorage.removeItem('admin_token')
  router.push('/login')
}
</script>

<style scoped>
.aside {
  background: #12141a;
}
.logo {
  height: 60px;
  line-height: 60px;
  text-align: center;
  color: #d9b678;
  font-weight: 600;
  letter-spacing: 1px;
}
.menu {
  border-right: none;
}
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  border-bottom: 1px solid #ebeef5;
}
.title {
  font-weight: 600;
}
</style>
