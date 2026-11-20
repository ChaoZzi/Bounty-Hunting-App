package com.bounty.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.bounty.dao.entity.Wallet;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

import java.math.BigDecimal;

@Mapper
public interface WalletMapper extends BaseMapper<Wallet> {

    @Update("UPDATE t_wallet SET available = available + #{amount}, " +
            "total_income = total_income + #{amount}, version = version + 1 " +
            "WHERE user_id = #{userId}")
    int addAvailable(@Param("userId") Long userId, @Param("amount") BigDecimal amount);
}
