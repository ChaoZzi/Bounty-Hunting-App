package com.bounty.api.controller;

import com.bounty.common.api.PageResult;
import com.bounty.common.api.Result;
import com.bounty.common.context.UserContext;
import com.bounty.dao.entity.Task;
import com.bounty.service.TaskService;
import com.bounty.service.vo.TaskCardVO;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/task")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @GetMapping("/hall")
    public Result<PageResult<TaskCardVO>> hall(
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false, defaultValue = "comprehensive") String sort,
            @RequestParam(defaultValue = "1") long pageNum,
            @RequestParam(defaultValue = "10") long pageSize) {
        return Result.ok(taskService.hall(categoryId, keyword, sort,
                Math.max(1, pageNum), Math.min(50, Math.max(1, pageSize))));
    }

    @GetMapping("/{id}")
    public Result<Task> detail(@PathVariable Long id) {
        return Result.ok(taskService.detail(id));
    }

    @PostMapping("/{id}/apply")
    public Result<Map<String, Object>> apply(@PathVariable Long id) {
        String orderNo = taskService.apply(id, UserContext.require());
        return Result.ok(Map.of("orderNo", orderNo));
    }
}
