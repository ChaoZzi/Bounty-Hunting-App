package com.bounty.api.controller;

import com.bounty.common.api.Result;
import com.bounty.common.api.ResultCode;
import com.bounty.common.exception.BizException;
import com.bounty.dao.entity.User;
import com.bounty.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/sms/send")
    public Result<Void> sendSms(@Valid @RequestBody SmsSendReq req) {
        authService.sendCode(req.getPhone(), req.getScene() == null ? "LOGIN" : req.getScene());
        return Result.ok();
    }

    @PostMapping("/login")
    public Result<Map<String, Object>> login(@Valid @RequestBody LoginReq req, HttpServletRequest request) {
        authService.verifyCode(req.getPhone(), "LOGIN", req.getCode());
        User user = authService.loginOrRegister(req.getPhone(), req.getDeviceId(), req.getInviteCode(),
                clientIp(request));
        String token = authService.issueToken(user.getId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("token", token);
        data.put("userId", user.getId());
        data.put("nickname", user.getNickname());
        data.put("avatar", user.getAvatar());
        data.put("realnameStatus", user.getRealnameStatus());
        return Result.ok(data);
    }

    @PostMapping("/logout")
    public Result<Void> logout(HttpServletRequest request) {
        String auth = request.getHeader("Authorization");
        if (auth != null && auth.startsWith("Bearer ")) {
            authService.logout(auth.substring(7).trim());
        }
        return Result.ok();
    }

    private String clientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isBlank()) {
            ip = request.getRemoteAddr();
        }
        return ip == null ? "" : ip.split(",")[0].trim();
    }

    @Data
    public static class SmsSendReq {
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        private String phone;
        private String scene;
    }

    @Data
    public static class LoginReq {
        @NotBlank(message = "手机号不能为空")
        @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
        private String phone;

        @NotBlank(message = "验证码不能为空")
        private String code;

        private String deviceId;
        private String inviteCode;
    }
}
