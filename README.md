## STUDENT INFORMATION:
Name: Nguyen Quang Truc
Student ID: ITCSIU23041
Class: Group 2

## COMPLETED EXERCISES:
[x] Exercise 5: Search Functionality
[x] Exercise 6: Validation Enhancement
[x] Exercise 7: Pagination
[ ] Bonus 1: CSV Export
[ ] Bonus 2: Sortable Columns

## 1. List Students - `list_students.jsp`

<img width="3050" height="933" alt="image" src="https://github.com/user-attachments/assets/d9c57bf5-e653-4dc5-9f57-07c176d44241" />

This flow explains how the initial list of students is retrieved and displayed.

### Flow: Client $\to$ Server $\to$ Database $\to$ Server $\to$ Client

1.  **Client Request:** The user navigates to the main application URL: `http://.../list_students.jsp`.
2.  **Server Execution (Start):** Tomcat receives the request and starts executing `list_students.jsp` line by line, top-to-bottom.
3.  **Setup & Connection:** The JSP scriptlet (`<% %>`) code executes:
    * It imports `java.sql.*`.
    * `Class.forName()` attempts to load the JDBC driver.
    * `DriverManager.getConnection()` establishes a connection (`conn`) to the `student_management` MySQL database.
    * A `Statement` (`stmt`) is created.
4.  **Database Query:** The SQL `SELECT` statement (`SELECT * FROM students ORDER BY id DESC`) is executed via `stmt.executeQuery()`.
5.  **Database Response:** The MySQL server executes the query and sends the results back to the server as a `ResultSet` (`rs`).
6.  **Server Processing & HTML Generation:** The `while (rs.next())` loop executes:
    * For each row in the `ResultSet`, Java retrieves column values (`id`, `student_code`, etc.).
    * The JSP Expression (`<%= %>`) tags dynamically inject these retrieved values into the HTML table row (`<tr> </tr>`).
    * Action links for Edit and Delete, passing the student `id` as a URL parameter, are generated.
7.  **Resource Cleanup:** The `finally` block ensures the `ResultSet`, `Statement`, and `Connection` are safely closed, regardless of success or failure.
8.  **Client Response:** Tomcat sends the fully generated HTML page (the table containing all student data) back to the client browser for rendering.

---

## 2. Add Student - `add_student.jsp` $\to$ `process_add.jsp`

<img width="1213" height="927" alt="image" src="https://github.com/user-attachments/assets/fc5e481a-36fe-41e3-9c3a-d3d605166bcf" />
<img width="3022" height="873" alt="image" src="https://github.com/user-attachments/assets/0c219f6e-c1d9-45c8-817c-e79912b8a617" />

This is a two-step Post-Redirect-Get flow.

### Flow: Client $\to$ Server $\to$ Database $\to$ Server $\to$ Client

1.  **Client Request (Form Display):** The user clicks the "Add New Student" link, loading **`add_student.jsp`**. This JSP renders an empty HTML form with `method="POST"` and `action="process_add.jsp"`.
2.  **Client Action (Form Submission):** The user fills out the form and clicks "Save Student." The browser sends an HTTP **POST** request containing the form data to **`process_add.jsp`**.
3.  **Server Execution (Process):** **`process_add.jsp`** executes:
    * `request.getParameter()` retrieves the form fields (`student_code`, `full_name`, etc.).
    * **Server-Side Validation:** Checks if required fields are missing. If invalid, it redirects back to `add_student.jsp` with an error message.
4.  **Database Connection:** A connection to MySQL is established.
5.  **Database Insert:**
    * A `PreparedStatement` is created using the SQL `INSERT` command with placeholders (`?`).
    * `pstmt.setString()` binds the user input (data) to the placeholders, safely preventing SQL injection.
    * `pstmt.executeUpdate()` executes the command.
6.  **Server Redirect (Post-Redirect-Get):**
    * If `rowsAffected > 0` (success), the server issues a redirect command (`response.sendRedirect`) to **`list_students.jsp?message=...`**.
    * If an error occurs (e.g., duplicate student code), it redirects back to **`add_student.jsp?error=...`**.
7.  **Client Response:** The client browser receives the redirect instruction and immediately makes a new **GET** request to **`list_students.jsp`**, which then displays the updated list and the success message.

---

## 3. Edit Student - `edit_student.jsp` $\to$ `process_edit.jsp`

