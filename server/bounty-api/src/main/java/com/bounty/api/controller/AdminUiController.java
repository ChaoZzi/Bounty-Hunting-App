package com.bounty.api.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/**
 * 管理后台入口转发。
 * 静态资源处理器只负责 /admin-ui/** 下的文件，访问目录根时不会自动找 index.html，
 * 所以这里显式转发一次。
 */
@Controller
public class AdminUiController {

    @GetMapping({"/admin-ui", "/admin-ui/"})
    public String index() {
        return "forward:/admin-ui/index.html";
    }
}
