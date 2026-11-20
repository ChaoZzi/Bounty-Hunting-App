package com.bounty.boot;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(scanBasePackages = "com.bounty")
@MapperScan("com.bounty.dao.mapper")
@EnableScheduling
public class BountyApplication {

    public static void main(String[] args) {
        SpringApplication.run(BountyApplication.class, args);
    }
}
