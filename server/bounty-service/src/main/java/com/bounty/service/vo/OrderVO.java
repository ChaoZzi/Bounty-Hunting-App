package com.bounty.service.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class OrderVO {
    private String orderNo;
    private Long taskId;
    private String taskTitle;
    private String taskCover;
    private BigDecimal amount;
    private Integer status;
    private String statusText;
    private LocalDateTime applyAt;
    private LocalDateTime deadlineAt;
    private String reviewRemark;

    public static String statusText(Integer status) {
        if (status == null) {
            return "";
        }
        return switch (status) {
            case 0 -> "待接单";
            case 1 -> "进行中";
            case 2 -> "待审核";
            case 3 -> "已通过";
            case 4 -> "未通过";
            case 5 -> "已超时";
            case 6 -> "已结算";
            case 7 -> "已取消";
            default -> "未知";
        };
    }
}
