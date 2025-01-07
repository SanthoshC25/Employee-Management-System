CREATE DATABASE EMS;
USE EMS;

CREATE TABLE Departments(DepartmentID INT PRIMARY KEY, DepartmentName VARCHAR(30));
INSERT INTO Departments(DepartmentID, DepartmentName) VALUES(1,'Product Management'),
                                              (2, 'Financial accounting'),
											  (3, 'IT Services'),
											  (4, 'Project Management'),
											  (5, 'Sales');
SELECT * FROM Departments;
DROP TABLE Departments;


CREATE TABLE Employees(EmployeeID INT PRIMARY KEY , Name VARCHAR(30), DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID), HireDate DATE);
INSERT INTO Employees(EmployeeID, Name,DepartmentID, HireDate) VALUES(101, 'Deepak Chandroo', 5, '08/01/2025'),
                                                                     (102, 'Santhosh Kumar C', 2, '07/12/2024'),
																	 (103, 'Madhu S', 2, '12/04/2024'),
																	 (104, 'Alice Johnson', 1, '2020-05-15'),
																	 (105, 'Bob Smith', 3, '2019-03-10'),
																	 (106, 'Charlie Brown', 3, '2021-08-20'),
																	 (107, 'David White', 2, '2018-11-05'),
																	 (108, 'Eve Green', 1, '2022-01-30');
SELECT * FROM Employees;

DROP TABLE Employees;
CREATE TABLE Salaries(EmployeeID INT FOREIGN KEY REFERENCES Employees(EmployeeID), BaseSalary DECIMAL(10,2), Bonus DECIMAL(10,2), Deductions DECIMAL(10,2))

INSERT INTO Salaries(EmployeeID, BaseSalary, Bonus, Deductions) VALUES (101, 10000, 1000, 0),
                                                            (102, 50000.00, 5000.00, 2000.00),
															(106, 60000.00, 4000.00, 1500.00),
															(108, 55000.00, 3500.00, 1800.00),
															(103, 48000.00, 2500.00, 1200.00),
															(104, 45000.00, 3000.00, 1000.00);
SELECT * FROM Salaries;

DROP TABLE Salaries;



--List all employees with their department names:

SELECT Employees.Name, Departments.DepartmentName FROM Departments LEFT OUTER JOIN Employees ON Employees.DepartmentID=Departments.DepartmentID;




--Calculate the net salary for each employee using:  Net Salary = BaseSalary + Bonus - Deductions.

SELECT Employees.Name, (Salaries.BaseSalary + Salaries.Bonus - Salaries.Deductions) AS NetSalary FROM Employees Employees JOIN Salaries Salaries ON Employees.EmployeeID= Salaries.EmployeeID;



--Identify the department with the highest average salary.

SELECT TOP 1 Departments.DepartmentID, Departments.DepartmentName, AVG(Salaries.BaseSalary + Salaries.Bonus - Salaries.Deductions) AS AvgSalary
FROM Salaries Salaries
JOIN Employees Employees ON Salaries.EmployeeID = Employees.EmployeeID
JOIN Departments Departments ON Employees.DepartmentID = Departments.DepartmentID
GROUP BY Departments.DepartmentID, Departments.DepartmentName 
ORDER BY AvgSalary DESC;



 --Add Employee Procedure

CREATE PROCEDURE AddEmployee @EmployeeID INT, @Name VARCHAR(30), @DepartmentID INT, @HireDate DATE AS
BEGIN 
INSERT INTO Employees(EmployeeID, Name, DepartmentID, HireDate)
            VALUES(@EmployeeID, @Name, @DepartmentID, @HireDate);
END;
EXEC AddEmployee 110, 'Iron man', 5, '12/04/2024';

SELECT * FROM Employees;

DROP PROCEDURE AddEmployee;



--Update Salary Procedure

CREATE PROCEDURE UpdateSalary @EmployeeID INT, @BaseSalary DECIMAL(10,2), @Bonus DECIMAL(10,2), @Deductions DECIMAL(10,2) AS
BEGIN
UPDATE Salaries SET BaseSalary=@BaseSalary, Bonus=@Bonus, Deductions=@Deductions WHERE EmployeeID=@EmployeeID;
END;

EXEC UpdateSalary 101, 15000, 1000, 0;

EXEC UpdateSalary 102,55000.00, 4000.00, 3000.00;

DROP PROCEDURE UpdateSalary;


--Calculate Total Payroll Procedure

CREATE PROCEDURE CalTotalPayroll AS 
BEGIN 
 SELECT SUM(BaseSalary + Bonus - Deductions) AS TotalPayroll
 FROM Salaries;
END;

EXEC CalTotalPayroll;



--Employee Salary View

CREATE VIEW EmployeeSalaryView AS
SELECT E.Name, D.DepartmentName, S.BaseSalary, S.Bonus, S.Deductions, (S.BaseSalary + S.Bonus - S.Deductions) AS NetSalary
FROM Employees E
JOIN Departments D ON E. DepartmentID = D.DepartmentID
JOIN Salaries S ON E.EmployeeID = S. EmployeeID;

SELECT * FROM EmployeeSalaryView;



--High Earner View

CREATE VIEW HighEarnar AS
SELECT E.Name, (S.BaseSalary + S. Bonus - S.Deductions) AS NetSalary
FROM Employees E
JOIN Salaries S ON E.EmployeeID=S.EmployeeID WHERE (S.BaseSalary + S. Bonus - S.Deductions)> 55000;

SELECT * FROM HighEarnar;



--SalaryHistory Table with Triggers


CREATE TABLE SalaryHistory(HistoryID INT PRIMARY KEY IDENTITY(1,1), 
                           EmployeeID INT FOREIGN KEY REFERENCES Employees(EmployeeID), 
						   OldBaseSalary DECIMAL(10,2), OldBonus DECIMAL(10,2), OldDeductions DECIMAL(10,2),
						   NewBaseSalary DECIMAL(10,2), NewBonus DECIMAL(10,2), NewDeductions DECIMAL(10,2),
						   ChangeDate DATETIME DEFAULT GETDATE());

EXEC sp_rename 'SalaryHistory.NewBqnus','Newbonus','COLUMN';
DROP TABLE SalaryHistory;


CREATE TRIGGER After_SalaryUpdate
ON Salaries AFTER UPDATE AS 
BEGIN 
  INSERT INTO SalaryHistory (EmployeeID, OldBaseSalary, OldBonus, OldDeductions, NewBaseSalary, NewBonus, NewDeductions)
  SELECT i.EmployeeID, 
         d.BaseSalary, d.Bonus, d.Deductions,
		 i.BaseSalary, i.Bonus, i.Deductions
   FROM inserted i
   JOIN deleted d ON i.EmployeeID = d.EmployeeID;
END;

UPDATE Salaries SET BaseSalary= 50000, Bonus=3000, Deductions=1500 WHERE EmployeeID=103;

SELECT * FROM SalaryHistory;

--Optimize Queries and Stored Procedures Using Indexing and Execution Plans;

CREATE INDEX Index_EmployeeID ON Salaries(EmployeeID);
CREATE INDEX Index_DepartmentID ON Employees(DepartmentID);



CREATE PROCEDURE Cal_TotalPayroll
AS
BEGIN
    SELECT SUM(NetSalary) AS TotalPayroll
    FROM (SELECT (BaseSalary + Bonus - Deductions) AS NetSalary
    FROM Salaries WITH (INDEX(Index_EmployeeID))) AS SalaryData;
END;
DROP PROCEDURE Cal_TotalPayroll;
EXEC Cal_TotalPayroll;