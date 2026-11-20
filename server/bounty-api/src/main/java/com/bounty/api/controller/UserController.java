package com.bounty.api.controller;

import com.bounty.common.api.Result;
import com.bounty.common.context.UserContext;
import com.bounty.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/user/profile")
    public Result<Map<String, Object>> profile() {
        return Result.ok(userService.profile(UserContext.require()));
    }

    @GetMapping("/wallet/summary")
    public Result<Map<String, Object>> walletSummary() {
        return Result.ok(userService.walletSummary(UserContext.require()));
    }
}
