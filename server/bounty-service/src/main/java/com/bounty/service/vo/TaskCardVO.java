package com.bounty.service.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class TaskCardVO {
    private Long id;
    private String title;
    private String cover;
    private String intro;
    private BigDecimal unitPrice;
    private Integer remainQuota;
    private Integer takenQuota;
    private Integer fastReview;
    private Boolean top;
    private Integer viewCount;
    private LocalDateTime createdAt;
}
