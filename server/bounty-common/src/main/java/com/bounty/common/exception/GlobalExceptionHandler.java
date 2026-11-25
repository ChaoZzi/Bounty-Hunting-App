package com.bounty.common.exception;

import com.bounty.common.api.Result;
import com.bounty.common.api.ResultCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BizException.class)
    public Result<Void> handleBiz(BizException e) {
        log.warn("业务异常: code={}, msg={}", e.getCode(), e.getMessage());
        return Result.fail(e.getCode(), e.getMessage());
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public Result<Void> handleValid(BindException e) {
        FieldError fe = e.getBindingResult().getFieldError();
        String msg = fe == null ? "参数错误" : fe.getDefaultMessage();
        return Result.fail(ResultCode.BAD_REQUEST.getCode(), msg);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public Result<Void> handleUnreadable(HttpMessageNotReadableException e) {
        return Result.fail(ResultCode.BAD_REQUEST.getCode(), "请求体格式错误");
    }

    @ExceptionHandler(NoHandlerFoundException.class)
    public Result<Void> handleNotFound(NoHandlerFoundException e) {
        return Result.fail(ResultCode.NOT_FOUND);
    }

    /**
     * 静态资源找不到（Spring 6.1 起不再走 NoHandlerFoundException）。
     *
     * 【为什么要单独处理】
     * 它本质上是一个 404，不是系统故障。
     * 如果落到下面的 Exception 兜底里，会把一次「访问了不存在的图片/页面」
     * 记成 ERROR + 完整堆栈，日志会被噪音淹没，真正的问题反而看不见。
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public Result<Void> handleNoResource(NoResourceFoundException e) {
        log.debug("静态资源不存在: {}", e.getResourcePath());
        return Result.fail(ResultCode.NOT_FOUND);
    }

    @ExceptionHandler(Exception.class)
    public Result<Void> handleOther(Exception e) {
        log.error("系统异常", e);
        return Result.fail(ResultCode.SYSTEM_ERROR);
    }
}
