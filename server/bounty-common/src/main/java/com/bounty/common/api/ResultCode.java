package com.bounty.common.api;

import lombok.Getter;

@Getter
public enum ResultCode {

    SUCCESS(0, "ok"),
    BAD_REQUEST(400, "参数错误"),
    UNAUTHORIZED(401, "未登录或登录已失效"),
    FORBIDDEN(403, "无权限"),
    NOT_FOUND(404, "资源不存在"),
    TOO_MANY_REQUESTS(429, "操作太频繁，请稍后再试"),

    BALANCE_NOT_ENOUGH(1001, "余额不足"),
    TASK_SOLD_OUT(1002, "名额已满"),
    TASK_OFFLINE(1003, "任务已下架"),
    TASK_DUPLICATED(1004, "你已报名过该任务"),

    REALNAME_REQUIRED(2001, "请先完成实名认证"),

    SYSTEM_ERROR(5000, "服务开小差了");

    private final int code;
    private final String msg;

    ResultCode(int code, String msg) {
        this.code = code;
        this.msg = msg;
    }
}
