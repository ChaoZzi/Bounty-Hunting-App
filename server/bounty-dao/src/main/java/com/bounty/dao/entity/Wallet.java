package com.bounty.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("t_wallet")
public class Wallet {

    @TableId(type = IdType.INPUT)
    private Long userId;

    private BigDecimal available;
    private BigDecimal frozen;
    private BigDecimal pending;
    private BigDecimal totalIncome;
    private BigDecimal totalWithdraw;
    private Integer version;
    private LocalDateTime updatedAt;
}
