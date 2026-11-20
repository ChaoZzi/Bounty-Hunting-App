package com.bounty.api.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "app.storage")
public class StorageProps {

    /** local | oss */
    private String type = "local";

    private String localPath = "./data/upload";

    /** 对外访问前缀，例如 http://192.168.1.23:8080/files/ */
    private String publicPrefix = "/files/";
}
