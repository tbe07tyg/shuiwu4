# 🔧 里程碑页面调试指南

## 🚨 **问题描述**
- 里程碑页面点击"下一步"没有反应
- 再点一次后直接到任务规划页面，但页面是空的

## 🔍 **问题分析 & 修复**

### **1. 验证逻辑增强** ✅
**问题**：里程碑验证不够完整，只检查是否启用，未检查必填字段
**修复**：添加了计划时间的验证
```javascript
// 新增验证：检查启用的里程碑是否都有计划时间
for (const milestone of enabledMilestones) {
  if (!milestone.plannedDate) {
    message.error(`请设置"${milestone.name}"的计划时间`)
    return false
  }
}
```

### **2. 调试信息添加** ✅
**目的**：追踪点击行为和数据状态
**内容**：
- nextStep方法添加控制台输出
- handleTemplateChange方法添加详细日志
- 里程碑数据验证前后的状态输出

### **3. 数据初始化检查** ✅
**确认**：handleTemplateChange在组件挂载时被调用
**预期**：应该正确更新里程碑的plannedDate

## 🧪 **调试步骤**

### **步骤1：打开开发者工具**
1. 按F12打开开发者工具
2. 切换到Console标签页
3. 刷新页面

### **步骤2：检查初始化日志**
**预期看到的日志**：
```
handleTemplateChange 被调用，templateId: 1
找到的模板: {id: 1, name: "标准研发模板", ...}
模板结构: {phases: [...], milestones: [...]}
更新后的里程碑: [{name: "需求确认", plannedDate: dayjs对象, ...}, ...]
更新后的WBS结构: [{key: "phase-0", title: "需求分析阶段", ...}, ...]
```

### **步骤3：测试里程碑验证**
1. 进入第3步里程碑设置
2. 点击"下一步"
3. **观察控制台输出**：
```
nextStep 被调用，当前步骤: 2
验证前 - milestones: [{name: "需求确认", plannedDate: dayjs对象, enabled: true}, ...]
验证通过，进入下一步
新的步骤: 3
```

### **步骤4：验证任务规划页面**
1. 确认进入第4步
2. 检查WBS树是否显示数据
3. 确认模板名称是否正确显示

## 🎯 **预期修复效果**

### **修复前的问题** ❌
- 点击"下一步"验证失败但没有错误提示
- 里程碑数据可能没有正确的plannedDate
- WBS结构可能没有正确初始化

### **修复后的效果** ✅
- 验证失败时会显示具体的错误消息
- 里程碑数据在模板应用时自动设置plannedDate
- 控制台有详细的调试信息帮助追踪问题

## 🔧 **如果问题仍然存在**

### **检查1：里程碑数据**
在控制台中输入：
```javascript
// 检查当前里程碑数据
console.log('当前里程碑数据:', Vue.getCurrentInstance().ctx.milestones)
```

### **检查2：模板应用**
确认模板是否正确应用：
```javascript
// 检查当前选中的模板
console.log('当前模板:', Vue.getCurrentInstance().ctx.selectedTemplate)
```

### **检查3：WBS结构**
验证WBS数据：
```javascript
// 检查WBS结构
console.log('WBS结构:', Vue.getCurrentInstance().ctx.wbsStructure)
```

## 📝 **问题总结**

**核心修复点**：
1. ✅ 增强里程碑验证逻辑（检查计划时间）
2. ✅ 添加详细的调试日志
3. ✅ 确保模板数据正确应用到里程碑和WBS

**下一步操作**：
1. 刷新页面测试
2. 查看控制台日志
3. 按步骤完成配置向导

如果问题仍然存在，请提供控制台的具体错误信息！