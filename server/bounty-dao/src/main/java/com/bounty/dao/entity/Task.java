package com.bounty.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("t_task")
public class Task {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long publisherId;
    private Integer categoryId;
    private String title;
    private String cover;
    private String intro;
    private String steps;
    private String rules;
    private BigDecimal unitPrice;
    private BigDecimal serviceFeeRate;
    private Integer totalQuota;
    private Integer takenQuota;
    private Integer finishedQuota;
    private Integer remainQuota;
    private Integer limitPerUser;
    private Integer ageLimit;
    private Integer deadlineMinutes;
    private Integer auditStatus;
    private String auditRemark;
    private Integer status;
    private Integer fastReview;
    private LocalDateTime topUntil;
    private Integer weight;
    private Integer viewCount;
    private LocalDateTime startAt;
    private LocalDateTime endAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @TableLogic
    private Integer deleted;
}
