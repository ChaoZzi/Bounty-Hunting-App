# 悬赏平台（本地版）

个人开发 · 仅 Android · 本地部署 · 不上线

一套可运行的悬赏任务平台骨架：**Flutter 客户端 + Java 单体后端 + Vue3 管理后台**。

---

## 目录结构

```
Bounty Hunting App/
├── app/                    Flutter 客户端（Android）
├── server/                 Java 后端（Maven 多模块单体）
│   ├── bounty-common/      通用：Result、异常、上下文、工具
│   ├── bounty-dao/         实体与 Mapper
│   ├── bounty-service/     业务逻辑
│   ├── bounty-api/         接口层
│   ├── bounty-job/         定时任务
│   └── bounty-boot/        启动与配置
├── admin/                  Vue3 管理后台
├── db/                     建表脚本与演示数据
├── docs/                   技术选型 / 设计规范 / 接口清单 / 本地运行方案
├── scripts/                开机自启等辅助脚本
├── docker-compose.yml      MySQL + Redis + 后端
├── start.bat               一键启动
└── stop.bat                停止
```

---

## 环境要求

| 软件 | 版本 | 说明 |
|---|---|---|
| JDK | 21 | 已装 |
| Maven | 3.9+ | 已装 |
| Node.js | 18+ | 已装 |
| Docker Desktop | 最新 | 必须运行 |
| Flutter | 3.x | `D:\dev\flutter` |
| Android SDK | 34+ | `D:\dev\android-sdk` |

---

## 快速开始

### 1. 启动服务

双击 **`start.bat`**

它会自动：启动 Docker → 拉起 mysql / redis 容器 → 等待数据库就绪 → 用本机 Java 21 启动后端 → 打印手机可用的局域网地址。

首次启动会初始化数据库并写入 5 条演示任务。

验证：

```
http://127.0.0.1:8080/api/v1/health
```

> **架构说明**：数据库跑在 Docker 里，后端直接跑在本机 Java 上。
> 这样改完代码 `mvn package` 后重启只要几秒，断点调试也能直接用；
> 数据库仍然隔离在容器里，不污染 Windows，随时可以 `down` 掉重来。
> `server/Dockerfile` 保留着，将来整套搬到服务器时才用。

### 2. 打开管理后台

**日常使用**（不需要 node，`start.bat` 起完就能开）：

```
http://127.0.0.1:8080/admin-ui/
   或
http://192.168.31.156:8080/admin-ui/     ← 手机同 WiFi 也能开
```

账号 `admin` / 密码 `admin123`

> 原理：`npm run build` 的产物在 `admin/dist/`，后端把 `/admin-ui/**` 映射到这个目录。
> 所以只要后端在跑，后台就能访问，重启电脑也不会丢。

**改前端代码时**（需要热重载）才用：

```bat
start-admin.bat
```

打开 `http://127.0.0.1:5173/admin-ui/`，改完代码浏览器自动刷新。

> 注意：`vite.config.ts` 里 `base: '/admin-ui/'` 是为了让打包产物能挂在后端路径下。
> 如果改了 base，记得两边一起改。改完要重新 `npm run build`，`/admin-ui/` 才会更新。

### 3. 打包安装 App

```bash
cd app
flutter pub get
flutter build apk --release --dart-define=API_BASE=http://<你电脑的局域网IP>:8080
```

产物：`app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

传到手机安装（数据线 / 微信文件传输助手 / 局域网下载）。

> 启动 App 后可在「设置」里直接修改服务器地址，IP 变了不用重新打包。

---

## 默认账号与地址

| 项 | 值 |
|---|---|
| 后端 | `http://127.0.0.1:8080` |
| 管理后台 | `http://127.0.0.1:8080/admin-ui/`（开发模式 5173） |
| MySQL | `127.0.0.1:3307`，root / root123456 |
| Redis | `127.0.0.1:6380` |
| 后台账号 | admin / admin123 |
| 短信验证码 | **固定 `123456`**（本地 Mock，可重复使用） |
| 演示数据 | 5 条任务，发布者「官方小助手」 |

---

## 常用命令

