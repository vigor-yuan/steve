<%@ include file="00-header.jsp" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<script type="text/javascript">
    $(document).ready(function() {
        $("#fileTable").dataTable({
            "language": {
                "url": "${ctxPath}/static/js/datatables-i18n.json"
            },
            "order": [[3, "desc"]],
            "columnDefs": [
                { "orderable": false, "targets": [5] }
            ]
        });
    });
</script>
<div class="content">
    <div>
        <section><span>文件管理</span></section>
        
        <c:if test="${not empty errorMessage}">
            <div class="error">
                ${errorMessage}
            </div>
        </c:if>
        <c:if test="${not empty successMessage}">
            <div class="success">
                ${successMessage}
            </div>
        </c:if>
        
        <div class="fileUploadContainer">
            <form:form action="${ctxPath}/manager/files/upload" method="POST" 
                      enctype="multipart/form-data" modelAttribute="fileForm">
                <table class="userInput">
                    <tr>
                        <td>选择文件:</td>
                        <td>
                            <input type="file" name="file" required />
                        </td>
                    </tr>
                    <tr>
                        <td>描述:</td>
                        <td>
                            <form:input path="description" />
                        </td>
                    </tr>
                    <tr>
                        <td></td>
                        <td>
                            <input type="submit" value="上传文件" />
                        </td>
                    </tr>
                </table>
            </form:form>
        </div>
        
        <br>
        
        <table class="res" id="fileTable">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>文件名</th>
                    <th>大小</th>
                    <th>上传时间</th>
                    <th>上传者</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach items="${fileList}" var="file">
                    <tr>
                        <td>${file.id}</td>
                        <td>
                            <a href="${ctxPath}/manager/files/download/${file.id}" title="${file.description}">
                                ${file.originalName}
                            </a>
                        </td>
                        <td>
                            <c:choose>
                                <c:when test="${file.fileSize < 1024}">
                                    ${file.fileSize} B
                                </c:when>
                                <c:when test="${file.fileSize < 1048576}">
                                    <fmt:formatNumber value="${file.fileSize / 1024}" maxFractionDigits="2" /> KB
                                </c:when>
                                <c:otherwise>
                                    <fmt:formatNumber value="${file.fileSize / 1048576}" maxFractionDigits="2" /> MB
                                </c:otherwise>
                            </c:choose>
                        </td>
                        <td data-sort-value="${file.uploadTime.millis}">
                            <fmt:formatDate value="${file.uploadTime.toDate()}" pattern="yyyy-MM-dd HH:mm:ss" />
                        </td>
                        <td>${file.uploadBy}</td>
                        <td>
                            <form action="${ctxPath}/manager/files/delete/${file.id}" method="POST" style="display:inline;">
                                <input type="submit" value="删除" class="redSubmit">
                            </form>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</div>
<%@ include file="00-footer.jsp" %>
