package com.bounty.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.bounty.dao.entity.TaskOrder;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;

@Mapper
public interface TaskOrderMapper extends BaseMapper<TaskOrder> {

    @Update("UPDATE t_task_order SET status = 5, updated_at = NOW() " +
            "WHERE status = 1 AND deadline_at < #{now}")
    int markTimeout(@Param("now") LocalDateTime now);

    @Update("UPDATE t_task_order SET status = #{to}, review_at = NOW(), review_remark = #{remark}, updated_at = NOW() " +
            "WHERE id = #{id} AND status = #{from}")
    int transit(@Param("id") Long id,
                @Param("from") int from,
                @Param("to") int to,
                @Param("remark") String remark);
}