<img width="1182" height="920" alt="image" src="https://github.com/user-attachments/assets/a825ecdd-d951-4740-9570-8e3f2e9b41d0" />
<img width="3048" height="882" alt="image" src="https://github.com/user-attachments/assets/4fedc0a6-46f2-4aa2-974c-a92d254f6d51" />

This flow also involves two pages but requires a preliminary database query to pre-fill the form.

### Flow: Client $\to$ Server $\to$ Database $\to$ Server $\to$ Client

1.  **Client Request (Pre-fill Form):** The user clicks the "Edit" link, sending a GET request to **`edit_student.jsp?id=X`**.
2.  **Server Execution (Fetch Data):** **`edit_student.jsp`** executes:
    * Retrieves the `id` from the URL parameter.
    * Establishes a connection.
    * Executes a `SELECT * FROM students WHERE id = ?` query.
    * It fetches the current student details from the `ResultSet`.
3.  **HTML Generation:** The retrieved values are inserted into the form inputs using the `value="<%= studentCode %>"` attribute. A hidden input field (`<input type="hidden" name="id" value="<%= studentId %>">`) is included to track which record to update.
4.  **Client Action (Form Submission):** The user modifies data and submits the form via HTTP **POST** to **`process_edit.jsp`**.
5.  **Server Execution (Process Update):** **`process_edit.jsp`** executes:
    * Retrieves all form data, including the hidden `id`.
    * Establishes a connection.
    * Creates and prepares the SQL `UPDATE` statement: `UPDATE students SET full_name = ?, email = ?, major = ? WHERE id = ?`.
    * `pstmt.executeUpdate()` executes the update.
6.  **Server Redirect (Post-Redirect-Get):**
    * On success, redirects to **`list_students.jsp?message=...`**.
    * On failure, redirects back to **`edit_student.jsp?id=X&error=...`**.
7.  **Client Response:** The client loads the updated list page.

---

## 4. Delete Student - `delete_student.jsp`

<img width="792" height="242" alt="image" src="https://github.com/user-attachments/assets/ea465525-54d3-4287-9001-a282fdca1beb" />
<img width="3037" height="815" alt="image" src="https://github.com/user-attachments/assets/a0556fe3-5f28-4901-90c2-1f7287dd1e98" />

This is a single-page, immediate process executed via a GET link.

### Flow: Client $\to$ Server $\to$ Database $\to$ Server $\to$ Client

1.  **Client Request (Confirmation):** The user clicks the "Delete" link. The JavaScript `onclick="return confirm('Are you sure?')"` triggers, asking for confirmation. If the user clicks **OK**, the browser sends a **GET** request to **`delete_student.jsp?id=X`**.
2.  **Server Execution (Process Delete):** **`delete_student.jsp`** executes:
    * Retrieves the `id` from the URL parameter.
    * Establishes a connection.
3.  **Database Delete:**
    * Creates and prepares the SQL `DELETE` statement: `DELETE FROM students WHERE id = ?`.
    * **CRITICAL:** The `WHERE` clause ensures only the specified student is deleted.
    * `pstmt.executeUpdate()` executes the delete operation.
4.  **Server Redirect:**
    * If `rowsAffected > 0`, it redirects to **`list_students.jsp?message=...`**.
    * If `rowsAffected = 0` (ID not found) or a `SQLException` occurs, it redirects to **`list_students.jsp?error=...`**.
5.  **Client Response:** The client loads the list page, showing the resulting data.
That's great progress! Based on the comprehensive lab guide you provided, exercises 5, 6, and 7 cover the implementation of the core **CRUD** operations: **Read (List)**, **Create (Add)**, **Update (Edit)**, and **Delete**.

Here is the report summarizing the implementation and key takeaways for each exercise.

---

### 5. Search functionality

<img width="3042" height="700" alt="image" src="https://github.com/user-attachments/assets/17e02ddd-f448-49b7-9f3a-a59e3078c6b5" />

### 6. Validation enhancement

<img width="1189" height="961" alt="image" src="https://github.com/user-attachments/assets/5606f98f-c4be-4566-8a1c-6d4573681261" />

### 7. User experiment improvements

<img width="3029" height="925" alt="image" src="https://github.com/user-attachments/assets/40ad1e43-9dd7-41fb-b077-f858340a7015" />
<img width="3021" height="582" alt="image" src="https://github.com/user-attachments/assets/cad1f4bb-3a36-4fd4-9e02-8cfd86508454" />



