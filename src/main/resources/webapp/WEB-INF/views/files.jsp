<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" trimDirectiveWhitespaces="true" %>
<%@ include file="00-header.jsp" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<script type="text/javascript">
    $(document).ready(function() {
        // 设置CSRF令牌
        var csrfHeader = '${_csrf.headerName}';
        var csrfToken = '${_csrf.token}';
        
        // 文件大小验证 - 最大2MB (2097152 bytes)
        var maxFileSize = 2097152;
        
        // 为所有文件上传输入框添加文件大小验证
        $(document).on('change', 'input[type="file"]', function() {
            var fileInput = this;
            var form = $(this).closest('form');
            var submitButton = form.find('input[type="submit"], button[type="submit"]');
            var errorDiv = form.find('.file-size-error');
            
            // 如果没有错误提示div，创建一个
            if (errorDiv.length === 0) {
                errorDiv = $('<div class="file-size-error" style="color: red; display: none;">文件大小超过2MB，无法上传</div>');
                $(this).after(errorDiv);
            }
            
            if (fileInput.files && fileInput.files[0]) {
                var fileSize = fileInput.files[0].size;
                
                if (fileSize > maxFileSize) {
                    // 显示错误信息
                    errorDiv.show();
                    // 禁用提交按钮
                    submitButton.prop('disabled', true);
                    // 添加红色边框
                    $(fileInput).css('border', '1px solid red');
                    // 显示友好的文件大小
                    var fileSizeMB = (fileSize / (1024 * 1024)).toFixed(2);
                    errorDiv.text('文件大小(' + fileSizeMB + 'MB)超过限制(2MB)，无法上传');
                } else {
                    // 隐藏错误信息
                    errorDiv.hide();
                    // 启用提交按钮
                    submitButton.prop('disabled', false);
                    // 移除红色边框
                    $(fileInput).css('border', '');
                }
            }
        });
        
        // 为所有AJAX请求添加CSRF令牌
        $.ajaxSetup({
            beforeSend: function(xhr) {
                xhr.setRequestHeader(csrfHeader, csrfToken);
            }
        });
        
        // 使用 stupidtable 初始化表格排序
        $("#fileTable").stupidtable();
        // 默认按上传时间降序排序
        $("#fileTable").find("th:eq(5)").stupidsort('desc');
        
        // Handle file disable/enable toggle
        $(document).on("click", ".toggle-disabled", function(e) {
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
                        var statusCell = button.closest('tr').find('td:nth-child(11)');
                        
                        if (newDisabled) {
                            button.html('<span class="blueSubmit">启用</span>');
                            statusCell.html('<span style="color: red;">已禁用</span>');
                        } else {
                            button.html('<span class="redSubmit">禁用</span>');
                            statusCell.html('<span style="color: green;">可用</span>');
                        }
                    } else {
                        alert("操作失败");
                    }
                },
                error: function(xhr, status, error) {
                    console.error("AJAX Error:", status, error);
                    alert("操作失败: " + error);
                }
            });
        });
        
        // 下载次数编辑功能现在通过模态对话框实现
        
        // Handle file deletion
        $(document).on("click", ".delete-file", function(e) {
            e.preventDefault();
            if (confirm("确定要删除此文件吗?")) {
                var fileId = $(this).data("id");
                $.ajax({
                    url: "${ctxPath}/manager/files/" + fileId,
                    type: "POST",
                    data: { _method: "DELETE", '${_csrf.parameterName}': '${_csrf.token}' },
                    success: function(response) {
                        if (response === "success") {
                            // 找到当前行并移除
                            var row = $("button[data-id='" + fileId + "']").closest('tr');
                            row.fadeOut(400, function() {
                                row.remove();
                            });
                        } else {
                            alert("删除失败");
                        }
                    },
                    error: function(xhr, status, error) {
                        console.error("AJAX Error:", status, error);
                        alert("删除失败: " + error);
                    }
                });
            }
        });
        
        // Handle URL copying
        $(document).on("click", ".copy-url", function(e) {
            e.preventDefault();
            var relativeUrl = $(this).data("url");
            // 构建完整的URL包含域名
            var fullUrl = window.location.origin + relativeUrl;
            var tempInput = document.createElement("input");
            document.body.appendChild(tempInput);
            tempInput.value = fullUrl;
            tempInput.select();
            document.execCommand("copy");
            document.body.removeChild(tempInput);
            
            // 显示临时提示而不是弹窗
            var button = $(this);
            var originalText = button.html();
            button.html('<span class="blueSubmit">已复制!</span>');
            
            // 2秒后恢复原始文本
            setTimeout(function() {
                button.html(originalText);
            }, 2000);
        });
        
        // Handle version update
        $(document).on("click", ".update-version", function(e) {
            e.preventDefault();
            var fileId = $(this).data("id");
            $("#updateFileId").val(fileId);
            $("#updateFileModal").show();
        });
        
        // Close modal when clicking the close button
        $(document).on("click", ".close-modal", function() {
            $("#updateFileModal").hide();
            $("#editMaxDownloadsModal").hide();
        });
        
        // Handle max downloads editing
        $(document).on("click", ".edit-max-downloads", function(e) {
            e.preventDefault();
            var fileId = $(this).data("id");
            var currentMaxDownloads = $(this).data("current");
            $("#editFileId").val(fileId);
            $("#maxDownloadsInput").val(currentMaxDownloads);
            $("#editMaxDownloadsModal").show();
        });
        
        // Save max downloads
        $(document).on("click", "#saveMaxDownloads", function() {
            var fileId = $("#editFileId").val();
            var maxDownloads = $("#maxDownloadsInput").val();
            
            $.ajax({
                url: "${ctxPath}/manager/files/max-downloads/" + fileId,
                type: "POST",
                data: { maxDownloads: maxDownloads },
                success: function(response) {
                    if (response === "success") {
                        $("#editMaxDownloadsModal").hide();
                        // 刷新页面显示更新后的数据
                        location.reload();
                    } else {
                        alert("更新失败: " + response);
                    }
                },
                error: function(xhr, status, error) {
                    console.error("AJAX Error:", status, error);
                    alert("更新失败: " + error);
                }
            });
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
    
    .update-notes-container {
        max-height: 100px; /* 约5行文本的高度 */
        width: 25em; /* 固定宽度为25个字符 */
        overflow: hidden;
        text-overflow: ellipsis;
        display: -webkit-box;
        -webkit-line-clamp: 5; /* 限制最多显示5行 */
        line-clamp: 5; /* 标准属性，提高兼容性 */
        -webkit-box-orient: vertical;
        line-height: 1.3;
        cursor: help; /* 鼠标悬停时显示帮助图标 */
        word-break: break-all; /* 允许在任意字符间断行 */
        text-align: center; /* 文本居中展示 */
        margin: 0 auto; /* 居中容器 */
    }
    
    /* 描述列的样式 */
    .file-description {
        text-align: center; /* 文本居中展示 */
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
                            <form:input path="maxDownloads" type="number" min="0" value="1000" />
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
                    <th data-sort="int">ID</th>
                    <th data-sort="string">文件名</th>
                    <th data-sort="string">版本</th>
                    <th data-sort="string">描述</th>
                    <th data-sort="string">大小</th>
                    <th data-sort="string">上传时间</th>
                    <th data-sort="string">最后更新</th>
                    <th data-sort="int">下载次数</th>
                    <th data-sort="string">更新说明</th>
                    <th data-sort="string">状态</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach items="${files}" var="file">
                    <tr>
                        <td>${file.id}</td>
                        <td>
                            <c:choose>
                                <c:when test="${file.disabled || (file.maxDownloads > 0 && file.downloadCount >= file.maxDownloads)}">
                                    <span title="文件已禁用或达到下载上限">${file.originalName}</span>
                                </c:when>
                                <c:otherwise>
                                    <a href="${ctxPath}/files/download/name/${file.originalName}" title="点击下载文件">${file.originalName}</a>
                                </c:otherwise>
                            </c:choose>
                        </td>
                        <td>${not empty file.version ? file.version : '1.0'}</td>
                        <td class="file-description">${file.description}</td>
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
                                <c:choose>
                                    <c:when test="${file.maxDownloads > 0}">
                                        / ${file.maxDownloads}
                                    </c:when>
                                    <c:otherwise>
                                        / <span title="无限制下载次数">无限制</span>
                                    </c:otherwise>
                                </c:choose>
                            </span>
                            <button class="edit-max-downloads" data-id="${file.id}" data-current="${file.maxDownloads}" title="编辑最大下载次数">
                                <i class="fa fa-edit">调整</i>
                            </button>
                        </td>
                        <td><div class="update-notes-container">${file.updateNotes}</div></td>
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
                            <c:choose>
                                <c:when test="${file.disabled || (file.maxDownloads > 0 && file.downloadCount >= file.maxDownloads)}">
                                    <span class="graySubmit" style="text-decoration: none; cursor: not-allowed;" title="文件已禁用或达到下载上限">下载描述</span>
                                </c:when>
                                <c:otherwise>
                                    <a href="${ctxPath}/files/download-description/name/${file.originalName}" class="blueSubmit" style="text-decoration: none;">下载描述</a>
                                </c:otherwise>
                            </c:choose>
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
                            <c:choose>
                                <c:when test="${file.disabled || (file.maxDownloads > 0 && file.downloadCount >= file.maxDownloads)}">
                                    <button class="disabled-button" disabled title="文件已禁用或达到下载上限">
                                        <span class="graySubmit">复制URL</span>
                                    </button>
                                </c:when>
                                <c:otherwise>
                                    <button class="copy-url" data-url="${ctxPath}/files/download/name/${file.originalName}">
                                        <span class="blueSubmit">复制URL</span>
                                    </button>
                                </c:otherwise>
                            </c:choose>
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
                
                <c:forEach begin="${Math.max(1, currentPage - 2)}" end="${Math.min(totalPages.intValue(), currentPage + 2)}" var="i">
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
</div>
</div>

<!-- 编辑下载次数模态对话框 -->
<div id="editMaxDownloadsModal" style="display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.4);">
    <div style="background-color: #fefefe; margin: 15% auto; padding: 20px; border: 1px solid #888; width: 30%;">
        <span class="close-modal" style="color: #aaa; float: right; font-size: 28px; font-weight: bold; cursor: pointer;">&times;</span>
        <h2>编辑最大下载次数</h2>
        <form id="editMaxDownloadsForm">
            <input type="hidden" id="editFileId" name="id" value="">
            <table class="userInput">
                <tr>
                    <td>最大下载次数:</td>
                    <td>
                        <input type="number" id="maxDownloadsInput" name="maxDownloads" min="0" value="1000" />
                        <div><small>0 表示无限制</small></div>
                    </td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                        <button type="button" id="saveMaxDownloads" class="blueSubmit">保存</button>
                        <button type="button" class="close-modal redSubmit">取消</button>
                    </td>
                </tr>
            </table>
        </form>
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
                        <input type="file" name="file" id="fileInput" required />
                        <div><small>最大文件大小: 2MB</small></div>
                    </td>
                </tr>
                <tr>
                    <td>描述:</td>
                    <td>
                        <textarea name="description" rows="3" cols="50"></textarea>
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
    // 表单提交处理
    $(document).on("submit", "#updateFileForm", function(e) {
        e.preventDefault();
        var formData = new FormData(this);
        
        // 添加CSRF令牌
        formData.append('${_csrf.parameterName}', '${_csrf.token}');
        
        $.ajax({
            url: $(this).attr("action"),
            type: "POST",
            data: formData,
            processData: false,
            contentType: false,
            success: function(response) {
                alert("文件版本更新成功");
                $("#updateFileModal").hide();
                
                // 获取表单数据
                var fileId = $("#updateFileId").val();
                var version = $("input[name='version']").val();
                var updateNotes = $("textarea[name='updateNotes']").val();
                
                // 更新表格中的数据
                var row = $("button.update-version[data-id='" + fileId + "']").closest('tr');
                row.find('td:nth-child(3)').text(version); // 版本列
                row.find('td:nth-child(10)').text(updateNotes); // 更新说明列
                
                // 更新最后更新时间
                var now = new Date();
                var formattedDate = now.getFullYear() + '-' + 
                    String(now.getMonth() + 1).padStart(2, '0') + '-' + 
                    String(now.getDate()).padStart(2, '0') + ' ' + 
                    String(now.getHours()).padStart(2, '0') + ':' + 
                    String(now.getMinutes()).padStart(2, '0');
                row.find('td:nth-child(7)').text(formattedDate); // 最后更新列
                
                // 清空表单
                $("#updateFileForm")[0].reset();
            },
            error: function(xhr, status, error) {
                console.error("AJAX Error:", status, error);
                alert("更新失败，请重试: " + error);
            }
        });
    });
</script>

<!-- 编辑下载次数模态对话框 -->
<div id="editMaxDownloadsModal" style="display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.4);">
    <div style="background-color: #fefefe; margin: 15% auto; padding: 20px; border: 1px solid #888; width: 50%;">
        <span class="close-modal" style="color: #aaa; float: right; font-size: 28px; font-weight: bold; cursor: pointer;">&times;</span>
        <h2>编辑最大下载次数</h2>
        <form id="editMaxDownloadsForm" action="${ctxPath}/manager/files/max-downloads" method="POST">
            <input type="hidden" id="editFileId" name="fileId" value="">
            <table class="userInput">
                <tr>
                    <td>最大下载次数:</td>
                    <td>
                        <input type="number" id="maxDownloads" name="maxDownloads" min="0" value="0" />
                        <p><small>设置为0表示无限制下载</small></p>
                    </td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                        <button type="submit" class="blueSubmit">保存</button>
                        <button type="button" class="close-modal redSubmit">取消</button>
                    </td>
                </tr>
            </table>
        </form>
    </div>
</div>

<%@ include file="00-footer.jsp" %>
