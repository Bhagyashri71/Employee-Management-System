-- 1. Question: Retrieve the first and last names of all employees.
SELECT FirstName, LastName 
FROM Employee ;

-- 2. Retrieve the first and last names of employees who work as 'Software Engineer'.
SELECT FirstName, LastName 
FROM Employee 
WHERE JobTitleID = (SELECT JobTitleID FROM JobTitle 
                    WHERE JobTitleName = 'Software Engineer');

-- 3. Question: Retrieve first names and last names of last 7 hires
SELECT TOP 7 FirstName, LastName
FROM Employee 
ORDER BY HireDate DESC;

-- 4. Question: Get the count of employees in each job title.
SELECT JobTitleName, COUNT(EmployeeID) employee_count
FROM Employee E
INNER JOIN JobTitle J 
ON E.JobTitleID = J.JobTitleID 
GROUP BY J.JobTitleName;

-- 5. Question: Retrieve the full name & other personal info of employees who work in the 'Engineering' department.
SELECT CONCAT(FirstName,' ',LastName) as FullName, 
        DateOfBirth, Gender, PhoneNumber
FROM Employee E 
INNER JOIN Department D 
ON E.DepartmentID = D.DepartmentID
WHERE D.DepartmentName = 'Engineering' ;

-- 6. Question: List job titles that have more than 3 employees.
SELECT JobTitleName, COUNT(EmployeeID) employee_count
FROM Employee E
INNER JOIN JobTitle J 
ON E.JobTitleID = J.JobTitleID 
GROUP BY J.JobTitleName
HAVING COUNT(EmployeeID) > 3;  -- To filter aggregate function where clause wont work

-- 7. Question: Retrieve all employee names along with their department names. 
SELECT FirstName, LastName, DepartmentName
FROM Employee E 
INNER JOIN Department D 
ON E.DepartmentID = D.DepartmentID;

-- 8. Question: Retrieve the first names of employees and the projects they are working on, along with their role in the project.
SELECT FirstName, ProjectName, JobTitleName AS 'Role'
FROM Employee E 
INNER JOIN ProjectAllocation PA 
ON E.EmployeeID = PA.EmployeeID 
INNER JOIN Project P 
ON P.ProjectID = PA.ProjectID
INNER JOIN JobTitle J 
ON J.JobTitleID = E.JobTitleID;

-- 9. Question: Get the count of employees in each department
SELECT DepartmentName, COUNT(EmployeeID) AS EmployeeCount 
FROM Employee E
JOIN Department D 
ON E.DepartmentID = D.DepartmentID
GROUP BY DepartmentName;

-- 10. Question: List all departments with more than 5 employees.
SELECT DepartmentName, COUNT(EmployeeID) AS EmployeeCount 
FROM Employee E
JOIN Department D 
ON E.DepartmentID = D.DepartmentID
GROUP BY DepartmentName
HAVING COUNT(EmployeeID) > 5;

-- 11. Question: Retrieve the full names of employees and their managers.
SELECT CONCAT(E.FirstName, ' ', E.LastName) as 'Employee Name',
        CONCAT(M.FirstName, ' ', M.LastName) as 'Manager Name'
FROM Employee E 
INNER JOIN EMPLOYEE M
ON E.ManagerID = M.EmployeeID;

-- 12. Question: Which manager is managing more employees and how many
SELECT TOP 1 
        CONCAT(M.FirstName, ' ', M.LastName) as 'Manager Name',
        COUNT(E.EmployeeID) AS NumberOfEmployees
FROM Employee E 
INNER JOIN EMPLOYEE M
ON E.ManagerID = M.EmployeeID
GROUP BY M.EmployeeID, M.FirstName, M.LastName
ORDER BY 2 DESC;

-- 13. Question: Retrieve names of employees working on projects as 'Software Engineer', ordered by project start date
SELECT FirstName, LastName, ProjectName, StartDate
FROM Employee E 
INNER JOIN ProjectAllocation PA 
ON E.EmployeeID = PA.EmployeeID 
INNER JOIN Project P 
ON PA.ProjectID = P.ProjectID
INNER JOIN JobTitle J 
ON J.JobTitleID = E.JobTitleID 
WHERE JobTitleName = 'Software Engineer' 
ORDER BY 4;

-- 14. Question: Retrieve the names of employees who are working on 'Project Delta'.
SELECT FirstName, LastName FROM Employee
WHERE EmployeeID IN (SELECT EmployeeID FROM ProjectAllocation
                    WHERE ProjectID = (SELECT ProjectID FROM PROJECT 
                                        WHERE ProjectName = 'Project Delta')) ;

-- 15. Question: Retrieve the names of employees, department name, and total salary, ordered by total salary in descending order
SELECT FirstName, LastName, DepartmentName,
    (BaseSalary + Bonus - Deductions) AS TotalSalary
FROM Employee E 
INNER JOIN Department D 
ON E.DepartmentID = D.DepartmentID
INNER JOIN Salary S 
ON S.EmployeeID = E.EmployeeID
ORDER BY 4 DESC ;

-- 16. Question: Create a function to find employees with a birthday in the given month and calculate their age
GO
CREATE FUNCTION fn_GetBirthday(@Month INT)
RETURNS TABLE
AS
RETURN
(
    SELECT FirstName, LastName, DateOfBirth,
        YEAR(GETDATE()) - YEAR(DateOfBirth) Age
    FROM Employee
    WHERE MONTH(DateOfBirth) = @Month
);
GO

-- 17. Find employees who have a birthday in November and their age
SELECT * FROM DBO.fn_GetBirthday(11);

-- 18. Find employees who have a birthday in March and their age
SELECT * FROM DBO.fn_GetBirthday(3);


-- 19: Create a function to find employees in a specified department and calculate their years of service
GO 
CREATE FUNCTION fn_GetDepartment(@departmentname VARCHAR(100))
RETURNS TABLE 
AS 
RETURN
(
	SELECT FIRSTNAME, LASTNAME, DEPARTMENTNAME, 
			YEAR(GETDATE()) - YEAR(HIREDATE) TOTAL_SERVICE_YEARS
	FROM EMPLOYEE E
	INNER JOIN DEPARTMENT D 
	ON E.DEPARTMENTID = D.DEPARTMENTID
	WHERE DEPARTMENTNAME = @DEPARTMENTNAME
);
GO

--20. Find employees in the SALES department and their years of service
SELECT * FROM DBO.fn_GetDepartment('Sales');

--21. Find employees in the HR department and their years of service
SELECT * FROM DBO.fn_GetDepartment('Human Resources');
