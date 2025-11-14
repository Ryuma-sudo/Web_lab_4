<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Student List</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        h1 { color: #333; }
        .message {
            padding: 10px;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .btn {
            display: inline-block;
            padding: 10px 20px;
            margin-bottom: 20px;
            background-color: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
        input[type="text"] {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            box-sizing: border-box;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background-color: white;
        }
        th {
            background-color: #007bff;
            color: white;
            padding: 12px;
            text-align: left;
        }
        td {
            padding: 10px;
            border-bottom: 1px solid #ddd;
        }
        tr:hover { background-color: #f8f9fa; }
        .action-link {
            color: #007bff;
            text-decoration: none;
            margin-right: 10px;
        }
        .delete-link { color: #dc3545; }
        .pagination {
            margin-top: 20px;
        }
        .pagination a, .pagination strong {
            padding: 8px 12px;
            margin: 0 3px;
            text-decoration: none;
            background: #007bff;
            color: white;
            border-radius: 5px;
        }
        .pagination strong {
            background: #0056b3;
        }
        .success::before { content: "✓ "; font-weight: bold; }
        .error::before { content: "✗ "; font-weight: bold; }
        .table-responsive {
            overflow-x: auto;
        }

        @media (max-width: 768px) {
            table {
                font-size: 12px;
            }
            th, td {
                padding: 5px;
            }
        }
    </style>
    <script>
        setTimeout(function() {
            document.querySelectorAll('.message').forEach(function(msg) {
                msg.style.display = 'none';
            });
        }, 5000);
    </script>
</head>
<body>
<h1>📚 Student Management System</h1>
<div>
    <form action="list_students.jsp" method="GET">
        <input type="text" name="keyword" placeholder="Search by name or code..." value="<%= request.getParameter("keyword") != null ? request.getParameter("keyword") : "" %>">
        <button type="submit" class="btn">Search</button>
        <a href="list_students.jsp" class="btn">Clear</a>
    </form>
</div>

<% if (request.getParameter("message") != null) { %>
<div class="message success">
    <%= request.getParameter("message") %>
</div>
<% } %>

<% if (request.getParameter("error") != null) { %>
<div class="message error">
    <%= request.getParameter("error") %>
</div>
<% } %>

<a href="add_student.jsp" class="btn">➕ Add New Student</a>
<div class="table-responsive">
    <table>
        <thead>
        <tr>
            <th>ID</th>
            <th>Student Code</th>
            <th>Full Name</th>
            <th>Email</th>
            <th>Major</th>
            <th>Created At</th>
            <th>Actions</th>
        </tr>
        </thead>
        <tbody>
        <%
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            int totalPages = 0;
            int currentPage = 1;

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(
                        "jdbc:mysql://localhost:3306/student_management",
                        "root",
                        "09141207" // Use your DB password
                );

                // --- Get Parameters ---
                String pageParam = request.getParameter("page");
                String keyword = request.getParameter("keyword");
                String likeKeyword = null;
                boolean isSearch = (keyword != null && !keyword.trim().isEmpty());

                if (isSearch) {
                    likeKeyword = "%" + keyword + "%";
                }

                // --- Pagination Setup ---
                currentPage = (pageParam != null) ? Integer.parseInt(pageParam) : 1;
                int recordsPerPage = 10;
                int offset = (currentPage - 1) * recordsPerPage;

                // --- Count total records (Corrected for Search) ---
                String countSql;
                PreparedStatement countStmt;

                if (isSearch) {
                    countSql = "SELECT COUNT(*) FROM students WHERE full_name LIKE ? OR student_code LIKE ? OR major LIKE ?";
                    countStmt = conn.prepareStatement(countSql);
                    countStmt.setString(1, likeKeyword);
                    countStmt.setString(2, likeKeyword);
                    countStmt.setString(3, likeKeyword);
                } else {
                    countSql = "SELECT COUNT(*) FROM students";
                    countStmt = conn.prepareStatement(countSql);
                }

                ResultSet countRs = countStmt.executeQuery();
                int totalRecords = 0;
                if (countRs.next()) {
                    totalRecords = countRs.getInt(1);
                }
                totalPages = (int) Math.ceil((double) totalRecords / recordsPerPage);

                // Close count resources
                countRs.close();
                countStmt.close();


                // --- Main Query With Search + Pagination ---
                String sql;
                if (isSearch) {
                    sql = "SELECT * FROM students " +
                            "WHERE full_name LIKE ? OR student_code LIKE ? OR major LIKE ? " +
                            "ORDER BY id DESC LIMIT ? OFFSET ?";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, likeKeyword);
                    pstmt.setString(2, likeKeyword);
                    pstmt.setString(3, likeKeyword);
                    pstmt.setInt(4, recordsPerPage);
                    pstmt.setInt(5, offset);
                } else {
                    sql = "SELECT * FROM students ORDER BY id DESC LIMIT ? OFFSET ?";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, recordsPerPage);
                    pstmt.setInt(2, offset);
                }

                rs = pstmt.executeQuery();

                if (!rs.isBeforeFirst()) { // Check if no records found
                    out.println("<tr><td colspan='7'>No students found.</td></tr>");
                }

                while (rs.next()) {
                    int id = rs.getInt("id");
                    String studentCode = rs.getString("student_code");
                    String fullName = rs.getString("full_name");
                    String email = rs.getString("email");
                    String major = rs.getString("major");
                    Timestamp createdAt = rs.getTimestamp("created_at");
        %>
        <tr>
            <td><%= id %></td>
            <td><%= studentCode %></td>
            <td><%= fullName %></td>
            <td><%= email != null ? email : "N/A" %></td>
            <td><%= major != null ? major : "N/A" %></td>
            <td><%= createdAt %></td>
            <td>
                <a href="edit_student.jsp?id=<%= id %>" class="action-link">✏️ Edit</a>
                <a href="delete_student.jsp?id=<%= id %>"
                   class="action-link delete-link"
                   onclick="return confirm('Are you sure?')">🗑️ Delete</a>
            </td>
        </tr>
        <%
                }
            } catch (ClassNotFoundException e) {
                out.println("<tr><td colspan='7'>Error: JDBC Driver not found!</td></tr>");
                e.printStackTrace();
            } catch (SQLException e) {
                out.println("<tr><td colspan='7'>Database Error: " + e.getMessage() + "</td></tr>");
                e.printStackTrace();
            } finally {
                try {
                    if (rs != null) rs.close();
                    if (pstmt != null) pstmt.close();
                    if (conn != null) conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        %>
        </tbody>
    </table>
</div>

<div class="pagination">
    <%
        String searchParams = (request.getParameter("keyword") != null) ? "&keyword=" + request.getParameter("keyword") : "";

        if (currentPage > 1) {
    %>
    <a href="list_students.jsp?page=<%= currentPage - 1 %><%= searchParams %>">Previous</a>
    <% } %>

    <% for (int i = 1; i <= totalPages; i++) { %>
    <% if (i == currentPage) { %>
    <strong><%= i %></strong>
    <% } else { %>
    <a href="list_students.jsp?page=<%= i %><%= searchParams %>"><%= i %></a>
    <% } %>
    <% } %>

    <% if (currentPage < totalPages) { %>
    <a href="list_students.jsp?page=<%= currentPage + 1 %><%= searchParams %>">Next</a>
    <% } %>
</div>
</body>
</html>