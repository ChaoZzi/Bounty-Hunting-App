package com.bounty.api.controller;

import com.bounty.common.api.Result;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
public class HealthController {

    private final JdbcTemplate jdbcTemplate;

    @Value("${spring.application.name:bounty}")
    private String appName;

    public HealthController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/health")
    public Result<Map<String, Object>> health() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("app", appName);
        m.put("time", LocalDateTime.now().toString());
        try {
            Integer one = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            m.put("db", one != null && one == 1 ? "up" : "down");
        } catch (Exception e) {
            m.put("db", "down");
            m.put("dbError", e.getMessage());
        }
        return Result.ok(m);
    }
}
