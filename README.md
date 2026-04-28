# MyApplication

HarmonyOS 健康记录 App，包含鸿蒙 ArkTS 客户端、Node.js 后端服务和一份 Web 原型。当前重点功能是饮食、饮水、体重、运动、AI 健康助手、趋势日历、周报和个人中心。

## 功能概览

- 账号注册、登录、首次资料初始化和资料同步
- 体重记录、体重管理方案、周内减重进度和体重曲线
- 饮水记录、饮品选择、每日目标和进度展示
- 餐食记录、食物搜索、拍照识别、收藏常吃食物和手动纠偏
- 运动记录、运动分类、消耗统计和本周运动柱状图
- 趋势日历，按日期回看热量、饮水、运动和体重记录
- AI 健康助手和 AI 周报入口
- 个人中心、成就积分、目标计划、数据导出预览

## 项目结构

```text
.
├── entry/                         # HarmonyOS ArkTS 主应用
│   └── src/main/ets/
│       ├── pages/Index.ets        # 主页面入口，保留 UI 编排和状态调度
│       ├── pages/modules/         # 登录、记录、AI、个人中心页面模块
│       ├── models/                # 状态模型、展示计算、业务 helper
│       ├── services/              # 后端、AI、食物库、持久化服务
│       └── config/                # 客户端配置
├── backend/                       # Express 后端服务
│   ├── src/index.js               # API 路由入口
│   ├── src/lib/                   # 用户、状态存储
│   ├── src/services/              # DeepSeek、豆包、薄荷食物库代理
│   └── test/                      # Node 测试
├── prototype/                     # Web 原型
├── docs/                          # 设计和重构计划文档
├── build-app.bat                  # 构建 HAP 的便捷脚本
└── run-hvigor.bat                 # hvigor 命令包装脚本
```

## 环境要求

- DevEco Studio，并确认 `build-app.bat` 里的 DevEco 安装路径正确
- Node.js 18 或更高版本
- npm

当前后端默认端口是 `5200`。之前 `3100` 在这台 Windows 机器上可能被系统保留，容易出现 `EACCES`，所以项目已切到 `5200`。

## 启动后端

```bash
cd backend
npm install
npm run dev
```

后端启动后默认地址：

```text
http://localhost:5200
```

健康检查：

```text
GET http://localhost:5200/api/health
```

## 后端环境变量

后端读取 `backend/.env`，这个文件不会提交到 Git。常用配置如下：

```env
PORT=5200
CLIENT_ORIGIN=*
AUTH_TOKEN_SECRET=replace-with-a-long-random-secret
AUTH_TOKEN_TTL_MS=604800000

DEEPSEEK_API_KEY=
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_API_URL=https://api.deepseek.com/chat/completions

DOUBAO_API_KEY=
DOUBAO_ENDPOINT_ID=
DOUBAO_API_URL=https://ark.cn-beijing.volces.com/api/v3/chat/completions

BOOHEE_APP_ID=
BOOHEE_APP_KEY=
BOOHEE_BASE_URL=https://fc.boohee.com

DEMO_EMAIL=demo@health.app
DEMO_PASSWORD=12345678
```

第三方 API Key 统一放在后端，客户端只请求自己的后端服务。

## 客户端连接后端

配置文件：

[entry/src/main/ets/config/BackendConfig.ets](entry/src/main/ets/config/BackendConfig.ets)

模拟器默认使用：

```ts
export const BACKEND_API_BASE_URL: string = 'http://10.0.2.2:5200/api';
```

真机调试时，把 `10.0.2.2` 改成电脑的局域网 IP，例如：

```text
http://192.168.1.20:5200/api
```

真机和电脑需要在同一个网络里，并确保防火墙允许 `5200` 端口。

## 构建 HarmonyOS 应用

在项目根目录运行：

```bash
.\build-app.bat
```

如果只想直接调用 hvigor 包装脚本：

```bash
.\run-hvigor.bat assembleHap
```

## 运行测试

后端测试：

```bash
cd backend
npm test
```

当前测试覆盖了 token 校验、过期拒绝、资料接口鉴权和用户状态隔离。

## 主要 API

认证和用户：

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/profile`
- `POST /api/auth/onboarding`
- `POST /api/auth/password`
- `GET /api/user/state`
- `PUT /api/user/state`

AI 和业务：

- `POST /api/ai/chat`
- `POST /api/ai/vision/food`
- `GET /api/foods/search`

`/api/auth/profile`、`/api/auth/onboarding`、`/api/auth/password` 和 `/api/user/state` 需要 Bearer token。

## 当前架构说明

客户端的 [Index.ets](entry/src/main/ets/pages/Index.ets) 仍然是主页面入口，但已经拆出了多批纯逻辑模块：

- `DateTimeUtils.ets`：日期和周区间
- `WeightPlan.ets`：体重计划和进度
- `ExerciseInsights.ets`：运动统计
- `MealInsights.ets`：餐食统计
- `WaterInsights.ets`：饮水目标和记录
- `ProfileInsights.ets`：个人中心展示文案
- `TrendDetails.ets`：趋势日历详情
- `IconResolvers.ets`、`IndexSeedData.ets`、`MealDisplay.ets`：图标、预设数据和展示映射

后续继续重构时，建议优先把 `Index.ets` 里的事件控制继续拆成 `WaterController`、`MealController`、`ExerciseController`、`ProfileController`，再逐步拆 UI builder。

## 常见问题

### 后端启动时报 `EACCES`

通常是端口被系统保留或占用。项目默认使用 `5200`，不要改回 `3100`。如果 `5200` 也被占用，可以修改 `backend/.env` 的 `PORT`，同时更新客户端 `BackendConfig.ets`。

### 模拟器请求不到后端

检查三件事：

- 后端是否已经运行 `npm run dev`
- 客户端是否使用 `http://10.0.2.2:5200/api`
- 电脑防火墙是否允许 Node.js 或 `5200` 端口

### 真机请求不到后端

真机不能使用 `10.0.2.2`，需要改成电脑局域网 IP。手机和电脑必须在同一个 Wi-Fi 或局域网内。

### AI 或食物识别不可用

检查 `backend/.env` 里的 DeepSeek、豆包、薄荷食物库配置是否填写。没有配置时，相关接口会返回配置缺失或服务错误。
