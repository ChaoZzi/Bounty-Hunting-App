import { createRouter, createWebHashHistory } from 'vue-router'

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/Login.vue')
    },
    {
      path: '/',
      component: () => import('@/views/Layout.vue'),
      redirect: '/dashboard',
      children: [
        {
          path: 'dashboard',
          name: 'dashboard',
          component: () => import('@/views/Dashboard.vue'),
          meta: { title: '数据总览' }
        },
        {
          path: 'tasks',
          name: 'tasks',
          component: () => import('@/views/TaskAudit.vue'),
          meta: { title: '任务审核' }
        },
        {
          path: 'withdraws',
          name: 'withdraws',
          component: () => import('@/views/WithdrawAudit.vue'),
          meta: { title: '提现审核' }
        }
      ]
    }
  ]
})

router.beforeEach((to) => {
  const token = localStorage.getItem('admin_token')
  if (to.path !== '/login' && !token) {
    return '/login'
  }
  if (to.path === '/login' && token) {
    return '/dashboard'
  }
  return true
})

export default router
