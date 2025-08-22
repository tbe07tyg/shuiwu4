<!--
 * @file 团队成员工作台v2页面
 * @description 简化的待办事项列表，支持格式化提报和审查意见查看
 * @author 科研管理系统
 * @version 6.0.0
 * @date 2025-01-29
-->
<template>
  <div class="team-workbench-v2">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>团队成员工作台 v2.0</h2>
      <p>我的待办事项管理，支持格式化提报和进度更新</p>
    </div>

    <!-- 待办事项列表 -->
    <a-card title="我的待办事项" :bordered="false" class="todo-card">
      <!-- 筛选器 -->
      <div class="todo-filters">
        <a-space>
          <a-select v-model:value="statusFilter" style="width: 120px">
            <a-select-option value="all">全部状态</a-select-option>
            <a-select-option value="pending">待办</a-select-option>
            <a-select-option value="in_progress">进行中</a-select-option>
            <a-select-option value="completed">已完成</a-select-option>
            <a-select-option value="revision_required">需要重新提报</a-select-option>
          </a-select>
          <a-input-search 
            v-model:value="searchKeyword" 
            placeholder="搜索任务"
            style="width: 200px"
          />
        </a-space>
      </div>

      <!-- 待办事项表格 -->
      <a-table 
        :dataSource="filteredTodos" 
        :columns="columns"
        rowKey="id"
        :pagination="{ pageSize: 10 }"
        size="middle"
      >
        <!-- 自定义单元格渲染 -->
        <template #bodyCell="{ column, record }">
          <!-- 任务标题 -->
          <template v-if="column.key === 'title'">
            <div class="task-title-cell">
              <h4>{{ record?.title || '未知任务' }}</h4>
              <p class="task-description">{{ record?.description || '' }}</p>
              <div class="task-meta">
                <a-space size="small">
                  <span class="meta-item">
                    <CalendarOutlined />
                    截止：{{ record?.deadline || '未设置' }}
                  </span>
                  <span class="meta-item">
                    <ClockCircleOutlined />
                    预计：{{ record?.estimatedHours || 0 }}小时
                  </span>
                </a-space>
              </div>
            </div>
          </template>

          <!-- 状态 -->
          <template v-else-if="column.key === 'status'">
            <a-tag :color="getStatusColor(record?.status || 'pending')">
              {{ getStatusText(record?.status || 'pending') }}
            </a-tag>
          </template>

          <!-- 操作 -->
          <template v-else-if="column.key === 'action'">
            <a-space>
              <a-button 
                size="small" 
                type="primary" 
                @click="handleSubmitReport(record)"
                :disabled="record?.status === 'completed'"
              >
                提报
              </a-button>
              <a-button 
                size="small" 
                @click="handleUpdateProgress(record)"
                :disabled="record?.status === 'completed'"
              >
                更新进度
              </a-button>
              <a-button 
                size="small" 
                @click="handleViewHistory(record)"
                v-if="record?.hasReviewHistory"
              >
                历史审查意见
              </a-button>
            </a-space>
          </template>
        </template>
      </a-table>
    </a-card>

    <!-- 格式化提报弹窗 -->
    <a-modal
      v-model:open="reportModalVisible"
      title="任务提报"
      width="800px"
      :footer="null"
    >
      <div v-if="currentTodo" class="report-form">
        <!-- 任务信息 -->
        <div class="task-info-section">
          <a-alert
            :message="`正在提报：${currentTodo.title}`"
            type="info"
            show-icon
            style="margin-bottom: 20px"
          />
        </div>

        <!-- 格式化提报表单 -->
        <a-form layout="vertical">
          <a-form-item label="🔍 发现结论" required>
            <a-textarea
              v-model:value="reportForm.findings"
              placeholder="请描述本阶段的主要发现和结论..."
              :rows="3"
              show-count
              :maxlength="300"
            />
          </a-form-item>

          <a-form-item label="📝 详细描述" required>
            <a-textarea
              v-model:value="reportForm.details"
              placeholder="请详细描述工作内容、实施过程、技术方案等..."
              :rows="4"
              show-count
              :maxlength="500"
            />
          </a-form-item>

          <a-form-item label="🔗 发现来源" required>
            <a-textarea
              v-model:value="reportForm.sources"
              placeholder="请说明发现的来源、依据、参考资料等..."
              :rows="3"
              show-count
              :maxlength="300"
            />
          </a-form-item>

          <a-form-item label="📋 下一步计划" required>
            <a-textarea
              v-model:value="reportForm.nextSteps"
              placeholder="请描述下一阶段的工作计划和时间安排..."
              :rows="3"
              show-count
              :maxlength="300"
            />
          </a-form-item>

          <a-form-item label="⚠️ 遇到的困难">
            <a-textarea
              v-model:value="reportForm.difficulties"
              placeholder="请描述遇到的问题、困难和需要的支持..."
              :rows="3"
              show-count
              :maxlength="300"
            />
          </a-form-item>

          <a-form-item label="📎 附件上传">
            <a-upload
              v-model:file-list="reportForm.attachments"
              :before-upload="() => false"
              multiple
            >
              <a-button>
                <UploadOutlined />
                选择文件
              </a-button>
            </a-upload>
          </a-form-item>
        </a-form>

        <!-- 操作按钮 -->
        <div class="report-actions">
          <a-space>
            <a-button 
              type="primary" 
              @click="handleSubmitReportForm"
              :disabled="!isReportFormValid"
            >
              <CheckOutlined />
              提交提报
            </a-button>
            <a-button @click="reportModalVisible = false">
              取消
            </a-button>
          </a-space>
        </div>
      </div>
    </a-modal>

    <!-- 进度更新弹窗 -->
    <a-modal
      v-model:open="progressModalVisible"
      title="更新进度"
      width="500px"
      :footer="null"
    >
      <div v-if="currentTodo" class="progress-form">
        <a-form layout="vertical">
          <a-form-item label="任务进度">
            <a-slider
              v-model:value="progressForm.progress"
              :marks="{ 0: '0%', 25: '25%', 50: '50%', 75: '75%', 100: '100%' }"
              :tooltip-formatter="(value) => `${value}%`"
            />
          </a-form-item>

          <a-form-item label="状态更新">
            <a-select v-model:value="progressForm.status" style="width: 100%">
              <a-select-option value="pending">待办</a-select-option>
              <a-select-option value="in_progress">进行中</a-select-option>
              <a-select-option value="completed">已完成</a-select-option>
            </a-select>
          </a-form-item>

          <a-form-item label="进度说明">
            <a-textarea
              v-model:value="progressForm.notes"
              placeholder="请简要说明进度变更的原因..."
              :rows="3"
            />
          </a-form-item>
        </a-form>

        <div class="progress-actions">
          <a-space>
            <a-button type="primary" @click="handleUpdateProgressForm">
              <CheckOutlined />
              更新进度
            </a-button>
            <a-button @click="progressModalVisible = false">
              取消
            </a-button>
          </a-space>
        </div>
      </div>
    </a-modal>

    <!-- 历史审查意见弹窗 -->
    <a-modal
      v-model:open="historyModalVisible"
      title="历史审查意见"
      width="700px"
      :footer="null"
    >
      <div v-if="currentTodo" class="history-content">
        <div class="history-list">
          <div 
            v-for="review in mockReviewHistory" 
            :key="review.id"
            class="review-item"
          >
            <div class="review-header">
              <div class="reviewer-info">
                <a-avatar size="small">{{ review.reviewer.charAt(0) }}</a-avatar>
                <div class="reviewer-details">
                  <span class="reviewer-name">{{ review.reviewer }}</span>
                  <span class="review-time">{{ review.reviewTime }}</span>
                </div>
              </div>
              <a-tag :color="review.action === 'approve' ? 'green' : 'orange'">
                {{ review.action === 'approve' ? '通过' : '要求修改' }}
              </a-tag>
            </div>
            <div class="review-content">
              <div class="review-opinion">
                <strong>审查意见：</strong>
                <p>{{ review.opinion }}</p>
              </div>
              <div v-if="review.suggestions" class="review-suggestions">
                <strong>{{ review.action === 'approve' ? '改进建议：' : '修改建议：' }}</strong>
                <p>{{ review.suggestions }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { message } from 'ant-design-vue'
import {
  CalendarOutlined,
  ClockCircleOutlined,
  CheckOutlined,
  UploadOutlined
} from '@ant-design/icons-vue'

// 响应式数据
const statusFilter = ref('all')
const searchKeyword = ref('')
const reportModalVisible = ref(false)
const progressModalVisible = ref(false)
const historyModalVisible = ref(false)
const currentTodo = ref(null)

// 表单数据
const reportForm = ref({
  findings: '',
  details: '',
  sources: '',
  nextSteps: '',
  difficulties: '',
  attachments: []
})

const progressForm = ref({
  progress: 0,
  status: 'pending',
  notes: ''
})

// 模拟待办事项数据
const todos = ref([
  {
    id: 'T001',
    title: '系统架构设计',
    description: '设计系统整体架构，包括前端、后端、数据库等组件',
    status: 'in_progress',
    deadline: '2025-08-25',
    estimatedHours: 40,
    progress: 60,
    hasReviewHistory: true
  },
  {
    id: 'T002',
    title: '前端界面开发',
    description: '开发用户界面，实现响应式设计和用户交互功能',
    status: 'pending',
    deadline: '2025-08-30',
    estimatedHours: 60,
    progress: 0,
    hasReviewHistory: false
  },
  {
    id: 'T003',
    title: '数据库设计优化',
    description: '优化数据库表结构，提升查询性能',
    status: 'revision_required',
    deadline: '2025-08-28',
    estimatedHours: 30,
    progress: 80,
    hasReviewHistory: true
  },
  {
    id: 'T004',
    title: '测试用例编写',
    description: '编写单元测试和集成测试用例',
    status: 'completed',
    deadline: '2025-08-22',
    estimatedHours: 20,
    progress: 100,
    hasReviewHistory: true
  },
  {
    id: 'T005',
    title: 'API接口设计',
    description: '设计RESTful API接口，定义数据格式和交互规范',
    status: 'pending',
    deadline: '2025-08-26',
    estimatedHours: 25,
    progress: 0,
    hasReviewHistory: false
  }
])

// 模拟审查历史数据
const mockReviewHistory = ref([
  {
    id: 'R001',
    reviewer: '项目负责人',
    reviewTime: '2025-08-21 14:30',
    action: 'reject',
    opinion: '数据库设计方案需要进一步完善，缺少关键的性能优化考虑。',
    suggestions: '1. 补充索引设计方案；2. 增加分区策略；3. 考虑读写分离架构。'
  },
  {
    id: 'R002',
    reviewer: '技术专家',
    reviewTime: '2025-08-20 16:45',
    action: 'approve',
    opinion: '初步设计方案合理，技术路线清晰。',
    suggestions: '建议在下一阶段加强性能测试验证。'
  }
])

// 表格列定义
const columns = [
  {
    title: '任务信息',
    key: 'title',
    width: '40%'
  },
  {
    title: '状态',
    key: 'status',
    width: '15%'
  },
  {
    title: '进度',
    dataIndex: 'progress',
    key: 'progress',
    width: '15%',
    customRender: ({ text }) => `${text}%`
  },
  {
    title: '操作',
    key: 'action',
    width: '30%'
  }
]

// 计算属性
const filteredTodos = computed(() => {
  let filtered = todos.value
  
  if (statusFilter.value !== 'all') {
    filtered = filtered.filter(todo => todo.status === statusFilter.value)
  }
  
  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    filtered = filtered.filter(todo => 
      todo.title.toLowerCase().includes(keyword) ||
      todo.description.toLowerCase().includes(keyword)
    )
  }
  
  return filtered
})

