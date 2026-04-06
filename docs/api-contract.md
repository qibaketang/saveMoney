# Budget Guard API 统一协议与对照表

本文档定义登录、记账、限额、目标、统计五大模块的统一请求/响应结构、错误码规范与前后端改造对照。

## 1. 统一响应结构

### 1.1 成功响应

```json
{
  "code": 0,
  "message": "登录成功",
  "data": {},
  "requestId": "a6fb7f3d-7f43-49f6-a2a4-e0e01e9f3a77",
  "timestamp": "2026-04-03T08:00:00.000Z"
}
```

字段约定：
- `code`: 成功固定为 `0`。
- `message`: 面向用户或日志的成功文案。
- `data`: 业务数据主体。
- `requestId`: 每个请求唯一链路 ID，服务端生成并回写响应头 `x-request-id`。
- `timestamp`: 服务端响应时间，ISO 8601。

### 1.2 失败响应

```json
{
  "code": "VALIDATION_FAILED",
  "message": "amount 和 category 必填且合法",
  "details": null,
  "requestId": "a6fb7f3d-7f43-49f6-a2a4-e0e01e9f3a77",
  "timestamp": "2026-04-03T08:00:00.000Z"
}
```

字段约定：
- `code`: 字符串错误码（见第 2 节）。
- `message`: 给前端展示的标准错误文案。
- `details`: 可选，调试信息或字段级错误。
- `requestId` / `timestamp`: 同成功响应。

## 2. 统一错误码与文案规范

| 错误码 | HTTP 状态码 | 默认文案 | 触发场景 |
|---|---:|---|---|
| `AUTH_MISSING_TOKEN` | 401 | 未登录，请先登录 | 缺少 Authorization 头 |
| `AUTH_INVALID_TOKEN` | 401 | 登录已失效，请重新登录 | Token 过期或无效 |
| `AUTH_INVALID_PHONE` | 400 | 手机号格式不正确 | 登录手机号参数非法 |
| `VALIDATION_FAILED` | 400 | 请求参数校验失败 | 通用字段校验不通过 |
| `RESOURCE_NOT_FOUND` | 404 | 资源不存在 | 根据 ID 查询不到记录 |
| `INTERNAL_SERVER_ERROR` | 500 | 服务器内部错误 | 未处理异常 |

文案规范：
- 面向用户：简短、可执行，不暴露堆栈与敏感信息。
- 面向日志：通过 `requestId` 回查服务日志，不直接拼接内部异常给用户。
- 面向前端：前端逻辑优先依赖 `code`，文案可按产品化做本地化覆盖。

## 3. API 对照表（后端现状 + 前端改造目标）

> 统一前缀：`/api`

### 3.1 登录 Auth

| 模块 | 方法 | 路径 | 请求 | 成功 data 结构 | 前端改造目标 |
|---|---|---|---|---|---|
| 登录 | `POST` | `/auth/login` | `{ "phone": "13800138000" }` | `{ "accessToken": "...", "tokenType": "Bearer", "expiresIn": 604800, "user": { ... } }` | `AuthProvider.login` 改为调用此接口并持久化 token + user |

### 3.2 记账 Expenses

| 模块 | 方法 | 路径 | 请求 | 成功 data 结构 | 前端改造目标 |
|---|---|---|---|---|---|
| 列表 | `GET` | `/expenses` | Header: `Authorization: Bearer <token>` | `{ "items": [Expense] }` | `RecordProvider.load` 改为远端拉取 |
| 新增 | `POST` | `/expenses` | `{ "amount": 12.5, "category": "早餐", "note": "豆浆", "tags": ["工作日"], "spentAt": "2026-04-03T08:00:00.000Z" }` | `{ "expense": Expense, "usage": { ... } }` | `RecordProvider.addRecord` 改为远端写入后本地刷新 |
| 更新 | `PUT` | `/expenses/:id` | 可更新字段同 Expense | `{ "expense": Expense }` | 增加编辑记账时调用 |
| 删除 | `DELETE` | `/expenses/:id` | 无 | `null` | `RecordProvider.deleteRecord` 改为远端删除 |

### 3.3 限额 Limits

| 模块 | 方法 | 路径 | 请求 | 成功 data 结构 | 前端改造目标 |
|---|---|---|---|---|---|
| 查询 | `GET` | `/limits` | Header: Bearer token | `{ "limit": Limit, "usage": { ... } }` | `LimitProvider.load` 改为远端拉取 |
| 保存 | `PUT` | `/limits` | `{ "dailyLimit": 250, "categories": [{ "name": "餐饮", "amount": 100 }] }` | `{ "limit": Limit }` | `LimitProvider.update*` 改为远端写入 |

### 3.4 储蓄目标 Goals

| 模块 | 方法 | 路径 | 请求 | 成功 data 结构 | 前端改造目标 |
|---|---|---|---|---|---|
| 查询 | `GET` | `/goals` | Header: Bearer token | `{ "goal": SavingGoal }` | `GoalProvider.load` 改为远端拉取 |
| 保存 | `PUT` | `/goals` | `{ "name": "旅行基金", "targetAmount": 6000, "savedAmount": 1800, "targetDate": "2026-10-01T00:00:00.000Z" }` | `{ "goal": SavingGoal }` | `GoalProvider.saveGoal` 改为远端写入 |

### 3.5 统计 Stats

| 模块 | 方法 | 路径 | 请求 | 成功 data 结构 | 前端改造目标 |
|---|---|---|---|---|---|
| 月统计 | `GET` | `/stats/monthly` | Header: Bearer token | `{ "categoryStats": [{ "_id": "餐饮", "total": 1200 }], "dailyTrend": [{ "_id": 1, "total": 50 }] }` | 新增 Stats API 调用层，替换本地聚合 |

## 4. 前后端落地改造清单

### 4.1 后端
- 所有接口遵循统一 Envelope（`code/message/data/requestId/timestamp`）。
- 所有异常返回统一 Error Envelope（`code/message/details/requestId/timestamp`）。
- 所有认证失败统一返回 `AUTH_MISSING_TOKEN` / `AUTH_INVALID_TOKEN`。

### 4.2 前端
- 新增统一 API Client：
  - 自动注入 Bearer token。
  - 统一解析 Envelope。
  - 非 0 code 映射错误文案。
- Provider 层全部切换到后端 API，不再直接使用 SharedPreferences 作为主数据源。
- SharedPreferences 仅保留 token、基础缓存和离线兜底。

## 5. 版本与兼容

- 版本：`v1`（当前）
- 兼容策略：
  - 旧返回结构不再保证兼容。
  - 前端必须按本文件升级解析逻辑。
