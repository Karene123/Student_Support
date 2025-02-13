# CREATE SCHEMA if not exists Educationsupport;
USE Educationsupport;

# View some of tables imported from Excel 
SELECT * FROM departments;
SELECT * FROM courses;
SELECT * FROM professors;
SELECT * FROM supervises;
SELECT * FROM additionalpractices;
SELECT * FROM quizzes;
SELECT * FROM students;


# Project Questions
# Diagnostic Questions
# Based on each department, how many students will need extra practice?
SELECT Departments.`Department Name`, COUNT(Takes.StudentID) AS nbrstrugglingstudents
FROM Takes
RIGHT JOIN Quizzes ON Takes.QuizID = Quizzes.QuizID
RIGHT JOIN Courses ON Quizzes.CourseID = Courses.CourseID
RIGHT JOIN Professors ON Courses.ProfessorID = Professors.ProfessorID
RIGHT JOIN Departments ON Professors.DepartmentID = Departments.DepartmentID 
WHERE Score <= 80
GROUP BY Departments.`Department Name`;

# How many students are in total in each deparment?
SELECT Departments.`Department Name`, COUNT(registers.StudentID) AS StudentsPerdepartment
FROM Departments
LEFT JOIN Professors ON Departments.DepartmentID = Professors.DepartmentID
LEFT JOIN Courses ON Professors.ProfessorID = Courses.ProfessorID
LEFT JOIN Registers ON Courses.CourseID = Registers.CourseID
GROUP BY Departments.`Department Name`;

# How many courses per department?
SELECT Departments.`Department Name`, COUNT(registers.CourseID) AS Nbrcourses
FROM Departments
LEFT JOIN Professors ON Departments.DepartmentID = Professors.DepartmentID
LEFT JOIN Courses ON Professors.ProfessorID = Courses.ProfessorID
LEFT JOIN Registers ON Courses.CourseID = Registers.CourseID
GROUP BY Departments.`Department Name`;


# Which departments have the most success rate vs failure rate?
SELECT Departments.`Department Name`, Departments.DepartmentID,
    SUM(CASE WHEN Takes.Score >= 80 THEN 1 ELSE 0 END) * 100/ COUNT(Takes.StudentID) AS Successrate,
    SUM(CASE WHEN Takes.Score < 80 THEN 1 ELSE 0 END) * 100/ COUNT(Takes.StudentID) AS Failurerate
FROM Departments 
LEFT JOIN Professors ON  Departments.DepartmentID = Professors.DepartmentID
LEFT JOIN Courses ON  Professors.ProfessorID = Courses.ProfessorID
LEFT JOIN Quizzes ON  Courses.CourseID = Quizzes.CourseID
LEFT JOIN Takes ON  Quizzes.QuizID = Takes.QuizID
WHERE Score <= 80 
GROUP BY Departments.`Department Name`, Departments.DepartmentID;


# Which subjects  are the most difficult for students to assimilate based on the failure rate? 
SELECT Quizzes.`Subject Name`, COUNT(Takes.StudentID) AS Studentsinneedofpractices, Quizzes.CourseID
FROM Quizzes JOIN Takes ON Quizzes.QuizID = Takes.QuizID
WHERE Score <= 80
GROUP BY Quizzes.`Subject Name`, Quizzes.CourseID;

# Let's classify each course based on their success and failure rate
SELECT CourseID,
    SUM(CASE WHEN Takes.Score >= 80 THEN 1 ELSE 0 END) * 100 / COUNT(Takes.StudentID) AS Successrate,
    SUM(CASE WHEN Takes.Score < 80 THEN 1 ELSE 0 END) * 100 / COUNT(Takes.StudentID) AS Failurerate
FROM Quizzes JOIN Takes ON  Quizzes.QuizID = Takes.QuizID
GROUP BY CourseID
ORDER BY CourseID ASC;