const isReportFormValid = computed(() => {
  return reportForm.value.findings.trim() &&
         reportForm.value.details.trim() &&
         reportForm.value.sources.trim() &&
         reportForm.value.nextSteps.trim()
})

// 方法定义
const getStatusColor = (status) => {
  const colorMap = {
    'pending': 'orange',
    'in_progress': 'blue',
    'completed': 'green',
    'revision_required': 'red'
  }
  return colorMap[status] || 'default'
}

const getStatusText = (status) => {
  const textMap = {
    'pending': '待办',
    'in_progress': '进行中',
    'completed': '已完成',
    'revision_required': '需要重新提报'
  }
  return textMap[status] || status
}

const handleSubmitReport = (todo) => {
  currentTodo.value = todo
  // 清空表单
  reportForm.value = {
    findings: '',
    details: '',
    sources: '',
    nextSteps: '',
    difficulties: '',
    attachments: []
  }
  reportModalVisible.value = true
}

const handleUpdateProgress = (todo) => {
  currentTodo.value = todo
  progressForm.value = {
    progress: todo.progress,
    status: todo.status,
    notes: ''
  }
  progressModalVisible.value = true
}

const handleViewHistory = (todo) => {
  currentTodo.value = todo
  historyModalVisible.value = true
}

const handleSubmitReportForm = () => {
  const reportData = {
    todoId: currentTodo.value.id,
    ...reportForm.value,
    submitTime: new Date().toLocaleString()
  }
  
  console.log('提交提报数据：', reportData)
  message.success('提报提交成功，等待审查')
  reportModalVisible.value = false
}

