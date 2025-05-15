<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ include file="00-header.jsp" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<script type="text/javascript">
    $(document).ready(function() {
        // Initialize DataTable but disable pagination as we use server-side pagination
        $("#fileTable").dataTable({
            "language": {
                "url": "${ctxPath}/static/js/datatables-i18n.json"
            },
            "order": [[5, "desc"]],
            "columnDefs": [
                { "orderable": false, "targets": [11] }
            ],
            "paging": false,
            "info": false
        });
        
        // Handle file disable/enable toggle
        $(".toggle-disabled").on("click", function(e) {
            e.preventDefault();
            var fileId = $(this).data("id");
            var disabled = $(this).data("disabled") === "true";
            var newDisabled = !disabled;
            var button = $(this);
            
            $.ajax({
                url: "${ctxPath}/manager/files/disable/" + fileId,
                type: "POST",
                data: { disabled: newDisabled },
                success: function(response) {
                    if (response === "success") {
                        button.data("disabled", newDisabled.toString());
                        if (newDisabled) {
                            button.text("启用");
                            button.removeClass("redSubmit").addClass("blueSubmit");
                        } else {
                            button.text("禁用");
                            button.removeClass("blueSubmit").addClass("redSubmit");
                        }
                    } else {
                        alert("操作失败");
                    }
                },
                error: function() {
                    alert("操作失败");
                }
            });
        });
        
        // Handle max downloads update
        $(".update-max-downloads").on("click", function(e) {
            e.preventDefault();
            var fileId = $(this).data("id");
            var currentMax = $(this).data("max");
            var newMax = prompt("请输入最大下载次数 (0表示无限制):", currentMax);
            
            if (newMax !== null && !isNaN(newMax)) {
                $.ajax({
                    url: "${ctxPath}/manager/files/max-downloads/" + fileId,
                    type: "POST",
                    data: { maxDownloads: newMax },
                    success: function(response) {
                        if (response === "success") {
                            location.reload();
                        } else {
                            alert("更新失败: " + response);
                        }
                    },
                    error: function() {
                        alert("更新失败");
                    }
                });
            }
        });
        
        // Handle file deletion
        $(".delete-file").on("click", function(e) {
            e.preventDefault();
            if (confirm("确定要删除此文件吗?")) {
                var fileId = $(this).data("id");
                $.ajax({
                    url: "${ctxPath}/manager/files/" + fileId,
                    type: "DELETE",
                    success: function(response) {
                        if (response === "success") {
                            location.reload();
                        } else {
                            alert("删除失败");
                        }
                    },
                    error: function() {
                        alert("删除失败");
                    }
                });
            }
        });
        
        // Handle URL copying
        $(".copy-url").on("click", function(e) {
            e.preventDefault();
            var url = $(this).data("url");
            var tempInput = document.createElement("input");
            document.body.appendChild(tempInput);
            tempInput.value = url;
            tempInput.select();
            document.execCommand("copy");
            document.body.removeChild(tempInput);
            alert("URL已复制到剪贴板: " + url);
        });
        
        // Handle version update
        $(".update-version").on("click", function(e) {
            e.preventDefault();
            var fileId = $(this).data("id");
            $("#updateFileModal").data("id", fileId).show();
        });
        
        // Close modal when clicking the close button
        $(".close-modal").on("click", function() {
            $("#updateFileModal").hide();
        });
    });
</script>
<style>
    .pagination {
        margin: 20px 0;
        text-align: center;
    }
    .pagination a, .pagination span {
        display: inline-block;
        padding: 5px 10px;
        margin: 0 2px;
        border: 1px solid #ddd;
        border-radius: 3px;
    }
    .pagination .current {
        background-color: #4CAF50;
        color: white;
        border: 1px solid #4CAF50;
    }
    .file-actions {
        white-space: nowrap;
    }
    .file-actions button {
        margin: 2px;
    }
    .file-disabled {
        color: #999;
        text-decoration: line-through;
    }
    .download-info {
        font-size: 0.9em;
        color: #666;
    }
