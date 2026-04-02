# Budget Guard（限额控制型记账存钱 App）

这是基于你上传的《限额控制型 APP - 功能页面设计文档》继续深化后的 **可继续开发 MVP 项目**。当前版本重点完成了：

- Flutter 3 + Dart 3 的移动端项目骨架
- Provider 状态管理
- shared_preferences 本地持久化
- fl_chart 月度统计图表
- Node.js 18 + Express 4 + MongoDB 6 后端基础 API
- JWT 登录占位实现
- 存钱目标、限额设置、消费记录、统计分析等核心页面

## 已落地的产品主线

### 1. 首页：实时限额监控
- 今日剩余额度大数字展示
- 预算状态颜色预警（安全 / 警告 / 危险 / 超支）
- 今日已消费、剩余预算、今日笔数
- 最近记录列表

### 2. 记账页：3 秒记账 MVP
- 金额输入
- 分类选择
- 备注输入
- 标签选择
- 本地保存并刷新首页/统计

### 3. 限额设置页
- 每日限额设置
- 月度限额自动推算
- 分类限额可视化
- 预留提醒能力接入位

### 4. 统计分析页
- 月度消费趋势折线图
- 分类消费排行

### 5. 存钱目标页
- 当前进度
- 目标金额 / 已存金额
- 目标编辑与保存

### 6. 个人中心
- 用户信息展示
- 限额设置 / 记录页 / 提醒设置入口
- 退出登录

## 项目结构

```text
budget_app_project/
├── frontend/                 # Flutter 移动端
│   └── lib/
│       ├── app/
│       ├── core/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── widgets/
├── backend/                  # Node.js + Express API
│   ├── scripts/
│   └── src/
└── README.md
```

## 前端启动

```bash
cd frontend
flutter pub get
flutter run
```

## 后端启动

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

## 当前前端实现说明

当前 Flutter 端已实现的是 **本地可演示 MVP 流程**：
- 使用 shared_preferences 做本地数据持久化
- 初次进入会自动生成演示消费记录与默认存钱目标
- 登录为演示快捷登录，可替换为短信验证码登录
- 底部导航已打通：首页 / 记账 / 统计 / 目标 / 我的

## 当前后端 API

- `POST /api/auth/login` 手机号快捷登录
- `GET /api/expenses` 获取消费记录
- `POST /api/expenses` 新增消费记录
- `PUT /api/expenses/:id` 更新消费记录
- `DELETE /api/expenses/:id` 删除消费记录
- `GET /api/limits` 获取限额与今日使用情况
- `PUT /api/limits` 更新限额
- `GET /api/stats/monthly` 获取月度统计
- `GET /api/goals` 获取存钱目标
- `PUT /api/goals` 保存存钱目标

## 下一阶段建议开发顺序

### Phase 1：把 MVP 跑通
- Flutter 真机跑通
- 对接真实 API
- 登录态持久化
- 限额提醒逻辑统一

### Phase 2：补齐云能力
- OSS / COS 上传头像与凭证
- 极光 / 个推接入限额提醒
- 阿里云 / 腾讯云短信验证码
- MongoDB Atlas 上云

### Phase 3：做成正式产品
- UI 动效和设计稿还原
- 数据导出 Excel / CSV
- 分类预算建议
- 每周/月报表
- Docker 化部署与 CI/CD

## 建议补充的工程能力

### Flutter 端
- Dio / Retrofit 网络层
- Freezed / Json Serializable
- GoRouter 路由管理
- 单元测试与 Widget 测试

### 后端
- Joi / Zod 参数校验
- Swagger/OpenAPI 文档
- Redis 预算缓存与频控
- 日志与异常链路追踪
- 定时任务（提醒、日报）

## 云服务建议

### 最小上线配置
- 应用服务器：阿里云/腾讯云 2 核 4G
- 数据库：MongoDB Atlas M10 或自建 MongoDB
- 对象存储：阿里云 OSS / 腾讯云 COS
- 推送：极光推送 / 个推
- 短信：阿里云短信 / 腾讯云短信

## 说明

当前交付更准确地说是：

> **可直接继续开发的完整工程骨架 + 已串起来的本地 MVP 前端 + 可扩展的后端基础 API**

它适合你下一步继续做正式版，而不是停留在静态原型阶段。
