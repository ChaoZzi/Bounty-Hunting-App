<template>
  <div>
    <el-row :gutter="16">
      <el-col :span="6" v-for="item in cards" :key="item.label">
        <div class="page-card stat">
          <div class="label">{{ item.label }}</div>
          <div class="value">{{ item.value }}</div>
        </div>
      </el-col>
    </el-row>

    <div class="page-card" style="margin-top: 16px">
      <h3 style="margin: 0 0 12px">最近任务</h3>
      <el-table :data="tasks" size="small">
        <el-table-column prop="id" label="ID" width="70" />
        <el-table-column prop="title" label="标题" />
        <el-table-column prop="unitPrice" label="单价" width="100" />
        <el-table-column prop="remainQuota" label="剩余" width="90" />
        <el-table-column label="状态" width="110">
          <template #default="{ row }">
            <el-tag :type="row.status === 2 ? 'success' : 'warning'" size="small">
              {{ row.status === 2 ? '展示中' : '未上架' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import request from '@/api/request'

const stats = ref<any>({})
const tasks = ref<any[]>([])

const cards = computed(() => [
  { label: '注册用户', value: stats.value.userCount ?? '-' },
  { label: '任务总数', value: stats.value.taskCount ?? '-' },
  { label: '报名总数', value: stats.value.orderCount ?? '-' },
  { label: '待审核提现', value: stats.value.pendingWithdraw ?? '-' }
])

onMounted(async () => {
  const data: any = await request.get('/dashboard')
  stats.value = data.data.stats || {}
  tasks.value = data.data.recentTasks || []
})
</script>

<style scoped>
.stat .label {
  color: #909399;
  font-size: 13px;
}
.stat .value {
  font-size: 26px;
  font-weight: 600;
  color: #303133;
  margin-top: 6px;
}
</style>
