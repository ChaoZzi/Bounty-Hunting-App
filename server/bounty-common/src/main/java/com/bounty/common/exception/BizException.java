package com.bounty.common.exception;

import com.bounty.common.api.ResultCode;
import lombok.Getter;

@Getter
public class BizException extends RuntimeException {

    private final int code;

    public BizException(ResultCode resultCode) {
        super(resultCode.getMsg());
        this.code = resultCode.getCode();
    }

    public BizException(ResultCode resultCode, String msg) {
        super(msg);
        this.code = resultCode.getCode();
    }

    public BizException(int code, String msg) {
        super(msg);
        this.code = code;
    }
}
