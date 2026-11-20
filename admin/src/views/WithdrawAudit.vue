<template>
  <div class="page-card">
    <div class="toolbar">
      <el-button @click="load">刷新</el-button>
      <span style="color: #909399; font-size: 13px">
        共 {{ total }} 条 · 提现需人工审核后放款
      </span>
    </div>

    <el-table :data="list" v-loading="loading" size="default">
      <el-table-column prop="withdrawNo" label="提现单号" width="200" />
      <el-table-column prop="userId" label="用户" width="90" />
      <el-table-column prop="amount" label="申请金额" width="110" />
      <el-table-column prop="account" label="收款账号" min-width="180" />
      <el-table-column prop="accountName" label="姓名" width="100" />
      <el-table-column prop="createdAt" label="申请时间" width="170" />
      <el-table-column label="状态" width="110">
        <template #default="{ row }">
          <el-tag :type="row.status === 0 ? 'warning' : 'success'" size="small">
            {{ row.status === 0 ? '待审核' : '已完成' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{ row }">
          <el-button size="small" type="primary" :disabled="row.status !== 0" @click="pay(row)">
            放款
          </el-button>
          <el-button size="small" type="danger" plain :disabled="row.status !== 0" @click="reject(row)">
            驳回
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-empty v-if="!loading && list.length === 0" description="暂无提现申请" />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import request from '@/api/request'

const list = ref<any[]>([])
const total = ref(0)
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    const data: any = await request.get('/withdraws', { params: { pageNum: 1, pageSize: 20 } })
    list.value = data.data.list
    total.value = data.data.total
  } finally {
    loading.value = false
  }
}

async function pay(row: any) {
  await request.post(`/withdraws/${row.withdrawNo}/audit`, { pass: true })
  ElMessage.success('已放款（本地模拟）')
  load()
}

async function reject(row: any) {
  await request.post(`/withdraws/${row.withdrawNo}/audit`, { pass: false, remark: '人工驳回' })
  ElMessage.success('已驳回')
  load()
}

onMounted(load)
</script>
