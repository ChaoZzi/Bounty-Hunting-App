package com.bounty.api.config;

import com.bounty.api.interceptor.AuthInterceptor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

@Slf4j
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
        Path uiDir = resolveAdminUiDir();
        if (uiDir == null) {
            // 目录不存在时不注册映射，访问 /admin-ui/ 会得到 404 而不是 500 堆栈
            log.warn("管理后台目录不存在，/admin-ui 暂不可用。当前工作目录={}，配置 app.admin-ui-path={}",
                    Paths.get("").toAbsolutePath(), adminUiPath);
            return;
        }
        log.info("管理后台静态目录: {}", uiDir);
        String location = "file:" + uiDir + java.io.File.separator;
        registry.addResourceHandler("/admin-ui/**")
                .addResourceLocations(location);
    }

    /**
     * 定位管理后台打包产物目录。
     *
     * 【为什么要向上找】
     * 配置里写的是相对路径 ./admin/dist/，它相对于「进程工作目录」。
     * 用 start.bat 启动时工作目录是项目根，能找到；
     * 但在 IDEA 里点运行，工作目录是 server/ 或 server/bounty-boot/，
     * 相对路径就变成 server/admin/dist，找不到。
     * 这里从当前目录逐级向上试，最多 5 层，覆盖所有常见的启动位置。
     *
     * @return 存在的绝对路径；找不到返回 null
     */
    private Path resolveAdminUiDir() {
        Path configured = Paths.get(adminUiPath);
        if (configured.isAbsolute()) {
            return Files.isDirectory(configured) ? configured.normalize() : null;
        }

        Path cursor = Paths.get("").toAbsolutePath();
        for (int depth = 0; depth < 5 && cursor != null; depth++) {
            Path candidate = cursor.resolve(configured).normalize();
            if (Files.isDirectory(candidate)) {
                return candidate;
            }
            cursor = cursor.getParent();
        }
        return null;
    }
}