</style>
<div class="content">
    <div>
        <section><span>文件管理</span></section>
        
        <c:if test="${not empty error}">
            <div class="error">
                ${error}
            </div>
        </c:if>
        <c:if test="${not empty success}">
            <div class="success">
                ${success}
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
                            <div><small>允许的文件类型: ${allowedFileTypes}</small></div>
                        </td>
                    </tr>
                    <tr>
                        <td>描述:</td>
                        <td>
                            <form:textarea path="description" rows="3" cols="50" />
                        </td>
                    </tr>
                    <tr>
                        <td>版本:</td>
                        <td>
                            <form:input path="version" />
                        </td>
                    </tr>
                    <tr>
                        <td>最大下载次数:</td>
                        <td>
                            <form:input path="maxDownloads" type="number" min="0" value="0" />
                            <div><small>0 表示无限制</small></div>
                        </td>
                    </tr>
                    <tr>
                        <td>更新说明:</td>
                        <td>
                            <form:textarea path="updateContent" rows="3" cols="50" />
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
                    <th>版本</th>
                    <th>描述</th>
                    <th>大小</th>
                    <th>上传时间</th>
                    <th>最后更新</th>
                    <th>下载次数</th>
                    <th>上传者</th>
                    <th>更新说明</th>
                    <th>状态</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach items="${files}" var="file">
                    <tr>
                        <td>${file.id}</td>
                        <td>${file.originalName}</td>
                        <td>${file.version}</td>
                        <td>${file.description}</td>
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
                        <td><fmt:formatDate value="${file.uploadTime.toDate()}" pattern="yyyy-MM-dd HH:mm" /></td>
                        <td><fmt:formatDate value="${file.lastUpdated.toDate()}" pattern="yyyy-MM-dd HH:mm" /></td>
                        <td>
                            <span class="download-info">
                                ${file.downloadCount}
                                <c:if test="${file.maxDownloads > 0}">
                                    / ${file.maxDownloads}
                                </c:if>
                            </span>
                        </td>
                        <td>${file.uploadBy}</td>
                        <td>${file.updateNotes}</td>
                        <td>
                            <c:choose>
                                <c:when test="${file.disabled}">
                                    <span style="color: red;">已禁用</span>
                                </c:when>
                                <c:otherwise>
                                    <span style="color: green;">可用</span>
                                </c:otherwise>
                            </c:choose>
                        </td>
                        <td class="file-actions">
                            <a href="${ctxPath}/manager/files/download/${file.id}" class="blueSubmit" style="text-decoration: none;">下载</a>
                            <button class="toggle-disabled" data-id="${file.id}" data-disabled="${file.disabled}">
                                <c:choose>
                                    <c:when test="${file.disabled}">
                                        <span class="blueSubmit">启用</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span class="redSubmit">禁用</span>
                                    </c:otherwise>
                                </c:choose>
                            </button>
                            <button class="copy-url" data-id="${file.id}" data-url="${ctxPath}/manager/files/download/${file.id}">
                                <span class="blueSubmit">复制URL</span>
                            </button>
                            <button class="delete-file redSubmit" data-id="${file.id}">删除</button>
                            <button class="update-version" data-id="${file.id}">
                                <span class="blueSubmit">更新</span>
                            </button>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
        
        <!-- Pagination -->
        <div class="pagination">
            <c:if test="${totalPages > 1}">
                <c:if test="${currentPage > 1}">
                    <a href="${ctxPath}/manager/files?page=1&size=${pageSize}">&laquo; 首页</a>
                    <a href="${ctxPath}/manager/files?page=${currentPage - 1}&size=${pageSize}">&lsaquo; 上一页</a>
                </c:if>
                
                <c:forEach begin="${Math.max(1, currentPage - 2)}" end="${Math.min(totalPages, currentPage + 2)}" var="i">
                    <c:choose>
                        <c:when test="${i == currentPage}">
                            <span class="current">${i}</span>
                        </c:when>
                        <c:otherwise>
                            <a href="${ctxPath}/manager/files?page=${i}&size=${pageSize}">${i}</a>
                        </c:otherwise>
                    </c:choose>
                </c:forEach>
                
                <c:if test="${currentPage < totalPages}">
                    <a href="${ctxPath}/manager/files?page=${currentPage + 1}&size=${pageSize}">下一页 &rsaquo;</a>
                    <a href="${ctxPath}/manager/files?page=${totalPages}&size=${pageSize}">末页 &raquo;</a>
                </c:if>
            </c:if>
        </div>
    </div>
</div>

<!-- 文件版本更新模态对话框 -->
<div id="updateFileModal" style="display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.4);">
    <div style="background-color: #fefefe; margin: 15% auto; padding: 20px; border: 1px solid #888; width: 50%;">
        <span class="close-modal" style="color: #aaa; float: right; font-size: 28px; font-weight: bold; cursor: pointer;">&times;</span>
        <h2>更新文件版本</h2>
        <form id="updateFileForm" action="${ctxPath}/manager/files/update" method="POST" enctype="multipart/form-data">
            <input type="hidden" id="updateFileId" name="id" value="">
            <table class="userInput">
                <tr>
                    <td>选择文件:</td>
                    <td>
                        <input type="file" name="file" required />
                    </td>
                </tr>
                <tr>
                    <td>版本号:</td>
                    <td>
                        <input type="text" name="version" required />
                    </td>
                </tr>
                <tr>
                    <td>更新说明:</td>
                    <td>
                        <textarea name="updateNotes" rows="3" cols="50" required></textarea>
                    </td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                        <input type="submit" value="更新文件" />
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>

<script>
    // 设置模态框中的文件ID
    $(".update-version").on("click", function() {
        var fileId = $(this).data("id");
        $("#updateFileId").val(fileId);
    });
    
    // 表单提交处理
    $("#updateFileForm").on("submit", function(e) {
        e.preventDefault();
        var formData = new FormData(this);
        
        $.ajax({
            url: $(this).attr("action"),
            type: "POST",
            data: formData,
            processData: false,
            contentType: false,
            success: function(response) {
                alert("文件版本更新成功");
                $("#updateFileModal").hide();
                location.reload();
            },
            error: function() {
                alert("更新失败，请重试");
            }
        });
    });
</script>

<%@ include file="00-footer.jsp" %>
