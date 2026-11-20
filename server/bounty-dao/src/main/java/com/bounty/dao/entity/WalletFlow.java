package com.bounty.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("t_wallet_flow")
public class WalletFlow {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;
    private String bizNo;
    private String bizType;
    private Long bizId;
    private Integer direction;
    private BigDecimal amount;
    private BigDecimal balanceAfter;
    private String remark;
    private LocalDateTime createdAt;
}
