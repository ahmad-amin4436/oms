/*
  OMS - initial departments and the category -> department mapping.
  Idempotent. Run AFTER Departments.sql. Matches categories by name, so it also works on a database whose
  category ids differ. Only categories that have no department yet are linked, so later manual
  changes made in the application are never overwritten.
*/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @dept TABLE (Name NVARCHAR(80), DisplayOrder INT, Description NVARCHAR(250));
INSERT INTO @dept VALUES
  (N'Main Kitchen', 1, N'Pizza, starters, soups, broast, burgers, sandwiches, wraps, sauces and extras'),
  (N'Juice Bar',    2, N'Shakes, chillers, ice cream and cold drinks'),
  (N'Bar BQ',       3, N'BBQ and grill');

INSERT INTO dbo.Departments (Name, Description, DisplayOrder, IsActive)
SELECT d.Name, d.Description, d.DisplayOrder, 1
FROM @dept d
WHERE NOT EXISTS (SELECT 1 FROM dbo.Departments x WHERE x.Name = d.Name);

DECLARE @map TABLE (CategoryName NVARCHAR(80), DepartmentName NVARCHAR(80));
INSERT INTO @map VALUES
  (N'BBQ',                       N'Bar BQ'),
  (N'Shakes',                    N'Juice Bar'),
  (N'Chillers',                  N'Juice Bar'),
  (N'Ice Cream',                 N'Juice Bar'),
  (N'Cold Drinks',               N'Juice Bar'),
  (N'Pizza - Classic Flavours',  N'Main Kitchen'),
  (N'Pizza - Special Flavors',   N'Main Kitchen'),
  (N'Pizza - Signature Flavours',N'Main Kitchen'),
  (N'Starters',                  N'Main Kitchen'),
  (N'Soups',                     N'Main Kitchen'),
  (N'Broast',                    N'Main Kitchen'),
  (N'Broast Deals',              N'Main Kitchen'),
  (N'Burgers',                   N'Main Kitchen'),
  (N'Sandwiches',                N'Main Kitchen'),
  (N'Wraps',                     N'Main Kitchen'),
  (N'Wrap / Roll',               N'Main Kitchen'),
  (N'Sauces',                    N'Main Kitchen'),
  (N'Extras',                    N'Main Kitchen'),
  (N'Chines',                    N'Main Kitchen');

UPDATE c
SET c.DepartmentID = d.DepartmentID
FROM dbo.Categories c
JOIN @map m         ON m.CategoryName = c.Name
JOIN dbo.Departments d ON d.Name = m.DepartmentName
WHERE c.DepartmentID IS NULL;

-- Anything not named above (a category added by hand earlier) goes to the Main Kitchen rather than "Unassigned".
UPDATE c
SET c.DepartmentID = (SELECT DepartmentID FROM dbo.Departments WHERE Name = N'Main Kitchen')
FROM dbo.Categories c
WHERE c.DepartmentID IS NULL;

SELECT d.Name AS Department, Categories = COUNT(DISTINCT c.CategoryID), Dishes = COUNT(mi.ItemID)
FROM dbo.Departments d
LEFT JOIN dbo.Categories c ON c.DepartmentID = d.DepartmentID
LEFT JOIN dbo.MenuItems mi ON mi.CategoryID = c.CategoryID
GROUP BY d.Name, d.DisplayOrder ORDER BY d.DisplayOrder;
GO
