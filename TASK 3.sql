use EMS;

-- Problem 1 : Whenever an employee's BaseSalary, Bonus, or Deductions changes, store the old and new values in a salary audit table.
-- First we need to create the audit table then trigger.
CREATE TABLE SalaryAudit
(
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    SalaryID INT,
    EmployeeID INT,
    OldBaseSalary DECIMAL(10,2),
    NewBaseSalary DECIMAL(10,2),
    OldBonus DECIMAL(10,2),
    NewBonus DECIMAL(10,2),
    OldDeductions DECIMAL(10,2),
    NewDeductions DECIMAL(10,2),
    ChangeDate DATETIME,
    ChangedBy VARCHAR(100)
);

-- creating trigger
CREATE TRIGGER trg_SalaryAudit
ON Salary
AFTER UPDATE
AS
BEGIN

    INSERT INTO SalaryAudit
    (
        SalaryID,
        EmployeeID,
        OldBaseSalary,
        NewBaseSalary,
        OldBonus,
        NewBonus,
        OldDeductions,
        NewDeductions,
        ChangeDate,
        ChangedBy
    )
    SELECT
        d.SalaryID,
        d.EmployeeID,
        d.BaseSalary,
        i.BaseSalary,
        d.Bonus,
        i.Bonus,
        d.Deductions,
        i.Deductions,
        GETDATE(),
        SYSTEM_USER
    FROM deleted d
    JOIN inserted i
        ON d.SalaryID = i.SalaryID
    WHERE
        d.BaseSalary <> i.BaseSalary
        OR ISNULL(d.Bonus,0) <> ISNULL(i.Bonus,0)
        OR ISNULL(d.Deductions,0) <> ISNULL(i.Deductions,0);

END;

-- Problem 2 : BaseSalary, Bonus, and Deductions should never be negative
CREATE TRIGGER trg_PreventNegativeSalary
ON Salary
AFTER INSERT, UPDATE
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE BaseSalary < 0
           OR ISNULL(Bonus,0) < 0
           OR ISNULL(Deductions,0) < 0
    )
    BEGIN

        RAISERROR(
            'Salary, bonus and deductions cannot be negative.',
            16,
            1
        );
        ROLLBACK TRANSACTION;
    END
END;


-- Problem 3 : Increase an employee's base salary by 10%.
BEGIN TRY

    BEGIN TRANSACTION;

    UPDATE Salary
    SET BaseSalary = BaseSalary * 1.10
    WHERE EmployeeID = 10;

    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    ROLLBACK TRANSACTION;

    SELECT ERROR_MESSAGE() AS ErrorMessage;

END CATCH;

select * from SalaryAudit

-- Problem 4: For Employee 11: Increase bonus by ₹5,000
--							Reduce deductions by ₹1,000

BEGIN TRY

    BEGIN TRANSACTION;

    UPDATE Salary
    SET
        Bonus = ISNULL(Bonus,0) + 5000,
        Deductions = ISNULL(Deductions,0) - 1000
    WHERE EmployeeID = 11;

    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    ROLLBACK TRANSACTION;

    SELECT ERROR_MESSAGE() AS ErrorMessage;

END CATCH;


-- Problem 6: Move Employee 11 to Department 4.

select * from Department
select * from Employee

BEGIN TRY

    BEGIN TRANSACTION;

    UPDATE Employee
    SET DepartmentID = 4
    WHERE EmployeeID = 11;

    IF @@ROWCOUNT = 0
        THROW 50001, 'Employee not found.', 1;

    COMMIT TRANSACTION;

END TRY

BEGIN CATCH

    ROLLBACK TRANSACTION;

    SELECT ERROR_MESSAGE() AS ErrorMessage;

END CATCH;

-- Problem 7 : Rank employees from highest to lowest base salary.
SELECT
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    s.BaseSalary,

    RANK() OVER
    (
        ORDER BY s.BaseSalary DESC
    ) AS SalaryRank

FROM Employee e
JOIN Salary s
    ON e.EmployeeID = s.EmployeeID;

--Problem 8: Find each employee's salary rank inside their own department.
SELECT
    e.EmployeeID,
    CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    e.DepartmentID,
    s.BaseSalary,

    RANK() OVER
    (
        PARTITION BY e.DepartmentID
        ORDER BY s.BaseSalary DESC
    ) AS DepartmentSalaryRank

FROM Employee e
JOIN Salary s
    ON e.EmployeeID = s.EmployeeID;

-- Problem 9 : Find top 3 highest-paid employees in each department
WITH RankedEmployees AS
(
    SELECT
        e.EmployeeID,
        CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
        e.DepartmentID,
        s.BaseSalary,

        ROW_NUMBER() OVER
        (
            PARTITION BY e.DepartmentID
            ORDER BY s.BaseSalary DESC
        ) AS rn

    FROM Employee e
    JOIN Salary s
        ON e.EmployeeID = s.EmployeeID
)

SELECT *
FROM RankedEmployees
WHERE rn <= 3;


-- Problem 10 : Calculate cumulative/running salary  paid to each employee
SELECT
    EmployeeID,
    PaymentDate,
    BaseSalary,

    SUM(BaseSalary) OVER
    (
        PARTITION BY EmployeeID
        ORDER BY PaymentDate
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS CumulativeSalary

FROM Salary;

-- Problem 11: Problem: For every employee, calculate the percentage of attendance.
SELECT
    EmployeeID,

    COUNT(*) AS TotalDays,

    SUM(
        CASE
            WHEN Status = 'Present' THEN 1
            ELSE 0
        END
    ) AS PresentDays,

    SUM(
        CASE
            WHEN Status = 'Present' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS AttendancePercentage

FROM Attendance
GROUP BY EmployeeID;