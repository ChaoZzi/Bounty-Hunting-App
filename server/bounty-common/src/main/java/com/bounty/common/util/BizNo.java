package com.bounty.common.util;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 业务单号生成：前缀 + yyyyMMddHHmmss + 4 位随机。
 * 单机场景足够；上多机后换成雪花算法或号段。
 */
public final class BizNo {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private BizNo() {
    }

    public static String gen(String prefix) {
        return prefix + LocalDateTime.now().format(FMT)
                + String.format("%04d", ThreadLocalRandom.current().nextInt(10000));
    }

    public static String order() {
        return gen("TO");
    }

    public static String withdraw() {
        return gen("WD");
    }

    public static String pay() {
        return gen("PY");
    }
}
