<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ include file="00-header.jsp" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<script type="text/javascript">
    $(document).ready(function() {
        $("#passwordForm").on("submit", function(event) {
            var password = $("#filePassword").val();
            if (!password || password.trim() === "") {
                $("#errorMessage").text("请输入密码");
                event.preventDefault();
            }
        });
    });
</script>

<div class="content">
    <div>
        <section><span>文件管理密码验证</span></section>
        <div class="info">
            <p>访问文件管理页面需要输入独立密码。请输入配置的文件访问密码。</p>
        </div>
        
        <c:if test="${not empty errorMessage}">
            <div class="error">
                ${errorMessage}
            </div>
        </c:if>
        
        <div id="errorMessage" class="error" style="display: none;"></div>
        
        <form id="passwordForm" action="${ctxPath}/manager/files" method="GET">
            <table class="userInput">
                <tr>
                    <td>密码:</td>
                    <td>
                        <input type="password" name="filePassword" id="filePassword" required>
                    </td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                        <input type="submit" value="验证">
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>

<%@ include file="00-footer.jsp" %>
