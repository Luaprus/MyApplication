# 后端服务说明

## 1. 安装依赖

```bash
cd backend
npm install
```

## 2. 环境变量

后端使用 `backend/.env` 保存所有敏感配置，不再把第三方密钥放到鸿蒙客户端里。

当前支持的配置项：

- `PORT`
- `DEEPSEEK_API_KEY`
- `DOUBAO_API_KEY`
- `DOUBAO_ENDPOINT_ID`
- `BOOHEE_APP_ID`
- `BOOHEE_APP_KEY`

用途说明：

- `DEEPSEEK_API_KEY`：AI 对话
- `DOUBAO_API_KEY` / `DOUBAO_ENDPOINT_ID`：拍照识别食物热量
- `BOOHEE_APP_ID` / `BOOHEE_APP_KEY`：食物搜索

## 3. 启动后端

推荐开发启动方式：

```bash
cd backend
npm run dev
```

如需文件监听模式：

```bash
npm run dev:watch
```

默认启动地址：

```text
http://localhost:5200
```

## 4. 前端如何连接后端

前端配置文件位置：

- `entry/src/main/ets/config/BackendConfig.ets`

当前模拟器默认值：

```text
http://10.0.2.2:5200/api
```

使用建议：

- 模拟器：继续使用 `http://10.0.2.2:5200/api`
- 真机：请改成你电脑的局域网 IP，例如 `http://192.168.1.20:5200/api`

注意：

- 真机和电脑要在同一个局域网
- 电脑防火墙不要拦截 `5200` 端口

## 5. 当前接口

### 认证相关

- `POST /api/auth/register`：注册账号
- `POST /api/auth/login`：账号密码登录
- `POST /api/auth/onboarding`：首次初始化用户信息
- `POST /api/auth/profile`：更新个人资料
- `POST /api/auth/password`：修改密码

### AI 与业务能力

- `POST /api/ai/chat`：AI 对话，服务端调用 DeepSeek
- `POST /api/ai/vision/food`：图片识别食物热量，服务端调用豆包多模态模型
- `GET /api/foods/search`：食物搜索，服务端调用薄荷食物库

## 6. 当前架构说明

现在项目已经改成“客户端 / 服务端分离”：

- 鸿蒙客户端不直接保存第三方 API Key
- 所有敏感密钥统一放到后端 `.env`
- 客户端只请求你自己的后端

这样做的好处：

- 密钥不会暴露在安装包里
- 后续更换模型或改接口时，只需要改后端
- 登录、AI、识图、食物库都更方便统一管理

## 7. 常见联调问题

### 1）点击演示账号后一直处理中

优先检查：

- 后端是否已经执行 `npm run dev`
- `BackendConfig.ets` 地址是否正确
- 真机是否还在使用 `10.0.2.2`

### 2）真机请求不到后端

通常是以下原因：

- 没改成电脑局域网 IP
- 手机和电脑不在同一个网络
- 电脑防火墙拦截了 `5200` 端口

### 3）后端启动时报 `EACCES`

这台 Windows 机器的 `3100` 端口在系统保留范围内，所以项目已经切到 `5200`。

如果你又改回了 `3100`，很可能会再次遇到端口权限问题。
