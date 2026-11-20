<template>
  <div class="page-card">
    <div class="toolbar">
      <el-select v-model="status" placeholder="全部状态" clearable style="width: 160px" @change="load">
        <el-option label="待审核" :value="0" />
        <el-option label="审核通过" :value="1" />
        <el-option label="审核驳回" :value="2" />
      </el-select>
      <el-button @click="load">刷新</el-button>
      <span style="color: #909399; font-size: 13px">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="default">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="title" label="任务标题" min-width="220" />
      <el-table-column prop="unitPrice" label="单价" width="90" />
      <el-table-column prop="totalQuota" label="名额" width="80" />
      <el-table-column prop="publisherId" label="发布者" width="90" />
      <el-table-column prop="createdAt" label="创建时间" width="170" />
      <el-table-column label="审核状态" width="110">
        <template #default="{ row }">
          <el-tag v-if="row.auditStatus === 0" type="warning" size="small">待审核</el-tag>
          <el-tag v-else-if="row.auditStatus === 1" type="success" size="small">已通过</el-tag>
          <el-tag v-else type="danger" size="small">已驳回</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="180" fixed="right">
        <template #default="{ row }">
          <el-button size="small" type="primary" @click="audit(row, true)">通过</el-button>
          <el-button size="small" type="danger" plain @click="audit(row, false)">驳回</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination
      style="margin-top: 16px; justify-content: flex-end"
      layout="prev, pager, next"
      :total="total"
      :page-size="pageSize"
      v-model:current-page="pageNum"
      @current-change="load"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '@/api/request'

const list = ref<any[]>([])
const total = ref(0)
const pageNum = ref(1)
const pageSize = 10
const status = ref<number | undefined>(undefined)
const loading = ref(false)

async function load() {
  loading.value = true
  try {
    const params: any = { pageNum: pageNum.value, pageSize }
    if (status.value !== undefined && status.value !== null) {
      params.auditStatus = status.value
    }
    const data: any = await request.get('/tasks', { params })
    list.value = data.data.list
    total.value = data.data.total
  } finally {
    loading.value = false
  }
}

async function audit(row: any, pass: boolean) {
  let remark = ''
  if (!pass) {
    const r: any = await ElMessageBox.prompt('请输入驳回原因', '驳回任务', {
      confirmButtonText: '确定',
      cancelButtonText: '取消'
    })
    remark = r.value
  }
  await request.post(`/tasks/${row.id}/audit`, { pass, remark })
  ElMessage.success(pass ? '已通过' : '已驳回')
  load()
}

onMounted(load)
</script>