# What is the success rate and failure rate after providing the additional exercises?
SELECT additionalpractices.CourseID,
		SUM(CASE WHEN Advices.Score >= 80 THEN 1 ELSE 0 END) * 100 / COUNT(Advices.StudentID) AS Successrate,
		SUM(CASE WHEN Advices.Score < 80 THEN 1 ELSE 0 END)  * 100 / COUNT(Advices.StudentID) AS Failurerate
FROM additionalpractices LEFT JOIN Advices ON additionalpractices.ExtraID = Advices.ExtraID
WHERE Advices.Score <= 80 
GROUP BY additionalpractices.CourseID
ORDER BY additionalpractices.CourseID ASC;


# What is the number of students in need of practice based on their year of birth and their gender.
SELECT Students.`Year of Birth`, Students.Sex, COUNT(Takes.StudentID) AS Students_in_need_of_practices
FROM Students
LEFT JOIN Takes ON Students.StudentID = Takes.StudentID
LEFT JOIN Quizzes ON Takes.QuizID = Quizzes.QuizID
WHERE Score <= 80 
GROUP BY Students.`Year of Birth`, Students.Sex
ORDER BY Students.`Year of Birth` ASC;

# Which professors have the most success?
SELECT Professors.ProfessorID , Professors.`First Name`, Professors.`Last Name`, Professors.DepartmentID, 
    SUM(CASE WHEN Takes.Score >= 80 THEN 1 ELSE 0 END) * 100 / COUNT(Takes.StudentID) AS Successrate
FROM Professors
LEFT JOIN Courses ON  Professors.ProfessorID = Courses.ProfessorID
LEFT JOIN Quizzes ON  Courses.CourseID = Quizzes.CourseID
LEFT JOIN Takes ON  Quizzes.QuizID = Takes.QuizID
GROUP BY Professors.`First Name`, Professors.`Last Name`, Professors.DepartmentID, Professors.ProfessorID
ORDER BY Successrate DESC;

# What is the average score based on the subject for additional practices?
SELECT additionalpractices.`Subject Name`, avg(Score) AS avgscore
FROM Advices
LEFT JOIN additionalpractices ON Advices.ExtraID = additionalpractices.ExtraID
GROUP BY additionalpractices.`Subject Name`
ORDER BY avgscore DESC;

# What is the average score based on the subject for quizzes scores?
SELECT Quizzes.`Subject Name`, avg(Takes.Score) AS avgscore
FROM Quizzes
LEFT JOIN Takes ON Quizzes.QuizID = Takes.QuizID
GROUP BY Quizzes.`Subject Name`
ORDER BY avgscore DESC;

# Compare the average score between the quizzes and the additional practices per course
SELECT AVG(Takes.Score) AS avg_score, Quizzes.CourseID
FROM Takes 
RIGHT JOIN Quizzes ON Quizzes.QuizID = Takes.QuizID
GROUP BY Quizzes.CourseID
ORDER BY avg_score ASC;
# OR
SELECT AVG(Advices.Score) AS avg_score, additionalpractices.CourseID
FROM Advices 
LEFT JOIN additionalpractices ON Advices.ExtraID = additionalpractices.ExtraID
GROUP BY additionalpractices.CourseID
ORDER BY avg_score ASC;

# Let's calculate their average final grades including weight without extra practices per courses 
WITH
score_weight as (SELECT Takes.StudentID, 
						Takes.Score, 
                        Quizzes.CourseID, 
                        Quizzes.QuizID, 
                        Quizzes.Weight,
                        Quizzes.Weight * Takes.Score AS finalquizscoreweight
				FROM Takes 
                LEFT JOIN Quizzes ON Takes.QuizID = Quizzes.QuizID),
final_grade as (SELECT score_weight.StudentID, score_weight.CourseID, SUM(score_weight.finalquizscoreweight) AS finals_quizzes_grades
				FROM score_weight
                GROUP BY score_weight.CourseID, score_weight.StudentID)
SELECT final_grade.CourseID, AVG(final_grade.finals_quizzes_grades) AS avg_grade
FROM final_grade
GROUP BY final_grade.CourseID
ORDER BY final_grade.CourseID ASC;





