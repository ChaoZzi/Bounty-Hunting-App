package com.bounty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.bounty.common.api.PageResult;
import com.bounty.common.exception.BizException;
import com.bounty.dao.entity.Task;
import com.bounty.dao.entity.TaskOrder;
import com.bounty.dao.entity.Withdraw;
import com.bounty.dao.mapper.TaskMapper;
import com.bounty.dao.mapper.TaskOrderMapper;
import com.bounty.dao.mapper.UserMapper;
import com.bounty.dao.mapper.WithdrawMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminService {

    private static final String ADMIN_TOKEN_KEY = "admin:token:%s";

    /** 本地演示用固定账号，接真实后台前替换为 t_admin_user 校验 */
    private static final String DEMO_USER = "admin";
    private static final String DEMO_PASS = "admin123";

    private final StringRedisTemplate redis;
    private final TaskMapper taskMapper;
    private final TaskOrderMapper orderMapper;
    private final UserMapper userMapper;
    private final WithdrawMapper withdrawMapper;

    public Map<String, Object> login(String username, String password) {
        if (!DEMO_USER.equals(username) || !DEMO_PASS.equals(password)) {
            throw new BizException(400, "账号或密码错误");
        }
        String token = UUID.randomUUID().toString().replace("-", "");
        redis.opsForValue().set(String.format(ADMIN_TOKEN_KEY, token), username, Duration.ofHours(24));

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("token", token);
        m.put("realName", "超级管理员");
        return m;
    }

    public void require(String token) {
        if (token == null || !Boolean.TRUE.equals(redis.hasKey(String.format(ADMIN_TOKEN_KEY, token)))) {
            throw new BizException(401, "登录已失效");
        }
    }

    public Map<String, Object> dashboard() {
        long userCount = userMapper.selectCount(null);
        long taskCount = taskMapper.selectCount(null);
        long orderCount = orderMapper.selectCount(null);
        long pendingWithdraw = withdrawMapper.selectCount(
                Wrappers.<Withdraw>lambdaQuery().eq(Withdraw::getStatus, 0));

        List<Task> recent = taskMapper.selectList(Wrappers.<Task>lambdaQuery()
                .orderByDesc(Task::getId).last("LIMIT 10"));

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("userCount", userCount);
        stats.put("taskCount", taskCount);
        stats.put("orderCount", orderCount);
        stats.put("pendingWithdraw", pendingWithdraw);

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("stats", stats);
        m.put("recentTasks", recent);
        return m;
    }

    public PageResult<Task> tasks(Integer auditStatus, long pageNum, long pageSize) {
        LambdaQueryWrapper<Task> qw = Wrappers.<Task>lambdaQuery().orderByDesc(Task::getId);
        if (auditStatus != null) {
            qw.eq(Task::getAuditStatus, auditStatus);
        }
        IPage<Task> page = taskMapper.selectPage(new Page<>(pageNum, pageSize), qw);
        return PageResult.of(page.getRecords(), page.getTotal(), pageNum, pageSize);
    }

    @Transactional(rollbackFor = Exception.class)
    public void auditTask(Long id, boolean pass, String remark) {
        Task task = taskMapper.selectById(id);
        if (task == null) {
            throw new BizException(404, "任务不存在");
        }
        taskMapper.update(null, Wrappers.<Task>lambdaUpdate()
                .eq(Task::getId, id)
                .set(Task::getAuditStatus, pass ? 1 : 2)
                .set(Task::getStatus, pass ? 2 : 5)
                .set(Task::getAuditRemark, remark == null ? "" : remark));
        log.info("任务审核 id={} pass={} remark={}", id, pass, remark);
    }

    public PageResult<Withdraw> withdraws(long pageNum, long pageSize) {
        IPage<Withdraw> page = withdrawMapper.selectPage(new Page<>(pageNum, pageSize),
                Wrappers.<Withdraw>lambdaQuery().orderByDesc(Withdraw::getId));
        return PageResult.of(page.getRecords(), page.getTotal(), pageNum, pageSize);
    }

    @Transactional(rollbackFor = Exception.class)
    public void auditWithdraw(String withdrawNo, boolean pass, String remark) {
        Withdraw w = withdrawMapper.selectOne(
                Wrappers.<Withdraw>lambdaQuery().eq(Withdraw::getWithdrawNo, withdrawNo));
        if (w == null) {
            throw new BizException(404, "提现单不存在");
        }
        if (w.getStatus() != 0) {
            throw new BizException(400, "该提现单已处理");
        }
        Withdraw update = new Withdraw();
        update.setId(w.getId());
        update.setStatus(pass ? 3 : 5);
        update.setAuditAt(LocalDateTime.now());
        update.setPaidAt(pass ? LocalDateTime.now() : null);
        update.setFailReason(pass ? "" : (remark == null ? "审核驳回" : remark));
        update.setThirdNo(pass ? "MOCK-" + System.currentTimeMillis() : "");
        withdrawMapper.updateById(update);
        log.info("提现审核 no={} pass={} （本地模拟打款，未真实转账）", withdrawNo, pass);
    }

    /** 供任务模块复用：订单数按状态统计 */
    public long countOrderByStatus(int status) {
        return orderMapper.selectCount(Wrappers.<TaskOrder>lambdaQuery().eq(TaskOrder::getStatus, status));
    }
}
