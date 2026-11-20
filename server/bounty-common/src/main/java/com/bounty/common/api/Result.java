package com.bounty.common.api;

import lombok.Data;

/**
 * 统一响应体。
 * 约定：code=0 表示成功，其余见 {@link ResultCode}。
 */
@Data
public class Result<T> {

    private int code;
    private String msg;
    private T data;
    private String traceId;

    public static <T> Result<T> ok(T data) {
        Result<T> r = new Result<>();
        r.code = 0;
        r.msg = "ok";
        r.data = data;
        return r;
    }

    public static <T> Result<T> ok() {
        return ok(null);
    }

    public static <T> Result<T> fail(ResultCode code) {
        return fail(code.getCode(), code.getMsg());
    }

    public static <T> Result<T> fail(int code, String msg) {
        Result<T> r = new Result<>();
        r.code = code;
        r.msg = msg;
        return r;
    }
}
