package com.bounty.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableLogic;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("t_user")
public class User {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String phone;
    private String nickname;
    private String avatar;
    private Integer gender;
    private Integer status;
    private Integer creditScore;
    private Integer realnameStatus;
    private Integer isPublisher;
    private Integer memberLevel;
    private LocalDateTime memberExpireAt;
    private String inviteCode;
    private Long inviterId;
    private String registerIp;
    private String deviceId;
    private LocalDateTime lastLoginAt;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @TableLogic
    private Integer deleted;
}
