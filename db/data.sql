-- ============================================================
-- 演示数据（本地开发用，生产环境不要执行）
-- ============================================================
SET NAMES utf8mb4;
USE `bounty`;

-- 官方账号（任务发布者）
INSERT INTO `t_user` (`id`, `phone`, `nickname`, `avatar`, `gender`, `status`, `credit_score`,
                      `realname_status`, `is_publisher`, `member_level`, `invite_code`, `inviter_id`,
                      `created_at`, `updated_at`, `deleted`)
VALUES (1, '13800000000', '官方小助手', '', 0, 1, 5000, 2, 1, 0, 'OFFICIAL', 0, NOW(), NOW(), 0);

INSERT INTO `t_wallet` (`user_id`, `available`, `frozen`, `pending`, `total_income`, `total_withdraw`, `version`)
VALUES (1, 0.00, 0.00, 0.00, 0.00, 0.00, 0);

-- 演示任务
INSERT INTO `t_task`
(`publisher_id`, `category_id`, `title`, `cover`, `intro`, `steps`, `rules`, `unit_price`,
 `service_fee_rate`, `total_quota`, `taken_quota`, `finished_quota`, `remain_quota`,
 `limit_per_user`, `age_limit`, `deadline_minutes`, `audit_status`, `status`,
 `fast_review`, `weight`, `view_count`, `created_at`, `updated_at`, `deleted`)
VALUES
(1, 1, '打开应用停留 30 秒', '', '简单试玩，秒过',
 '[{"step":1,"desc":"从应用商店下载并打开"},{"step":2,"desc":"停留 30 秒以上"},{"step":3,"desc":"截图首页"}]',
 '需为首次安装，截图需清晰可见应用名称', 0.37, 0.1000, 1600, 0, 0, 1600, 1, 0, 1440, 1, 2, 1, 100, 4667, NOW(), NOW(), 0),

(1, 2, '注册并完成实名认证', '', '新用户专享，审核快',
 '[{"step":1,"desc":"点击链接注册"},{"step":2,"desc":"完成手机号验证"},{"step":3,"desc":"截图个人中心"}]',
 '同一身份证仅可参与一次', 3.17, 0.1000, 300, 0, 0, 300, 1, 18, 720, 1, 2, 1, 120, 5170, NOW(), NOW(), 0),

(1, 3, '填写一份 3 分钟问卷', '', '共 12 题，无标准答案',
 '[{"step":1,"desc":"打开问卷链接"},{"step":2,"desc":"按真实情况作答"},{"step":3,"desc":"截图提交成功页"}]',
 '乱填会被驳回', 1.88, 0.1000, 200, 0, 0, 200, 1, 0, 1440, 1, 2, 0, 80, 4186, NOW(), NOW(), 0),

(1, 4, '试玩小游戏通关前三关', '', '休闲益智，5 分钟搞定',
 '[{"step":1,"desc":"下载并安装游戏"},{"step":2,"desc":"通关前三关"},{"step":3,"desc":"截图关卡界面"}]',
 '需要真实游玩记录，禁止使用外挂', 3.20, 0.1000, 285, 0, 0, 285, 1, 0, 2880, 1, 2, 0, 90, 5338, NOW(), NOW(), 0),

(1, 5, '体验文章并点赞收藏', '', '内容体验，操作简单',
 '[{"step":1,"desc":"打开文章链接"},{"step":2,"desc":"阅读完毕并点赞收藏"},{"step":3,"desc":"截图点赞状态"}]',
 '需保持点赞状态 24 小时', 0.32, 0.1000, 4657, 0, 0, 4657, 1, 0, 1440, 1, 2, 0, 70, 28522, NOW(), NOW(), 0);
