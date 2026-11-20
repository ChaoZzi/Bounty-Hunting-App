package com.bounty.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("t_withdraw")
public class Withdraw {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String withdrawNo;
    private Long userId;
    private BigDecimal amount;
    private BigDecimal fee;
    private BigDecimal actualAmount;
    private Integer channel;
    private String account;
    private String accountName;
    /** 0待审核 1审核通过 2打款中 3成功 4失败 5驳回 */
    private Integer status;
    private String thirdNo;
    private String failReason;
    private Long auditBy;
    private LocalDateTime auditAt;
    private LocalDateTime paidAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
