package com.bounty.api.interceptor;

import com.bounty.common.api.ResultCode;
import com.bounty.common.context.UserContext;
import com.bounty.common.exception.BizException;
import com.bounty.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final AuthService authService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        String token = resolveToken(request);
        if (!StringUtils.hasText(token)) {
            throw new BizException(ResultCode.UNAUTHORIZED);
        }
        Long userId = authService.resolveToken(token);
        if (userId == null) {
            throw new BizException(ResultCode.UNAUTHORIZED);
        }
        UserContext.set(userId);
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        UserContext.clear();
    }

    private String resolveToken(HttpServletRequest request) {
        String auth = request.getHeader("Authorization");
        if (StringUtils.hasText(auth) && auth.startsWith("Bearer ")) {
            return auth.substring(7).trim();
        }
        return request.getHeader("X-Token");
    }
}
