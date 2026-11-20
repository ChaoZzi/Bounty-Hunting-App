package com.bounty.api.config;

import com.bounty.api.interceptor.AuthInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final AuthInterceptor authInterceptor;

    /** 本地图片存储目录，可通过 app.storage.local-path 覆盖 */
    private final StorageProps storageProps;

    /**
     * 管理后台打包产物目录。执行过 npm run build 之后，
     * 直接用 http://<ip>:8080/admin-ui/ 访问，不需要再开 node。
     */
    @Value("${app.admin-ui-path:./admin/dist/}")
    private String adminUiPath;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(
                        "/api/v1/health",
                        "/api/v1/auth/**",
                        "/api/v1/common/**",
                        "/api/v1/task/hall",
                        "/api/v1/task/categories"
                );
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String dir = Paths.get(storageProps.getLocalPath()).toAbsolutePath().normalize().toString();
        registry.addResourceHandler("/files/**")
                .addResourceLocations("file:" + dir + "/");

        // 管理后台静态产物：http://<ip>:8080/admin-ui/
        String uiDir = Paths.get(adminUiPath).toAbsolutePath().normalize().toString();
        if (!uiDir.endsWith(java.io.File.separator)) {
            uiDir = uiDir + java.io.File.separator;
        }
        registry.addResourceHandler("/admin-ui/**")
                .addResourceLocations("file:" + uiDir);
    }
}
