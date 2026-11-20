package com.bounty.api.controller;

import com.bounty.common.api.PageResult;
import com.bounty.common.api.Result;
import com.bounty.common.exception.BizException;
import com.bounty.dao.entity.Task;
import com.bounty.dao.entity.Withdraw;
import com.bounty.service.AdminService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/admin/v1")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @PostMapping("/auth/login")
    public Result<Map<String, Object>> login(@RequestBody LoginReq req) {
        return Result.ok(adminService.login(req.getUsername(), req.getPassword()));
    }

    @GetMapping("/dashboard")
    public Result<Map<String, Object>> dashboard(HttpServletRequest request) {
        check(request);
        return Result.ok(adminService.dashboard());
    }

    @GetMapping("/tasks")
    public Result<PageResult<Task>> tasks(HttpServletRequest request,
                                          @RequestParam(required = false) Integer auditStatus,
                                          @RequestParam(defaultValue = "1") long pageNum,
                                          @RequestParam(defaultValue = "10") long pageSize) {
        check(request);
        return Result.ok(adminService.tasks(auditStatus, pageNum, pageSize));
    }

    @PostMapping("/tasks/{id}/audit")
    public Result<Void> auditTask(HttpServletRequest request,
                                  @PathVariable Long id,
                                  @RequestBody AuditReq req) {
        check(request);
        adminService.auditTask(id, Boolean.TRUE.equals(req.getPass()), req.getRemark());
        return Result.ok();
    }

    @GetMapping("/withdraws")
    public Result<PageResult<Withdraw>> withdraws(HttpServletRequest request,
                                                  @RequestParam(defaultValue = "1") long pageNum,
                                                  @RequestParam(defaultValue = "10") long pageSize) {
        check(request);
        return Result.ok(adminService.withdraws(pageNum, pageSize));
    }

    @PostMapping("/withdraws/{no}/audit")
    public Result<Void> auditWithdraw(HttpServletRequest request,
                                      @PathVariable String no,
                                      @RequestBody AuditReq req) {
        check(request);
        adminService.auditWithdraw(no, Boolean.TRUE.equals(req.getPass()), req.getRemark());
        return Result.ok();
    }

    private void check(HttpServletRequest request) {
        String auth = request.getHeader("Authorization");
        String token = null;
        if (StringUtils.hasText(auth) && auth.startsWith("Bearer ")) {
            token = auth.substring(7).trim();
        }
        if (token == null) {
            throw new BizException(401, "未登录");
        }
        adminService.require(token);
    }

    @Data
    public static class LoginReq {
        private String username;
        private String password;
    }

    @Data
    public static class AuditReq {
        private Boolean pass;
        private String remark;
    }
}
