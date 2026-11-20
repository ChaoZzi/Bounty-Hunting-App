package com.bounty.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("t_task_order")
public class TaskOrder {

    /** 状态：0待接单 1进行中 2待审核 3已通过 4已驳回 5已超时 6已结算 7已取消 */
    public static final int STATUS_DOING = 1;
    public static final int STATUS_REVIEWING = 2;
    public static final int STATUS_APPROVED = 3;
    public static final int STATUS_REJECTED = 4;
    public static final int STATUS_TIMEOUT = 5;
    public static final int STATUS_SETTLED = 6;

    @TableId(type = IdType.AUTO)
    private Long id;

    private String orderNo;
    private Long taskId;
    private Long userId;
    private Long publisherId;
    private BigDecimal amount;
    private Integer status;
    private LocalDateTime applyAt;
    private LocalDateTime deadlineAt;
    private LocalDateTime submitAt;
    private LocalDateTime reviewAt;
    private String reviewRemark;
    private LocalDateTime settleAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
