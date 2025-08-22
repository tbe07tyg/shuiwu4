# 🔧 登录跳转问题修复指南

## 🚨 **问题描述**
点击"立即配置"按钮后，页面自动跳转到登录页面，无法进入项目配置向导。

## 🔍 **问题原因分析**

### **1. 路由守卫检查token** ❌
系统有一个路由守卫检查localStorage中是否存在token：
```javascript
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token')
  if (!token) {
    next('/login') // 没有token就跳转到登录页
    return
  }
  next()
})
```

### **2. 通配符路由兜底** ❌
路由配置末尾有一个通配符：
```javascript
{
  path: '/:catchAll(.*)',
  redirect: '/login'
}
```

### **3. 配置向导路由缺失** ❌
之前删除无效路由时，config-wizard路由可能被误删。

## ✅ **修复方案**

### **修复1：添加配置向导路由** ✅
```javascript
{
  path: 'project-manager/projects/config-wizard',
  name: 'ProjectManagerProjectConfigWizard',
  component: () => import('@/views/project-manager/projects/config-wizard.vue'),
  meta: {
    title: '项目配置向导',
    icon: 'SettingOutlined',
    permissions: ['project-manager:projects']
  }
}
```

### **修复2：优化登录token设置** ✅
```javascript
const onLogin = async () => {
  loading.value = true
  // 设置token以避免跳转问题
  localStorage.setItem('token', 'mock-token-' + Date.now())
  setTimeout(() => {
    loading.value = false
    router.push('/dashboard')
  }, 500)
}
```

### **修复3：启用调试路由守卫** ✅
```javascript
router.beforeEach((to, from, next) => {
  console.log('路由跳转:', from.path, '->', to.path)
  
  // 如果是登录页面，直接通过
  if (to.path === '/login') {
    next()
    return
  }
  
  // 检查token
  const token = localStorage.getItem('token')
  if (!token) {
    console.log('未找到token，跳转到登录页')
    next('/login')
    return
  }
  
  console.log('找到token，允许访问:', token)
  next()
})
```

## 🧪 **测试步骤**

### **步骤1：先登录获取token**
1. 访问 `http://localhost:5173/login`
2. 输入任意用户名和密码（比如 admin/123456）
3. 点击"登录"
4. 成功后会跳转到dashboard并设置token

### **步骤2：测试项目配置**
1. 进入"项目经理后台" → "项目管理"
2. 点击任意项目的"立即配置"按钮
3. 查看浏览器控制台的路由跳转日志
4. 应该能正常进入配置向导页面

### **步骤3：查看调试信息**
在浏览器开发者工具Console中应该看到：
```
路由跳转: /project-manager/projects -> /project-manager/projects/config-wizard?projectId=1&projectName=...
找到token，允许访问: mock-token-xxxxx
```

## 🎯 **预期修复效果**

### **修复前** ❌
- 点击"立即配置" → 自动跳转到登录页面
- 控制台可能显示：`未找到token，跳转到登录页`

### **修复后** ✅
- 点击"立即配置" → 正常进入项目配置向导
- URL: `/project-manager/projects/config-wizard?projectId=1&...`
- 控制台显示：`找到token，允许访问`

## 🔧 **如果问题仍然存在**

### **检查1：确认token存在**
在浏览器控制台输入：
```javascript
console.log('当前token:', localStorage.getItem('token'))
```

### **检查2：手动设置token**
如果没有token，手动设置：
```javascript
localStorage.setItem('token', 'manual-test-token')
```

### **检查3：直接访问配置向导**
手动输入URL测试：
```
http://localhost:5173/project-manager/projects/config-wizard?projectId=1&projectName=测试项目
```

### **检查4：查看路由跳转日志**
观察控制台的路由跳转信息，确定在哪一步发生了重定向。

## 📝 **技术要点**

### **路由守卫逻辑**
- 登录页面无需token验证
- 其他页面需要token才能访问
- 无token时自动跳转到登录页

### **Token管理**
- 登录成功后自动设置token
- Token存储在localStorage中
- 页面刷新后token仍然有效

### **调试功能**
- 控制台显示详细的路由跳转信息
- 方便追踪问题发生的具体位置

现在按照上述步骤操作，应该能解决登录跳转问题！🎉