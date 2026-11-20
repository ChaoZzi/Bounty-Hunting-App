import axios from 'axios'
import { ElMessage } from 'element-plus'

const request = axios.create({
  baseURL: '/admin/v1',
  timeout: 15000
})

request.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

request.interceptors.response.use(
  (res) => {
    const body = res.data
    if (body && typeof body.code === 'number' && body.code !== 0) {
      ElMessage.error(body.msg || '请求失败')
      if (body.code === 401) {
        localStorage.removeItem('admin_token')
        location.hash = '#/login'
      }
      return Promise.reject(new Error(body.msg))
    }
    return body
  },
  (err) => {
    ElMessage.error(err?.message || '网络异常')
    return Promise.reject(err)
  }
)

export default request
