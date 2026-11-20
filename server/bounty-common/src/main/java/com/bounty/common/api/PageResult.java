package com.bounty.common.api;

import lombok.Data;

import java.util.List;

@Data
public class PageResult<T> {

    private List<T> list;
    private long total;
    private long pageNum;
    private long pageSize;
    private boolean hasNext;

    public static <T> PageResult<T> of(List<T> list, long total, long pageNum, long pageSize) {
        PageResult<T> p = new PageResult<>();
        p.list = list;
        p.total = total;
        p.pageNum = pageNum;
        p.pageSize = pageSize;
        p.hasNext = pageNum * pageSize < total;
        return p;
    }

    public static <T> PageResult<T> empty(long pageNum, long pageSize) {
        return of(List.of(), 0, pageNum, pageSize);
    }
}
