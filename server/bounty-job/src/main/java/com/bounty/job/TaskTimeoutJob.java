package com.bounty.job;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.bounty.dao.entity.TaskOrder;
import com.bounty.dao.mapper.TaskMapper;
import com.bounty.dao.mapper.TaskOrderMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 超时关单。
 * 关键点：除定时扫描外，启动时也全量补扫一次 ——
 * 本地开发时电脑关机期间不会跑定时任务，开机后必须把漏掉的全部处理掉。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TaskTimeoutJob {

    private static final int BATCH = 500;

    private final TaskOrderMapper orderMapper;
    private final TaskMapper taskMapper;

    @Scheduled(cron = "0 * * * * ?")
    public void schedule() {
        runOnce("定时");
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        runOnce("启动补偿");
    }

    public int runOnce(String reason) {
        LocalDateTime now = LocalDateTime.now();
        List<TaskOrder> list = orderMapper.selectList(Wrappers.<TaskOrder>lambdaQuery()
                .eq(TaskOrder::getStatus, TaskOrder.STATUS_DOING)
                .lt(TaskOrder::getDeadlineAt, now)
                .last("LIMIT " + BATCH));

        int count = 0;
        for (TaskOrder o : list) {
            int n = orderMapper.transit(o.getId(), TaskOrder.STATUS_DOING,
                    TaskOrder.STATUS_TIMEOUT, "任务超时");
            if (n > 0) {
                taskMapper.releaseQuota(o.getTaskId());
                count++;
            }
        }
        if (count > 0) {
            log.info("[{}] 超时关单 {} 条", reason, count);
        }
        return count;
    }
}