const handleUpdateProgressForm = () => {
  const progressData = {
    todoId: currentTodo.value.id,
    ...progressForm.value,
    updateTime: new Date().toLocaleString()
  }
  
  // 更新本地数据
  const todo = todos.value.find(t => t.id === currentTodo.value.id)
  if (todo) {
    todo.progress = progressForm.value.progress
    todo.status = progressForm.value.status
  }
  
  console.log('更新进度数据：', progressData)
  message.success('进度更新成功')
  progressModalVisible.value = false
}
</script>

<style scoped>
.team-workbench-v2 {
  padding: 24px;
  background: #f5f8ff;
  min-height: 100vh;
}

.page-header {
  text-align: center;
  margin-bottom: 32px;
  padding: 32px;
  background: linear-gradient(135deg, #f0f7ff 0%, #e6f4ff 100%);
  border-radius: 12px;
  border: 1px solid #d6e4ff;
}

.page-header h2 {
  color: #234fa2;
  font-size: 28px;
  margin: 0 0 8px 0;
  font-weight: 600;
}

.page-header p {
  color: #64748b;
  margin: 0;
  font-size: 16px;
}

.todo-card {
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(35,79,162,0.06);
}

.todo-filters {
  margin-bottom: 20px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e6eaf2;
}

.task-title-cell h4 {
  margin: 0 0 4px 0;
  color: #333;
  font-size: 16px;
  font-weight: 600;
}

.task-description {
  margin: 0 0 8px 0;
  color: #64748b;
  font-size: 14px;
  line-height: 1.5;
}

.task-meta {
  margin: 0;
}

.meta-item {
  color: #8c8c8c;
  font-size: 12px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

/* 弹窗样式 */
.report-form,
.progress-form {
  max-height: 70vh;
  overflow-y: auto;
}

.task-info-section {
  margin-bottom: 20px;
}

.report-actions,
.progress-actions {
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid #e6eaf2;
  display: flex;
  justify-content: center;
}

/* 历史审查意见样式 */
.history-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-height: 60vh;
  overflow-y: auto;
}

.review-item {
  border: 1px solid #e6eaf2;
  border-radius: 8px;
  padding: 16px;
  background: #fafbfc;
}

.review-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.reviewer-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.reviewer-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.reviewer-name {
  font-weight: 600;
  color: #234fa2;
  font-size: 13px;
}

.review-time {
  color: #8c8c8c;
  font-size: 11px;
}

.review-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.review-opinion,
.review-suggestions {
  padding: 12px;
  background: #f8fafc;
  border-radius: 6px;
  border-left: 4px solid #234fa2;
}

.review-opinion strong,
.review-suggestions strong {
  color: #234fa2;
  font-size: 13px;
  display: block;
  margin-bottom: 8px;
}

.review-opinion p,
.review-suggestions p {
  margin: 0;
  color: #333;
  font-size: 13px;
  line-height: 1.6;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .team-workbench-v2 {
    padding: 16px;
  }
  
  .page-header {
    padding: 20px;
  }
  
  .todo-filters {
    flex-direction: column;
    gap: 12px;
  }
  
  .review-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
}
</style>