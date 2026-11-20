-- ============================================================
-- 悬赏平台 数据库 Schema v0.1
-- MySQL 8.0 / InnoDB / utf8mb4
-- 约定：
--   1. 主键统一 BIGINT UNSIGNED AUTO_INCREMENT
--   2. 金额统一 DECIMAL(12,2)，禁止 FLOAT/DOUBLE
--   3. 状态字段用 TINYINT + 注释枚举，不用 ENUM 类型
--   4. 软删除统一 deleted TINYINT（0 正常 / 1 删除）
--   5. 所有时间 DATETIME，业务时间由应用层写入
--   6. 不加物理外键，一致性由应用层保证
-- ============================================================

CREATE DATABASE IF NOT EXISTS `bounty`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE `bounty`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- 1. 用户
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_user`;
CREATE TABLE `t_user` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `phone`           VARCHAR(20)     NOT NULL                COMMENT '手机号（登录账号）',
  `nickname`        VARCHAR(64)     NOT NULL DEFAULT ''     COMMENT '昵称',
  `avatar`          VARCHAR(255)    NOT NULL DEFAULT ''     COMMENT '头像 URL',
  `gender`          TINYINT         NOT NULL DEFAULT 0      COMMENT '0未知 1男 2女',
  `status`          TINYINT         NOT NULL DEFAULT 1      COMMENT '1正常 0封禁 2注销中',
  `credit_score`    INT             NOT NULL DEFAULT 1000   COMMENT '信誉分 0-10000',
  `realname_status` TINYINT         NOT NULL DEFAULT 0      COMMENT '0未认证 1审核中 2已认证 3认证失败',
  `is_publisher`    TINYINT         NOT NULL DEFAULT 0      COMMENT '1 曾发布过任务',
  `member_level`    TINYINT         NOT NULL DEFAULT 0      COMMENT '0普通 1年卡',
  `member_expire_at` DATETIME       NULL                    COMMENT '会员到期时间',
  `invite_code`     VARCHAR(16)     NULL                    COMMENT '我的邀请码（注册时生成）',
  `inviter_id`      BIGINT UNSIGNED NOT NULL DEFAULT 0      COMMENT '邀请人 ID',
  `register_ip`     VARCHAR(64)     NOT NULL DEFAULT ''     COMMENT '注册 IP',
  `device_id`       VARCHAR(64)     NOT NULL DEFAULT ''     COMMENT '注册设备指纹',
  `last_login_at`   DATETIME        NULL,
  `created_at`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT         NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_phone`       (`phone`),
  UNIQUE KEY `uk_invite_code` (`invite_code`),
  KEY `idx_inviter`  (`inviter_id`),
  KEY `idx_device`   (`device_id`),
  KEY `idx_created`  (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

-- ------------------------------------------------------------
-- 2. 实名认证
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_user_realname`;
CREATE TABLE `t_user_realname` (
  `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`        BIGINT UNSIGNED NOT NULL,
  `real_name`      VARCHAR(128)    NOT NULL                COMMENT '姓名（AES-GCM 密文）',
  `id_card_cipher` VARCHAR(255)    NOT NULL                COMMENT '身份证号（AES-GCM 密文）',
  `id_card_hash`   CHAR(64)        NOT NULL                COMMENT '身份证 SHA256，用于唯一性校验',
  `id_card_mask`   VARCHAR(24)     NOT NULL DEFAULT ''     COMMENT '脱敏展示 如 3301**********1234',
  `phone`          VARCHAR(20)     NOT NULL DEFAULT '',
  `status`         TINYINT         NOT NULL DEFAULT 1      COMMENT '1审核中 2通过 3驳回',
  `channel`        TINYINT         NOT NULL DEFAULT 1      COMMENT '1三要素核验 2人工 3人脸',
  `reject_reason`  VARCHAR(255)    NOT NULL DEFAULT '',
  `verified_at`    DATETIME        NULL,
  `created_at`     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user`   (`user_id`),
  UNIQUE KEY `uk_idcard` (`id_card_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='实名认证';

-- ------------------------------------------------------------
-- 3. 钱包（一人一行，只做记账，不存真钱）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_wallet`;
CREATE TABLE `t_wallet` (
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `available`     DECIMAL(12,2)   NOT NULL DEFAULT 0.00   COMMENT '可用余额',
  `frozen`        DECIMAL(12,2)   NOT NULL DEFAULT 0.00   COMMENT '冻结（提现中）',
  `pending`       DECIMAL(12,2)   NOT NULL DEFAULT 0.00   COMMENT '待结算（任务审核中）',
  `total_income`  DECIMAL(12,2)   NOT NULL DEFAULT 0.00   COMMENT '累计收入',
  `total_withdraw` DECIMAL(12,2)  NOT NULL DEFAULT 0.00   COMMENT '累计提现',
  `version`       INT             NOT NULL DEFAULT 0      COMMENT '乐观锁',
  `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户钱包';

-- ------------------------------------------------------------
-- 4. 资金流水（唯一可信账本，余额只能由它推导）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_wallet_flow`;
CREATE TABLE `t_wallet_flow` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `biz_no`        VARCHAR(64)     NOT NULL                COMMENT '业务幂等号，唯一',
  `biz_type`      VARCHAR(32)     NOT NULL                COMMENT 'TASK_INCOME/INVITE_REWARD/WITHDRAW/WITHDRAW_REFUND/MEMBER/PROMOTION/ADJUST',
  `biz_id`        BIGINT UNSIGNED NOT NULL DEFAULT 0      COMMENT '关联业务主键',
  `direction`     TINYINT         NOT NULL                COMMENT '1 收入 -1 支出',
  `amount`        DECIMAL(12,2)   NOT NULL,
  `balance_after` DECIMAL(12,2)   NOT NULL                COMMENT '变动后可用余额快照',
  `remark`        VARCHAR(255)    NOT NULL DEFAULT '',
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_biz_no` (`biz_no`),
  KEY `idx_user_time` (`user_id`, `created_at`),
  KEY `idx_type_time` (`biz_type`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资金流水';

-- ------------------------------------------------------------
-- 5. 任务分类
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_task_category`;
CREATE TABLE `t_task_category` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(32)  NOT NULL,
  `icon`       VARCHAR(255) NOT NULL DEFAULT '',
  `sort`       INT          NOT NULL DEFAULT 0,
  `status`     TINYINT      NOT NULL DEFAULT 1,
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务分类';

-- ------------------------------------------------------------
-- 6. 任务
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_task`;
CREATE TABLE `t_task` (
  `id`              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `publisher_id`    BIGINT UNSIGNED NOT NULL              COMMENT '悬赏主 user_id',
  `category_id`     INT UNSIGNED    NOT NULL DEFAULT 0,
  `title`           VARCHAR(128)    NOT NULL,
  `cover`           VARCHAR(255)    NOT NULL DEFAULT '',
  `intro`           VARCHAR(512)    NOT NULL DEFAULT ''   COMMENT '一句话简介',
  `steps`           JSON            NULL                  COMMENT '[{"step":1,"desc":"..."}]',
  `rules`           TEXT            NULL                  COMMENT '任务要求/注意事项',
  `unit_price`      DECIMAL(10,2)   NOT NULL              COMMENT '单个赏金',
  `service_fee_rate` DECIMAL(6,4)   NOT NULL DEFAULT 0.1000 COMMENT '平台服务费率',
  `total_quota`     INT             NOT NULL              COMMENT '总名额',
  `taken_quota`     INT             NOT NULL DEFAULT 0    COMMENT '已报名数',
  `finished_quota`  INT             NOT NULL DEFAULT 0    COMMENT '已完成数',
  `remain_quota`    INT             NOT NULL DEFAULT 0    COMMENT '剩余名额（Redis 为准，此处为快照）',
  `limit_per_user`  TINYINT         NOT NULL DEFAULT 1    COMMENT '每人限做次数',
  `age_limit`       TINYINT         NOT NULL DEFAULT 18   COMMENT '最低年龄，0 不限',
  `deadline_minutes` INT            NOT NULL DEFAULT 1440 COMMENT '报名后完成时限（分钟）',
  `audit_status`    TINYINT         NOT NULL DEFAULT 0    COMMENT '0待审 1通过 2驳回',
  `audit_remark`    VARCHAR(255)    NOT NULL DEFAULT '',
  `status`          TINYINT         NOT NULL DEFAULT 0    COMMENT '0草稿 1待上架 2展示中 3已暂停 4已结束 5审核失败',
  `fast_review`     TINYINT         NOT NULL DEFAULT 0    COMMENT '1 极速快审',
  `top_until`       DATETIME        NULL                  COMMENT '置顶到期时间',
  `weight`          INT             NOT NULL DEFAULT 0    COMMENT '排序权重（置顶/快审/人工干预）',
  `view_count`      INT             NOT NULL DEFAULT 0,
  `start_at`        DATETIME        NULL                  COMMENT '任务开始时间',
  `end_at`          DATETIME        NULL                  COMMENT '任务截止时间',
  `created_at`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted`         TINYINT         NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_hall`      (`status`, `deleted`, `weight` DESC, `created_at` DESC),
  KEY `idx_publisher` (`publisher_id`, `status`),
  KEY `idx_category`  (`category_id`, `status`),
  KEY `idx_audit`     (`audit_status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='悬赏任务';

-- ------------------------------------------------------------
-- 7. 报名单（核心业务表）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_task_order`;
CREATE TABLE `t_task_order` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_no`      VARCHAR(32)     NOT NULL                COMMENT '业务单号',
  `task_id`       BIGINT UNSIGNED NOT NULL,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `publisher_id`  BIGINT UNSIGNED NOT NULL,
  `amount`        DECIMAL(10,2)   NOT NULL                COMMENT '成交赏金',
  `status`        TINYINT         NOT NULL DEFAULT 0      COMMENT '0待接单 1进行中 2待审核 3已通过 4已驳回 5已超时 6已结算 7已取消',
  `apply_at`      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deadline_at`   DATETIME        NOT NULL                COMMENT '完成截止时间',
  `submit_at`     DATETIME        NULL,
  `review_at`     DATETIME        NULL,
  `review_remark` VARCHAR(255)    NOT NULL DEFAULT '',
  `settle_at`     DATETIME        NULL,
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no`  (`order_no`),
  UNIQUE KEY `uk_task_user` (`task_id`, `user_id`),
  KEY `idx_user_status` (`user_id`, `status`, `created_at`),
  KEY `idx_task_status` (`task_id`, `status`),
  KEY `idx_deadline`    (`status`, `deadline_at`),
  KEY `idx_settle`      (`status`, `settle_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务报名单';

-- ------------------------------------------------------------
-- 8. 提交凭证
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_task_submission`;
CREATE TABLE `t_task_submission` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`   BIGINT UNSIGNED NOT NULL,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `images`     JSON            NOT NULL                   COMMENT '["https://oss/...jpg"]',
  `content`    VARCHAR(1000)   NOT NULL DEFAULT ''        COMMENT '文字说明',
  `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order` (`order_id`),
  KEY `idx_user`  (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='任务提交凭证';

-- ------------------------------------------------------------
-- 9. 审核日志
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_task_review_log`;
CREATE TABLE `t_task_review_log` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id`      BIGINT UNSIGNED NOT NULL,
  `reviewer_type` TINYINT         NOT NULL                COMMENT '1系统 2平台人工 3悬赏主',
  `reviewer_id`   BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `result`        TINYINT         NOT NULL                COMMENT '1通过 2驳回',
  `reason`        VARCHAR(255)    NOT NULL DEFAULT '',
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审核日志';

-- ------------------------------------------------------------
-- 10. 提现单
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_withdraw`;
CREATE TABLE `t_withdraw` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `withdraw_no`   VARCHAR(32)     NOT NULL,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `amount`        DECIMAL(12,2)   NOT NULL                COMMENT '申请金额',
  `fee`           DECIMAL(12,2)   NOT NULL DEFAULT 0.00   COMMENT '手续费',
  `actual_amount` DECIMAL(12,2)   NOT NULL                COMMENT '实际到账',
  `channel`       TINYINT         NOT NULL DEFAULT 1      COMMENT '1支付宝 2微信 3银行卡',
  `account`       VARCHAR(128)    NOT NULL                COMMENT '收款账号',
  `account_name`  VARCHAR(64)     NOT NULL                COMMENT '收款姓名',
  `status`        TINYINT         NOT NULL DEFAULT 0      COMMENT '0待审核 1审核通过 2打款中 3成功 4失败 5驳回',
  `third_no`      VARCHAR(64)     NOT NULL DEFAULT ''     COMMENT '支付宝转账单号',
  `fail_reason`   VARCHAR(255)    NOT NULL DEFAULT '',
  `audit_by`      BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `audit_at`      DATETIME        NULL,
  `paid_at`       DATETIME        NULL,
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_withdraw_no` (`withdraw_no`),
  KEY `idx_user`   (`user_id`, `created_at`),
  KEY `idx_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='提现单';

-- ------------------------------------------------------------
-- 11. 支付订单（充值 / 会员 / 增值服务）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_pay_order`;
CREATE TABLE `t_pay_order` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_no`   VARCHAR(32)     NOT NULL,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `biz_type`   TINYINT         NOT NULL                COMMENT '1任务充值 2会员 3增值服务',
  `biz_id`     BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `amount`     DECIMAL(12,2)   NOT NULL,
  `channel`    TINYINT         NOT NULL DEFAULT 1      COMMENT '1支付宝 2微信',
  `status`     TINYINT         NOT NULL DEFAULT 0      COMMENT '0待支付 1已支付 2已关闭 3已退款',
  `third_no`   VARCHAR(64)     NOT NULL DEFAULT ''     COMMENT '第三方交易号',
  `pay_at`     DATETIME        NULL,
  `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  UNIQUE KEY `uk_third_no` (`third_no`),
  KEY `idx_user`   (`user_id`, `created_at`),
  KEY `idx_status` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付订单';

-- ------------------------------------------------------------
-- 12. 增值服务订单（置顶/刷新/加价/加量/快审）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_promotion_order`;
CREATE TABLE `t_promotion_order` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_no`      VARCHAR(32)     NOT NULL,
  `task_id`       BIGINT UNSIGNED NOT NULL,
  `publisher_id`  BIGINT UNSIGNED NOT NULL,
  `type`          VARCHAR(20)     NOT NULL              COMMENT 'TOP/TOP_SCHEDULED/AUTO_REFRESH/TOP_PACK/REFRESH_PACK/RAISE_PRICE/ADD_QUOTA/FAST_REVIEW',
  `qty`           INT             NOT NULL DEFAULT 1    COMMENT '购买数量（包类型用）',
  `unit_price`    DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
  `amount`        DECIMAL(12,2)   NOT NULL,
  `effect_start`  DATETIME        NULL,
  `effect_end`    DATETIME        NULL,
  `status`        TINYINT         NOT NULL DEFAULT 0    COMMENT '0待生效 1生效中 2已结束 3已取消',
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_task` (`task_id`, `status`),
  KEY `idx_publisher` (`publisher_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='增值服务订单';

-- ------------------------------------------------------------
-- 13. 邀请关系
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_invite`;
CREATE TABLE `t_invite` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `inviter_id`    BIGINT UNSIGNED NOT NULL,
  `invitee_id`    BIGINT UNSIGNED NOT NULL,
  `reward_amount` DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
  `reward_status` TINYINT         NOT NULL DEFAULT 0    COMMENT '0待发放 1已发放 2已失效',
  `reward_at`     DATETIME        NULL,
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_invitee` (`invitee_id`),
  KEY `idx_inviter` (`inviter_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='邀请关系';

-- ------------------------------------------------------------
-- 14. 信誉分变动
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_credit_log`;
CREATE TABLE `t_credit_log` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`       BIGINT UNSIGNED NOT NULL,
  `change_value`  INT             NOT NULL             COMMENT '正数加，负数减',
  `balance_after` INT             NOT NULL,
  `reason`        VARCHAR(64)     NOT NULL             COMMENT 'TASK_DONE/TASK_TIMEOUT/REJECTED/INVITE/ADMIN_ADJUST',
  `biz_id`        BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `remark`        VARCHAR(255)    NOT NULL DEFAULT '',
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='信誉分流水';

-- ------------------------------------------------------------
-- 15. 站内信
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_message`;
CREATE TABLE `t_message` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `type`       TINYINT         NOT NULL              COMMENT '1系统 2任务 3钱包 4审核 5活动',
  `title`      VARCHAR(64)     NOT NULL,
  `content`    VARCHAR(500)    NOT NULL DEFAULT '',
  `biz_id`     BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `is_read`    TINYINT         NOT NULL DEFAULT 0,
  `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_read` (`user_id`, `is_read`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='站内信';

-- ------------------------------------------------------------
-- 16. 运营位 / Banner
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_banner`;
CREATE TABLE `t_banner` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `position`   VARCHAR(32)  NOT NULL              COMMENT 'HOME_TOP/MORE_EARN/MINE_TOP',
  `title`      VARCHAR(64)  NOT NULL DEFAULT '',
  `image`      VARCHAR(255) NOT NULL,
  `link_type`  TINYINT      NOT NULL DEFAULT 0    COMMENT '0无 1任务 2H5 3会员 4邀请',
  `link_value` VARCHAR(255) NOT NULL DEFAULT '',
  `sort`       INT          NOT NULL DEFAULT 0,
  `status`     TINYINT      NOT NULL DEFAULT 1,
  `start_at`   DATETIME     NULL,
  `end_at`     DATETIME     NULL,
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_position` (`position`, `status`, `sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='运营位';

-- ------------------------------------------------------------
-- 17. 后台账号
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_admin_user`;
CREATE TABLE `t_admin_user` (
  `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username`      VARCHAR(32)     NOT NULL,
  `password_hash` VARCHAR(128)    NOT NULL,
  `salt`          VARCHAR(32)     NOT NULL DEFAULT '',
  `real_name`     VARCHAR(32)     NOT NULL DEFAULT '',
  `role`          VARCHAR(20)     NOT NULL DEFAULT 'OPERATOR'  COMMENT 'ADMIN/FINANCE/AUDITOR/OPERATOR',
  `status`        TINYINT         NOT NULL DEFAULT 1,
  `last_login_at` DATETIME        NULL,
  `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台账号';

-- ------------------------------------------------------------
-- 18. 后台操作审计
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_admin_log`;
CREATE TABLE `t_admin_log` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `admin_id`   BIGINT UNSIGNED NOT NULL,
  `action`     VARCHAR(64)     NOT NULL             COMMENT 'TASK_AUDIT/WITHDRAW_AUDIT/REALNAME_AUDIT/...',
  `target_id`  BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `detail`     TEXT            NULL                 COMMENT '变更前后 JSON',
  `ip`         VARCHAR(64)     NOT NULL DEFAULT '',
  `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin` (`admin_id`, `created_at`),
  KEY `idx_action` (`action`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台操作日志';

-- ------------------------------------------------------------
-- 19. 设备与风险标记
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_risk_device`;
CREATE TABLE `t_risk_device` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id`  VARCHAR(64)     NOT NULL,
  `user_id`    BIGINT UNSIGNED NOT NULL,
  `ip`         VARCHAR(64)     NOT NULL DEFAULT '',
  `risk_level` TINYINT         NOT NULL DEFAULT 0   COMMENT '0正常 1观察 2限制 3封禁',
  `risk_tags`  VARCHAR(255)    NOT NULL DEFAULT ''  COMMENT '多账号/模拟器/改机/黑名单IP',
  `last_seen`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_device` (`device_id`),
  KEY `idx_user`   (`user_id`),
  KEY `idx_level`  (`risk_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备风险';

-- ------------------------------------------------------------
-- 20. 系统配置
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_sys_config`;
CREATE TABLE `t_sys_config` (
  `config_key`   VARCHAR(64)  NOT NULL,
  `config_value` VARCHAR(1000) NOT NULL DEFAULT '',
  `remark`       VARCHAR(255) NOT NULL DEFAULT '',
  `updated_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置';

-- ------------------------------------------------------------
-- 21. 短信日志（防刷 + 成本核算）
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `t_sms_log`;
CREATE TABLE `t_sms_log` (
  `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `phone`      VARCHAR(20)     NOT NULL,
  `scene`      VARCHAR(32)     NOT NULL              COMMENT 'LOGIN/BIND/WITHDRAW_NOTIFY',
  `code`       VARCHAR(8)      NOT NULL DEFAULT '',
  `ip`         VARCHAR(64)     NOT NULL DEFAULT '',
  `status`     TINYINT         NOT NULL DEFAULT 0    COMMENT '0发送中 1成功 2失败',
  `biz_id`     VARCHAR(64)     NOT NULL DEFAULT '',
  `created_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_phone_time` (`phone`, `created_at`),
  KEY `idx_ip_time`    (`ip`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='短信发送日志';

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 初始化数据
-- ============================================================

INSERT INTO `t_task_category` (`id`, `name`, `sort`) VALUES
  (1, '应用试玩', 100),
  (2, '注册下载', 90),
  (3, '问卷调研', 80),
  (4, '游戏试玩', 70),
  (5, '内容体验', 60),
  (6, '探店打卡', 50),
  (7, '其他', 10);

INSERT INTO `t_sys_config` (`config_key`, `config_value`, `remark`) VALUES
  ('withdraw.min_amount',      '1.00',   '最低提现金额'),
  ('withdraw.fee_rate',        '0.0000', '提现手续费率'),
  ('withdraw.day_limit',       '3',      '每日提现次数上限'),
  ('withdraw.audit_mode',      '1',      '0自动 1人工审核'),
  ('task.service_fee_rate',    '0.1000', '平台服务费率'),
  ('task.audit_mode',          '1',      '0自动 1人工审核'),
  ('task.min_price',           '0.10',   '任务最低单价'),
  ('task.max_price',           '1000.00','任务最高单价'),
  ('user.credit_init',         '1000',   '初始信誉分'),
  ('user.credit_max',          '10000',  '信誉分上限'),
  ('invite.reward_amount',     '1.00',   '邀请奖励金额'),
  ('invite.reward_condition',  '1',      '被邀请人完成首单后发放'),
  ('member.year_price',        '99.00',  '年卡价格'),
  ('promotion.top_price',      '5.00',   '置顶每小时价格'),
  ('promotion.refresh_price',  '0.50',   '单次刷新价格'),
  ('promotion.fast_review_price','1.00',  '快审单条价格'),
  ('app.version_code',         '1',      '当前最新版本号'),
  ('app.version_name',         '1.0.0',  '当前最新版本名'),
  ('app.download_url',         '',       'APK 下载地址');

INSERT INTO `t_admin_user` (`username`, `password_hash`, `real_name`, `role`)
VALUES ('admin', 'CHANGE_ME_BCRYPT', '超级管理员', 'ADMIN');
