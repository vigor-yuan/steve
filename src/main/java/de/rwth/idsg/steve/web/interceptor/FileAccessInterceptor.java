/*
 * SteVe - SteckdosenVerwaltung - https://github.com/RWTH-i5-IDSG/steve
 * Copyright (C) 2013-2022 RWTH Aachen University - Information Systems - Intelligent Distributed Systems Group (IDSG).
 * All Rights Reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
package de.rwth.idsg.steve.web.interceptor;

import de.rwth.idsg.steve.SteveConfiguration;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * 文件管理页面访问拦截器
 * 用于验证访问文件管理页面时的密码
 */
@Slf4j
@Component
public class FileAccessInterceptor implements HandlerInterceptor {

    private static final String FILE_ACCESS_PASSWORD_ATTR = "fileAccessPasswordVerified";
    private static final String FILE_PASSWORD_PARAM = "filePassword";
    
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // 获取配置的文件访问密码
        String configuredPassword = SteveConfiguration.CONFIG.getFileAccessPassword();
        
        // 如果未配置密码，则不进行拦截
        if (configuredPassword == null || configuredPassword.isEmpty()) {
            return true;
        }
        
        // 检查会话中是否已验证过密码
        HttpSession session = request.getSession();
        Boolean passwordVerified = (Boolean) session.getAttribute(FILE_ACCESS_PASSWORD_ATTR);
        
        // 如果已验证过密码，则允许访问
        if (passwordVerified != null && passwordVerified) {
            return true;
        }
        
        // 检查请求中是否包含密码参数
        String providedPassword = request.getParameter(FILE_PASSWORD_PARAM);
        if (providedPassword != null && providedPassword.equals(configuredPassword)) {
            // 密码正确，在会话中标记为已验证
            session.setAttribute(FILE_ACCESS_PASSWORD_ATTR, true);
            return true;
        }
        
        // 密码未验证，重定向到密码输入页面
        response.sendRedirect(request.getContextPath() + "/manager/file-password");
        return false;
    }
}
