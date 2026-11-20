package com.bounty.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.bounty.dao.entity.Task;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

@Mapper
public interface TaskMapper extends BaseMapper<Task> {

    /**
     * 原子扣减名额：remain_quota 足够才扣，返回受影响行数。
     */
    @Update("UPDATE t_task SET taken_quota = taken_quota + 1, remain_quota = remain_quota - 1 " +
            "WHERE id = #{taskId} AND deleted = 0 AND remain_quota > 0")
    int takeQuota(@Param("taskId") Long taskId);

    @Update("UPDATE t_task SET finished_quota = finished_quota + 1 WHERE id = #{taskId} AND deleted = 0")
    int finishQuota(@Param("taskId") Long taskId);

    @Update("UPDATE t_task SET remain_quota = remain_quota + 1, taken_quota = taken_quota - 1 " +
            "WHERE id = #{taskId} AND deleted = 0 AND taken_quota > 0")
    int releaseQuota(@Param("taskId") Long taskId);
}
