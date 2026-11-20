package com.bounty.api.controller;

import com.bounty.common.api.PageResult;
import com.bounty.common.api.Result;
import com.bounty.common.context.UserContext;
import com.bounty.service.TaskService;
import com.bounty.service.vo.OrderVO;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/order")
@RequiredArgsConstructor
public class OrderController {

    private final TaskService taskService;

    /**
     * group: doing / pending / approved / rejected，不传则全部
     */
    @GetMapping("/my")
    public Result<PageResult<OrderVO>> my(
            @RequestParam(required = false) String group,
            @RequestParam(defaultValue = "1") long pageNum,
            @RequestParam(defaultValue = "10") long pageSize) {
        return Result.ok(taskService.myOrders(UserContext.require(), group,
                Math.max(1, pageNum), Math.min(50, Math.max(1, pageSize))));
    }
}
