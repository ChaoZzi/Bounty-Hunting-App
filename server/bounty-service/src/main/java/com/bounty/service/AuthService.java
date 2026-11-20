package com.bounty.service;

import com.bounty.common.api.ResultCode;
import com.bounty.common.exception.BizException;
import com.bounty.dao.entity.User;
import com.bounty.dao.entity.Wallet;
import com.bounty.dao.mapper.UserMapper;
import com.bounty.dao.mapper.WalletMapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private static final String CODE_KEY = "sms:code:%s:%s";
    private static final String TOKEN_KEY = "token:%s";
    private static final Duration CODE_TTL = Duration.ofMinutes(5);
    private static final Duration TOKEN_TTL = Duration.ofDays(7);

    private final StringRedisTemplate redis;
    private final UserMapper userMapper;
    private final WalletMapper walletMapper;

    /** 本地模式：固定验证码，控制台打印；接真实短信后改为随机 6 位 */
    @Value("${app.mock.sms-code:}")
    private String mockSmsCode;

    public void sendCode(String phone, String scene) {
        String code = (mockSmsCode == null || mockSmsCode.isBlank())
                ? String.format("%06d", (int) (Math.random() * 1_000_000))
                : mockSmsCode;
        redis.opsForValue().set(String.format(CODE_KEY, scene, phone), code, CODE_TTL);
        log.info("[MOCK-SMS] phone={} scene={} code={}", phone, scene, code);
    }

    public String verifyCode(String phone, String scene, String code) {
        // 本地模式：配置了固定验证码时直接放行，且不消费，方便反复调试
        if (mockSmsCode != null && !mockSmsCode.isBlank() && mockSmsCode.equals(code)) {
            return phone;
        }
        String key = String.format(CODE_KEY, scene, phone);
        String expect = redis.opsForValue().get(key);
        if (expect == null) {
            throw new BizException(ResultCode.BAD_REQUEST, "验证码已过期，请重新获取");
        }
        if (!expect.equals(code)) {
            throw new BizException(ResultCode.BAD_REQUEST, "验证码不正确");
        }
        redis.delete(key);
        return phone;
    }

    @Transactional(rollbackFor = Exception.class)
    public User loginOrRegister(String phone, String deviceId, String inviteCode, String ip) {
        User user = userMapper.selectOne(Wrappers.<User>lambdaQuery().eq(User::getPhone, phone));
        if (user == null) {
            user = new User();
            user.setPhone(phone);
            user.setNickname("用户" + phone.substring(Math.max(0, phone.length() - 4)));
            user.setAvatar("");
            user.setGender(0);
            user.setStatus(1);
            user.setCreditScore(1000);
            user.setRealnameStatus(0);
            user.setIsPublisher(0);
            user.setMemberLevel(0);
            user.setInviteCode(randomCode());
            user.setInviterId(0L);
            user.setDeviceId(deviceId == null ? "" : deviceId);
            user.setRegisterIp(ip == null ? "" : ip);
            user.setLastLoginAt(LocalDateTime.now());
            userMapper.insert(user);

            Wallet wallet = new Wallet();
            wallet.setUserId(user.getId());
            wallet.setAvailable(BigDecimal.ZERO);
            wallet.setFrozen(BigDecimal.ZERO);
            wallet.setPending(BigDecimal.ZERO);
            wallet.setTotalIncome(BigDecimal.ZERO);
            wallet.setTotalWithdraw(BigDecimal.ZERO);
            wallet.setVersion(0);
            walletMapper.insert(wallet);

            log.info("新用户注册 id={} phone={} inviteCode={}", user.getId(), phone, inviteCode);
        } else {
            if (user.getStatus() != null && user.getStatus() == 0) {
                throw new BizException(ResultCode.FORBIDDEN, "账号已被封禁");
            }
            user.setLastLoginAt(LocalDateTime.now());
            userMapper.updateById(user);
        }
        return user;
    }

    public String issueToken(Long userId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        redis.opsForValue().set(String.format(TOKEN_KEY, token), String.valueOf(userId), TOKEN_TTL);
        return token;
    }

    public Long resolveToken(String token) {
        String v = redis.opsForValue().get(String.format(TOKEN_KEY, token));
        return v == null ? null : Long.valueOf(v);
    }

    public void logout(String token) {
        if (token != null) {
            redis.delete(String.format(TOKEN_KEY, token));
        }
    }

    private String randomCode() {
        return UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
    }
}
