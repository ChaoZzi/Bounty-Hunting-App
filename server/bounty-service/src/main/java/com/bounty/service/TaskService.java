package com.bounty.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.bounty.common.api.PageResult;
import com.bounty.common.api.ResultCode;
import com.bounty.common.exception.BizException;
import com.bounty.common.util.BizNo;
import com.bounty.dao.entity.Task;
import com.bounty.dao.entity.TaskOrder;
import com.bounty.dao.mapper.TaskMapper;
import com.bounty.dao.mapper.TaskOrderMapper;
import com.bounty.service.vo.OrderVO;
import com.bounty.service.vo.TaskCardVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class TaskService {

    /** 任务状态：2 展示中 */
    private static final int TASK_ONLINE = 2;

    private final TaskMapper taskMapper;
    private final TaskOrderMapper orderMapper;

    public PageResult<TaskCardVO> hall(Integer categoryId, String keyword, String sort,
                                       long pageNum, long pageSize) {
        LambdaQueryWrapper<Task> qw = Wrappers.<Task>lambdaQuery()
                .eq(Task::getStatus, TASK_ONLINE)
                .eq(Task::getDeleted, 0);
        if (categoryId != null && categoryId > 0) {
            qw.eq(Task::getCategoryId, categoryId);
        }
        if (StringUtils.hasText(keyword)) {
            qw.like(Task::getTitle, keyword);
        }
        switch (sort == null ? "comprehensive" : sort) {
            case "latest" -> qw.orderByDesc(Task::getCreatedAt);
            case "price" -> qw.orderByDesc(Task::getUnitPrice);
            case "simple" -> qw.orderByAsc(Task::getUnitPrice);
            case "selected" -> qw.orderByDesc(Task::getFastReview).orderByDesc(Task::getWeight);
            default -> qw.orderByDesc(Task::getWeight).orderByDesc(Task::getCreatedAt);
        }

        IPage<Task> page = taskMapper.selectPage(new Page<>(pageNum, pageSize), qw);
        List<TaskCardVO> list = page.getRecords().stream().map(this::toCard).toList();
        return PageResult.of(list, page.getTotal(), pageNum, pageSize);
    }

    public Task detail(Long id) {
        Task task = taskMapper.selectById(id);
        if (task == null || task.getStatus() == null || task.getStatus() != TASK_ONLINE) {
            throw new BizException(ResultCode.TASK_OFFLINE);
        }
        return task;
    }

    /**
     * 报名：DB 原子扣减名额 + 唯一索引兜底。
     * 并发量上来后把这一步换成 Redis 预扣，接口签名不变。
     */
    @Transactional(rollbackFor = Exception.class)
    public String apply(Long taskId, Long userId) {
        Task task = taskMapper.selectById(taskId);
        if (task == null || task.getStatus() != TASK_ONLINE) {
            throw new BizException(ResultCode.TASK_OFFLINE);
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime deadline = now.plusMinutes(task.getDeadlineMinutes() == null ? 1440 : task.getDeadlineMinutes());

        TaskOrder exist = orderMapper.selectOne(Wrappers.<TaskOrder>lambdaQuery()
                .eq(TaskOrder::getTaskId, taskId)
                .eq(TaskOrder::getUserId, userId));

        if (exist != null && exist.getStatus() != null) {
            int st = exist.getStatus();
            if (st == TaskOrder.STATUS_DOING || st == TaskOrder.STATUS_REVIEWING
                    || st == TaskOrder.STATUS_APPROVED || st == TaskOrder.STATUS_SETTLED) {
                throw new BizException(ResultCode.TASK_DUPLICATED);
            }
            // 已驳回 / 已超时 → 重新报名，复用原单（唯一索引 task_id+user_id）
            if (taskMapper.takeQuota(taskId) == 0) {
                throw new BizException(ResultCode.TASK_SOLD_OUT);
            }
            exist.setStatus(TaskOrder.STATUS_DOING);
            exist.setApplyAt(now);
            exist.setDeadlineAt(deadline);
            exist.setSubmitAt(null);
            exist.setReviewAt(null);
            exist.setReviewRemark("");
            orderMapper.updateById(exist);
            log.info("重新报名 orderNo={} taskId={} userId={}", exist.getOrderNo(), taskId, userId);
            return exist.getOrderNo();
        }

        if (taskMapper.takeQuota(taskId) == 0) {
            throw new BizException(ResultCode.TASK_SOLD_OUT);
        }

        TaskOrder order = new TaskOrder();
        order.setOrderNo(BizNo.order());
        order.setTaskId(taskId);
        order.setUserId(userId);
        order.setPublisherId(task.getPublisherId());
        order.setAmount(task.getUnitPrice());
        order.setStatus(TaskOrder.STATUS_DOING);
        order.setApplyAt(now);
        order.setDeadlineAt(deadline);
        order.setCreatedAt(now);
        order.setUpdatedAt(now);
        orderMapper.insert(order);

        log.info("报名成功 orderNo={} taskId={} userId={}", order.getOrderNo(), taskId, userId);
        return order.getOrderNo();
    }

    public PageResult<OrderVO> myOrders(Long userId, String group, long pageNum, long pageSize) {
        LambdaQueryWrapper<TaskOrder> qw = Wrappers.<TaskOrder>lambdaQuery()
                .eq(TaskOrder::getUserId, userId)
                .orderByDesc(TaskOrder::getApplyAt);

        if (group != null) {
            switch (group) {
                case "doing" -> qw.eq(TaskOrder::getStatus, TaskOrder.STATUS_DOING);
                case "pending" -> qw.eq(TaskOrder::getStatus, TaskOrder.STATUS_REVIEWING);
                case "approved" -> qw.in(TaskOrder::getStatus, TaskOrder.STATUS_APPROVED, TaskOrder.STATUS_SETTLED);
                case "rejected" -> qw.in(TaskOrder::getStatus, TaskOrder.STATUS_REJECTED, TaskOrder.STATUS_TIMEOUT);
                default -> {
                }
            }
        }

        IPage<TaskOrder> page = orderMapper.selectPage(new Page<>(pageNum, pageSize), qw);
        List<OrderVO> list = page.getRecords().stream().map(this::toOrderVO).toList();
        return PageResult.of(list, page.getTotal(), pageNum, pageSize);
    }

    private TaskCardVO toCard(Task t) {
        TaskCardVO vo = new TaskCardVO();
        vo.setId(t.getId());
        vo.setTitle(t.getTitle());
        vo.setCover(t.getCover());
        vo.setIntro(t.getIntro());
        vo.setUnitPrice(t.getUnitPrice());
        vo.setRemainQuota(t.getRemainQuota());
        vo.setTakenQuota(t.getTakenQuota());
        vo.setFastReview(t.getFastReview());
        vo.setTop(t.getTopUntil() != null && t.getTopUntil().isAfter(LocalDateTime.now()));
        vo.setViewCount(t.getViewCount());
        vo.setCreatedAt(t.getCreatedAt());
        return vo;
    }

    private OrderVO toOrderVO(TaskOrder o) {
        OrderVO vo = new OrderVO();
        vo.setOrderNo(o.getOrderNo());
        vo.setTaskId(o.getTaskId());
        vo.setAmount(o.getAmount());
        vo.setStatus(o.getStatus());
        vo.setStatusText(OrderVO.statusText(o.getStatus()));
        vo.setApplyAt(o.getApplyAt());
        vo.setDeadlineAt(o.getDeadlineAt());
        vo.setReviewRemark(o.getReviewRemark());
        Task t = taskMapper.selectById(o.getTaskId());
        if (t != null) {
            vo.setTaskTitle(t.getTitle());
            vo.setTaskCover(t.getCover());
        }
        return vo;
    }
}
