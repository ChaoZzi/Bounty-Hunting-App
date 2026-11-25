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
│   ├── bounty-boot/        启动与配置
│   └── db/                 建表 SQL 与演示数据（PostgreSQL 初始化时读取）
├── admin/                  Vue3 管理后台
├── docs/                   技术选型 / 设计规范 / 接口清单 / 本地运行方案
├── scripts/                开机自启等辅助脚本
├── docker-compose.yml      PostgreSQL + Redis
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
| Docker Desktop | 最新 | 可选（用本机原生 PostgreSQL 时不需要） |
| Flutter | 3.x | `D:\dev\flutter` |
| Android SDK | 34+ | `D:\dev\android-sdk` |

---

## 快速开始

### 1. 启动服务

双击 **`start.bat`**

它会自动：启动本机 PostgreSQL 服务（没有服务则用 Docker 起容器）→ 等待数据库就绪 → 用本机 Java 21 启动后端 → 打印手机可用的局域网地址。

首次启动会初始化数据库并写入 5 条演示任务。

验证：

```
http://127.0.0.1:8080/api/v1/health
```

> **架构说明**：数据库是本机原生 PostgreSQL 16（Windows 服务 `postgresql-x64-16`，端口 5432），后端直接跑在本机 Java 上。
> 这样改完代码 `mvn package` 后重启只要几秒，断点调试也能直接用。
> 想改成容器版数据库，用 `docker-compose.yml` 里的 `postgres` 服务（映射到 5433），再把 `application-local.yml` 的端口改掉即可。
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

### 4. 开发调试（推荐用脚本）

```powershell
scripts\run-app.ps1              # 自动探测 IP + 热重载
scripts\run-app.ps1 -Reverse     # 走 USB 反向代理，不需要同一 WiFi
scripts\run-app.ps1 -Release     # 打 release 包
scripts\run-app.ps1 -DryRun      # 只看会执行什么，不真跑
```

它会做四件事：

1. 探测本机局域网 IP（排除 VMware / Hyper-V / WSL 虚拟网卡）
2. 检查后端是否在线，没起会提示先跑 `start.bat`
3. 确认手机已连接且已授权
4. 带上 `--dart-define=API_BASE=http://<ip>:8080` 启动

这样就不会再出现「装上去连 10.0.2.2 连不上」的问题。

---

## 默认账号与地址

| 项 | 值 |
|---|---|
| 后端 | `http://127.0.0.1:8080` |
| 管理后台 | `http://127.0.0.1:8080/admin-ui/`（开发模式 5173） |
| PostgreSQL | `127.0.0.1:5432`，bounty / bounty123456（超级用户 postgres / 123456） |
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

:: 连数据库
psql -h 127.0.0.1 -p 5432 -U bounty -d bounty

:: 重新导入表结构与演示数据（会清空数据）
psql -h 127.0.0.1 -p 5432 -U bounty -d bounty -f server\db\schema.sql
psql -h 127.0.0.1 -p 5432 -U bounty -d bounty -f server\db\data.sql

:: 若走容器版数据库
docker compose ps
docker compose logs -f postgres

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
| App「我的任务」页 | ✅ 四态 Tab、分页、下拉刷新、竞态防护；模型单测 7/7 通过 |

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
| 建表报 `relation "idx_xxx" already exists` | PostgreSQL 的索引名是**全库唯一**的（MySQL 是每表唯一），多张表用同名索引就撞 | 索引 / 唯一约束名统一带表前缀：`idx_task_*` / `uk_pay_*` |
| 写 JSON 列报 `column steps is of type jsonb but expression is of type character varying` | Java 的 `String` 按 varchar 发过去，pgjdbc 不会自动转 jsonb | JDBC url 加 `stringtype=unspecified` |
| 接口中文变乱码 | 导入时客户端编码不是 UTF8 | `psql` 前设 `PGCLIENTENCODING=UTF8`，脚本首行 `SET client_encoding = 'UTF8'` |
| 改了 SQL 但数据没变 | 容器版 `data/postgres` 是 bind mount，`down -v` 删不掉 | 手动删 `data\postgres` 再 `up` |
| 分页 `total` 恒为 0 | 没注册 `PaginationInnerInterceptor` | `MybatisPlusConfig` 里注册 |
| 脚本中文报「字符串未终止」 | Windows PowerShell 5.1 按 GBK 读 UTF-8 脚本 | `.ps1` 必须存成 **UTF-8 with BOM** |
| `Unable to access jarfile D:\Bounty` | 路径含空格没加引号 | `-ArgumentList` 里给 jar 路径套 `"` |
| Gradle 下载 `zip END header not found` | 镜像给的是坏包 | curl 手动下 + `distributionUrl=file:///...` |
| Kotlin 增量缓存 `Could not close incremental caches` | 文件被占用 | `gradle.properties` 里 `kotlin.incremental=false` |
| Docker Hub 拉不下来 | 直连被墙 | 从 `docker.m.daocloud.io` 拉再 `docker tag` |
| `ninja: FindFirstFileExA ... 语法不正确` | 用户名含中文，Ninja 处理不了 `C:\Users\姜盛超\AppData\...` | 设 `PUB_CACHE=D:\dev\pub-cache`，再 `flutter clean && flutter pub get` |
| `git push` 报 `Host key verification failed` | Git 自带 SSH 解析不了中文用户名，找不到 known_hosts | `git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"` |

---

## 文档

| 文档 | 内容 |
|---|---|
| [技术选型方案](docs/技术选型方案.md) | 为什么这么选、架构、排期、成本 |
| [设计规范](docs/设计规范.md) | 黑金视觉、动效曲线、音效清单 |
| [接口清单](docs/接口清单.md) | 80+ 接口契约、状态机、错误码 |
| [本地运行方案](docs/本地运行方案.md) | Docker、手机连接、Mock 策略、常见坑 |
