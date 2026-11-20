package com.bounty.service;

import com.bounty.common.api.ResultCode;
import com.bounty.common.exception.BizException;
import com.bounty.dao.entity.User;
import com.bounty.dao.entity.Wallet;
import com.bounty.dao.mapper.UserMapper;
import com.bounty.dao.mapper.WalletMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final WalletMapper walletMapper;

    public User require(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BizException(ResultCode.UNAUTHORIZED);
        }
        return user;
    }

    public Map<String, Object> profile(Long userId) {
        User u = require(userId);
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("phone", maskPhone(u.getPhone()));
        m.put("nickname", u.getNickname());
        m.put("avatar", u.getAvatar());
        m.put("creditScore", u.getCreditScore());
        m.put("creditMax", 10000);
        m.put("realnameStatus", u.getRealnameStatus());
        m.put("isPublisher", u.getIsPublisher());
        m.put("memberLevel", u.getMemberLevel());
        m.put("memberExpireAt", u.getMemberExpireAt());
        m.put("inviteCode", u.getInviteCode());
        return m;
    }

    public Map<String, Object> walletSummary(Long userId) {
        Wallet w = walletMapper.selectById(userId);
        if (w == null) {
            w = new Wallet();
            w.setUserId(userId);
            w.setAvailable(BigDecimal.ZERO);
            w.setFrozen(BigDecimal.ZERO);
            w.setPending(BigDecimal.ZERO);
            w.setTotalIncome(BigDecimal.ZERO);
            w.setTotalWithdraw(BigDecimal.ZERO);
            walletMapper.insert(w);
        }
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("available", w.getAvailable());
        m.put("frozen", w.getFrozen());
        m.put("pending", w.getPending());
        m.put("totalIncome", w.getTotalIncome());
        m.put("totalWithdraw", w.getTotalWithdraw());
        return m;
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone == null ? "" : phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }
}