```bat
:: 启动 / 停止全部
start.bat
stop.bat

:: 只重启后端（改完代码后）
cd server && mvn -DskipTests package && cd ..
powershell -File scripts\start-backend.ps1
powershell -File scripts\stop-backend.ps1

:: 只看数据库容器
docker compose ps
docker compose logs -f mysql

:: 数据库整个重置（会清空数据，并重新导入演示数据）
docker compose down
rmdir /s /q data\mysql
docker compose up -d

:: 后端日志
Get-Content logs\app.log -Wait -Tail 50
```

---

## 开机自启

右键「使用 PowerShell 运行」：

```
scripts/install-autostart.ps1
```

登录 Windows 后自动拉起 Docker 和服务。取消：

```powershell
Unregister-ScheduledTask -TaskName BountyAppServer -Confirm:$false
```

---

## 本地 Mock 说明

| 能力 | 本地行为 | 上线时替换为 |
|---|---|---|
| 短信验证码 | 固定 `123456`，日志打印 | 阿里云短信 |
| 支付 | 直接置成功 | 支付宝 App 支付 |
| 实名认证 | 提交即通过 | 三要素 / 人脸核身 |
| 文件存储 | 本地磁盘 `data/upload` | 阿里云 OSS |
| 推送 | 无，App 启动拉未读数 | 极光推送 |
| 提现打款 | 直接置成功，不真实转账 | 支付宝转账到账户 |

**业务代码不因 Mock 而简化**：资金流水、订单状态机、实名门槛校验都按真实逻辑跑。

---

## 已实现并已验证

| 功能 | 验证结果 |
|---|---|
| 短信登录 / 自动注册 / Token | ✅ 新用户自动建号并开钱包 |
| 任务大厅（5 种排序、分页） | ✅ 5 条演示任务，`total` 正确 |
| 任务详情 / 报名 | ✅ 报名成功，名额 285 → 284 |
| 重复报名拦截 | ✅ 返回 `1004 你已报名过该任务` |
| 我的任务（四态分组） | ✅ 报名后出现在「进行中」 |
| 钱包概览 | ✅ 可用 / 冻结 / 待结算 |
| 管理后台登录 / 总览 | ✅ 用户 2、任务 5、报名 1 |
| 管理后台任务列表 / 审核接口 | ✅ 分页正常 |
| 超时关单定时任务 | ✅ 含**开机补偿**：关机期间到期的单子，启动后一次性处理 |

## 待实现

- 提交凭证（图片上传）
- 审核通过 → 结算 → 资金流水
- 提现申请与打款
- 悬赏主发布 / 管理任务
- 增值服务（置顶 / 刷新 / 加价 / 加量 / 快审）
- 邀请裂变、会员、消息中心

---

## 踩过的坑（记下来，别再踩）

| 现象 | 原因 | 解法 |
|---|---|---|
| 接口中文变乱码 | `data.sql` 缺 `SET NAMES utf8mb4`，导入时双重编码 | 文件首行加 `SET NAMES utf8mb4` |
| 改了 SQL 但数据没变 | `data/mysql` 是 bind mount，`down -v` 删不掉 | 手动删 `data\mysql` 再 `up` |
| 分页 `total` 恒为 0 | 没注册 `PaginationInnerInterceptor` | `MybatisPlusConfig` 里注册 |
| 脚本中文报「字符串未终止」 | Windows PowerShell 5.1 按 GBK 读 UTF-8 脚本 | `.ps1` 必须存成 **UTF-8 with BOM** |
| `Unable to access jarfile D:\Bounty` | 路径含空格没加引号 | `-ArgumentList` 里给 jar 路径套 `"` |
| Gradle 下载 `zip END header not found` | 镜像给的是坏包 | curl 手动下 + `distributionUrl=file:///...` |
| Kotlin 增量缓存 `Could not close incremental caches` | 文件被占用 | `gradle.properties` 里 `kotlin.incremental=false` |
| Docker Hub 拉不下来 | 直连被墙 | 从 `docker.m.daocloud.io` 拉再 `docker tag` |

---

## 文档

| 文档 | 内容 |
|---|---|
| [技术选型方案](docs/技术选型方案.md) | 为什么这么选、架构、排期、成本 |
| [设计规范](docs/设计规范.md) | 黑金视觉、动效曲线、音效清单 |
| [接口清单](docs/接口清单.md) | 80+ 接口契约、状态机、错误码 |
| [本地运行方案](docs/本地运行方案.md) | Docker、手机连接、Mock 策略、常见坑 |
