/*
  OMS - Menu update (printed menu: Pizzas, Starters, Broast, Burgers, Sandwiches,
  Wraps, BBQ, Bar). Idempotent: safe to re-run; re-running re-applies the prices
  below (it overwrites price edits made in Menu Items for these item names).

  - The order screen has no size selector, so every size is its own item
    ("Chicken Tikka Pizza - Medium" / "- Large").
  - Old placeholder items are DELETED when nothing references them, otherwise
    only marked unavailable (order history and deals keep working).
  - sp_GetMenuItems now sorts by ItemID inside a category (= printed menu
    order) instead of alphabetically, so Medium comes before Large.
*/
SET NOCOUNT ON;
GO

-- ------------------------------------------------------------
--  Source data
-- ------------------------------------------------------------
IF OBJECT_ID('tempdb..#Cat') IS NOT NULL DROP TABLE #Cat;
CREATE TABLE #Cat (Ord INT PRIMARY KEY, Name NVARCHAR(80) NOT NULL);
INSERT INTO #Cat (Ord, Name) VALUES
 (1,  'Pizza - Classic Flavours'),
 (2,  'Pizza - Signature Flavours'),
 (3,  'Starters'),
 (4,  'Soups'),
 (5,  'Broast'),
 (6,  'Broast Deals'),
 (7,  'Burgers'),
 (8,  'Sandwiches'),
 (9,  'Wraps'),
 (10, 'BBQ'),
 (11, 'Sauces'),
 (12, 'Shakes'),
 (13, 'Chillers'),
 (14, 'Ice Cream'),
 (15, 'Cold Drinks'),
 (16, 'Extras');

-- One row per printed item. P2/S1/S2 are set only for two-size items; those
-- become "<Name> - <S1>" at P1 and "<Name> - <S2>" at P2.
IF OBJECT_ID('tempdb..#Raw') IS NOT NULL DROP TABLE #Raw;
CREATE TABLE #Raw (K INT IDENTITY(1,1), CatOrd INT NOT NULL, Name NVARCHAR(120) NOT NULL,
                   Descr NVARCHAR(500) NULL, P1 DECIMAL(10,2) NOT NULL,
                   P2 DECIMAL(10,2) NULL, S1 NVARCHAR(20) NULL, S2 NVARCHAR(20) NULL);

INSERT INTO #Raw (CatOrd, Name, Descr, P1, P2, S1, S2) VALUES
 -- Pizza - Classic Flavours
 (1, 'Chicken Tikka Pizza',  'Regular pizza sauce, tikka-spiced chicken, bell pepper, tomato, onion, vinaigrette green chili, black olives.', 1250, 1800, 'Medium', 'Large'),
 (1, 'Pepperoni Pizza',      'Regular pizza sauce, beef pepperoni, 100% mozzarella cheese.', 1250, 1800, 'Medium', 'Large'),
 (1, 'Chicken Fajita Pizza', 'Regular pizza sauce, fajita-spiced chicken, onion slices, tomato slices, bell pepper slices, button mushrooms.', 1250, 1800, 'Medium', 'Large'),
 (1, 'Cheese Lover Pizza',   'Tomato pizza sauce, cheddar cheese (30%), mozzarella cheese (70%), topped with a sprinkle of oregano.', 1250, 1800, 'Medium', 'Large'),
 -- Pizza - Signature Flavours
 (2, 'Small Pizza',              'Chicken, black olive, mushroom, satay veg, cheese.', 750, NULL, NULL, NULL),
 (2, 'KAF Special Pizza',        'Special chicken, cheese, capsicum, onion, tomato, black olives, and chicken sausages - topped with our special sauce.', 1400, 2600, 'Medium', 'Large'),
 (2, 'KAF Special Kenzon Pizza', NULL, 1450, 2800, 'Medium', 'Large'),
 (2, 'Malai Boti Pizza',         'Onion, olive, top with malai sauce.', 1400, 2600, 'Medium', 'Large'),
 (2, 'Kabab Behari Pizza',       'Special pizza sauce, marinated fajita chicken, tomato, bell pepper, onion, mushrooms, French creamy sauce, cheese sausage.', 1400, 2600, 'Medium', 'Large'),
 (2, 'Ranch Pizza',              'Ranch white sauce, marinated and baked chicken, jalapenos, tomato slices, black olives, topped with ranch sauce.', 1400, 2600, 'Medium', 'Large'),
 (2, 'Crown Crust Pizza',        'Regular pizza base, Italian herb creamy sauce, marinated baked chicken, onion, tomato, jalapenos.', 1400, 2600, 'Medium', 'Large'),
 (2, 'Kebab Stuffed Pizza',      'Special chicken, cheese, onion, tomato, black olives, and capsicum - topped with our special signature sauce.', 1400, 2600, 'Medium', 'Large'),
 -- Starters
 (3, 'Kebab Bite',                   NULL, 799,  NULL, NULL, NULL),
 (3, 'Finger Fish (8 pcs)',          NULL, 1499, NULL, NULL, NULL),
 (3, 'Plain Fries',                  NULL, 450,  NULL, NULL, NULL),
 (3, 'Loaded Fries',                 NULL, 700,  NULL, NULL, NULL),
 (3, 'Honey Wings (8 pcs)',          NULL, 800,  NULL, NULL, NULL),
 (3, 'Hot Wings (8 pcs)',            NULL, 800,  NULL, NULL, NULL),
 (3, 'B.B.Q Wings (8 pcs)',          NULL, 800,  NULL, NULL, NULL),
 (3, 'Nuggets (12 pcs)',             NULL, 1000, NULL, NULL, NULL),
 (3, 'Dynamite Chicken',             'Marinated crispy fried chicken, hot shots (8 pieces), sesame seeds, special aromatic sauce, crispy hot shot toast with sauce.', 750, NULL, NULL, NULL),
 -- Soups
 (4, 'Hot & Sour Soup',   NULL, 450, 1299, 'Single', 'Family'),
 (4, 'Chicken Corn Soup', NULL, 450, 1299, 'Single', 'Family'),
 -- Broast
 (5, 'Quarter Broast', '2 pieces chicken + fries + 1 bun + garlic sauce.', 850,  NULL, NULL, NULL),
 (5, 'Half Broast',    '4 pieces chicken + 1 bun + 2 garlic sauces + fries.', 1450, NULL, NULL, NULL),
 (5, 'Full Broast',    '8 pieces chicken + fries + 2 buns + 4 garlic sauces.', 2800, NULL, NULL, NULL),
 -- Broast Deals
 (6, 'Maza Deal',   '4 pieces chicken, fries, 1 bun, garlic sauce, 1 can.', 1550, NULL, NULL, NULL),
 (6, 'Couple Deal', '8 pieces chicken, fries, 1 bun, 2 garlic sauces, 1.5L drink.', 2950, NULL, NULL, NULL),
 (6, 'Alpha Deal',  '16 pieces chicken, 4 fries, 4 buns, 4 garlic dips, 1.5L drink.', 5200, NULL, NULL, NULL),
 (6, 'Beta Deal',   '32 pieces chicken, 8 buns, 8 fries, 8 garlic dips, 1.5L drink.', 10000, NULL, NULL, NULL),
 -- Burgers
 (7, 'Fish Burger',          'Tartar sauce, iceberg, serving with fries.', 780, NULL, NULL, NULL),
 (7, 'Smash Beef Burger',    'Tomato, beef, iceberg, cheese slice with sauce.', 900, NULL, NULL, NULL),
 (7, 'Zinger Burger',        'Marinated chicken thigh, crispy skin fried, served with fries.', 550, NULL, NULL, NULL),
 (7, 'Chicken Grill Burger', 'Grill chicken, salad, tomatoes, iceberg, cucumber + burger sauce, with fries.', 750, NULL, NULL, NULL),
 (7, 'Chicken Fillet Burger','Plain mayo, iceberg, cheese slice, fillet chicken.', 480, NULL, NULL, NULL),
 -- Sandwiches
 (8, 'B.B.Q Sandwich',           'Grilled B.B.Q chicken, serving with fries.', 595, NULL, NULL, NULL),
 (8, 'Jalapeno Tikka Sandwich',  'Grilled tikka chicken, jalapeno, onion, serving with fries.', 650, NULL, NULL, NULL),
 (8, 'Grilled Sandwich',         'Grilled chicken, 3 pc bread, iceberg, chipotle sauce, serving with fries.', 650, NULL, NULL, NULL),
 (8, 'Special Club Sandwich',    '4 pieces of toasted bread, grilled chicken, a tomato slice, iceberg lettuce, a cheese slice, fried egg, special sandwich sauce, served with fries.', 750, NULL, NULL, NULL),
 -- Wraps
 (9, 'Crispy Jalapeno Wrap', 'Marinated crispy fried chicken, tortilla bread, garlic mayo sauce, tomato slice, jalapeno, onion, black olives, lettuce, French fries, sauce dip.', 695, NULL, NULL, NULL),
 (9, 'Chipotle Wrap',        'Crispy marinated fried chicken, garlic mayo sauce, special chipotle tortilla bread, French fries, gherkin pickles, black olives, cheese slices, served with fries.', 695, NULL, NULL, NULL),
 -- BBQ
 (10, 'Chicken Malai Boti (8 PC)',         NULL, 1999, NULL, NULL, NULL),
 (10, 'Chicken Special Green Boti (8 PC)', NULL, 1299, NULL, NULL, NULL),
 (10, 'Chicken Special Green Boti (12 PC)',NULL, 1899, NULL, NULL, NULL),
 (10, 'Hyderabadi Boti (4 PC)',            NULL, 925,  NULL, NULL, NULL),
 (10, 'Hyderabadi Boti (8 PC)',            NULL, 1850, NULL, NULL, NULL),
 (10, 'Reshmi Kabab (4 PC)',               NULL, 1799, NULL, NULL, NULL),
 (10, 'Rim Jhim Kabab (4 PC)',             NULL, 1699, NULL, NULL, NULL),
 (10, 'Chicken Tikka (8 PC)',              NULL, 1599, NULL, NULL, NULL),
 (10, 'Beef Kabab (4 PC)',                 NULL, 1499, NULL, NULL, NULL),
 (10, 'Leg Piece',                         NULL, 499,  NULL, NULL, NULL),
 (10, 'Chest Piece',                       NULL, 499,  NULL, NULL, NULL),
 -- Sauces (KAF special sauces + BBQ sauces)
 (11, 'Garlic Sauce',       NULL, 120, NULL, NULL, NULL),
 (11, 'Chipotle Sauce',     NULL, 120, NULL, NULL, NULL),
 (11, 'Special Sauce',      NULL, 120, NULL, NULL, NULL),
 (11, 'Mushroom Sauce',     NULL, 120, NULL, NULL, NULL),
 (11, 'Jalapeno Sauce',     NULL, 120, NULL, NULL, NULL),
 (11, 'Tartar Sauce',       NULL, 120, NULL, NULL, NULL),
 (11, 'BBQ Temper Sauce',   NULL, 120, NULL, NULL, NULL),
 (11, 'Spicy Green Sauce',  NULL, 120, NULL, NULL, NULL),
 -- Shakes
 (12, 'Oreo Shake',       NULL, 350, NULL, NULL, NULL),
 (12, 'Vanilla Shake',    NULL, 450, NULL, NULL, NULL),
 (12, 'Chocolate Shake',  NULL, 500, NULL, NULL, NULL),
 (12, 'Nutella Shake',    NULL, 650, NULL, NULL, NULL),
 (12, 'Strawberry Shake', NULL, 450, NULL, NULL, NULL),
 -- Chillers
 (13, 'Mint Margarita',        NULL, 350,  NULL, NULL, NULL),
 (13, 'Fresh Lime',            NULL, 300,  NULL, NULL, NULL),
 (13, 'Pina Colada',           NULL, 550,  NULL, NULL, NULL),
 (13, 'Blue Lagoon',           NULL, 600,  NULL, NULL, NULL),
 (13, 'Blue Lagoon + Sprite',  NULL, 350,  NULL, NULL, NULL),
 (13, 'Apple Berry',           NULL, 500,  NULL, NULL, NULL),
 (13, 'Pink Lady',             NULL, 400,  NULL, NULL, NULL),
 (13, 'Khan e Azam Special',   NULL, 500,  NULL, NULL, NULL),
 (13, 'Cold Coffee',           NULL, 1000, NULL, NULL, NULL),
 -- Ice Cream
 (14, 'Vanilla Ice Cream',        NULL, 250, 400, 'Regular', 'Large'),
 (14, 'Chocolate Chip Ice Cream', NULL, 250, 400, 'Regular', 'Large'),
 (14, 'Tutti-frutti Ice Cream',   NULL, 250, 400, 'Regular', 'Large'),
 (14, 'Pishtachio Ice Cream',     NULL, 250, 400, 'Regular', 'Large'),
 (14, 'Kulfi Ice Cream',          NULL, 250, 400, 'Regular', 'Large'),
 (14, 'Mango Ice Cream',          NULL, 250, 400, 'Regular', 'Large'),
 (14, 'Strawberry Ice Cream',     NULL, 250, 400, 'Regular', 'Large'),
 -- Cold Drinks
 (15, '1.5L Cold Drink',  NULL, 250, NULL, NULL, NULL),
 (15, 'Water Bottle',     NULL, 100, NULL, NULL, NULL),
 (15, 'Can (350ml)',      NULL, 160, NULL, NULL, NULL),
 -- Extras: extra pizza topping is priced by pizza size
 (16, 'Extra Pizza Topping', NULL, 150, 250, 'Medium Pizza', 'Large Pizza');

IF OBJECT_ID('tempdb..#Menu') IS NOT NULL DROP TABLE #Menu;
CREATE TABLE #Menu (Seq INT IDENTITY(1,1), CatOrd INT NOT NULL, Name NVARCHAR(120) NOT NULL,
                    Descr NVARCHAR(500) NULL, Price DECIMAL(10,2) NOT NULL);
INSERT INTO #Menu (CatOrd, Name, Descr, Price)
SELECT CatOrd, Name + ISNULL(' - ' + SizeName, ''), Descr, Price
FROM #Raw r
CROSS APPLY (VALUES (1, r.S1, r.P1), (2, r.S2, r.P2)) s (N, SizeName, Price)
WHERE s.N = 1 OR r.P2 IS NOT NULL
ORDER BY r.K, s.N;
GO

-- ------------------------------------------------------------
--  Apply
-- ------------------------------------------------------------
BEGIN TRANSACTION;

-- Legacy placeholder items (created before this menu existed) that no order, deal
-- or size price uses are removed first, so the new items get fresh IDs in printed
-- order. Legacy items that ARE referenced are kept (retired below).
DELETE FROM dbo.MenuItems
WHERE CreatedAt < '20261005'
  AND NOT EXISTS (SELECT 1 FROM dbo.OrderItems      x WHERE x.ItemID = MenuItems.ItemID)
  AND NOT EXISTS (SELECT 1 FROM dbo.DealItems       x WHERE x.ItemID = MenuItems.ItemID)
  AND NOT EXISTS (SELECT 1 FROM dbo.ItemSizePricing x WHERE x.ItemID = MenuItems.ItemID);

-- Categories: update by name, add missing, order as printed.
UPDATE c SET c.DisplayOrder = n.Ord, c.IsActive = 1
FROM dbo.Categories c INNER JOIN #Cat n ON n.Name = c.Name;

INSERT INTO dbo.Categories (Name, DisplayOrder, IsActive)
SELECT n.Name, n.Ord, 1 FROM #Cat n
WHERE NOT EXISTS (SELECT 1 FROM dbo.Categories c WHERE c.Name = n.Name);

-- Items: update by name, add missing (in menu order so ItemID follows the print).
UPDATE mi SET mi.CategoryID = c.CategoryID, mi.Description = m.Descr,
              mi.BasePrice = m.Price, mi.IsAvailable = 1
FROM dbo.MenuItems mi
INNER JOIN #Menu m ON m.Name = mi.Name
INNER JOIN #Cat n ON n.Ord = m.CatOrd
INNER JOIN dbo.Categories c ON c.Name = n.Name;

INSERT INTO dbo.MenuItems (CategoryID, Name, Description, BasePrice, IsAvailable)
SELECT c.CategoryID, m.Name, m.Descr, m.Price, 1
FROM #Menu m
INNER JOIN #Cat n ON n.Ord = m.CatOrd
INNER JOIN dbo.Categories c ON c.Name = n.Name
WHERE NOT EXISTS (SELECT 1 FROM dbo.MenuItems mi WHERE mi.Name = m.Name)
ORDER BY m.Seq;

-- Old items that are not on the printed menu: delete if unused, else retire.
SELECT mi.ItemID INTO #Old
FROM dbo.MenuItems mi WHERE NOT EXISTS (SELECT 1 FROM #Menu m WHERE m.Name = mi.Name);

DELETE FROM dbo.MenuItems
WHERE ItemID IN (SELECT ItemID FROM #Old)
  AND NOT EXISTS (SELECT 1 FROM dbo.OrderItems  x WHERE x.ItemID = MenuItems.ItemID)
  AND NOT EXISTS (SELECT 1 FROM dbo.DealItems   x WHERE x.ItemID = MenuItems.ItemID)
  AND NOT EXISTS (SELECT 1 FROM dbo.ItemSizePricing x WHERE x.ItemID = MenuItems.ItemID);

UPDATE dbo.MenuItems SET IsAvailable = 0
WHERE ItemID IN (SELECT ItemID FROM #Old);

-- Old categories: delete when empty, otherwise hide.
DELETE FROM dbo.Categories
WHERE Name NOT IN (SELECT Name FROM #Cat)
  AND NOT EXISTS (SELECT 1 FROM dbo.MenuItems mi WHERE mi.CategoryID = Categories.CategoryID);
UPDATE dbo.Categories SET IsActive = 0 WHERE Name NOT IN (SELECT Name FROM #Cat);

-- Old placeholder toppings are not on the menu (extra topping is an item now).
IF NOT EXISTS (SELECT 1 FROM dbo.OrderItemToppings)
  DELETE FROM dbo.Toppings;
ELSE
  UPDATE dbo.Toppings SET IsAvailable = 0;

COMMIT TRANSACTION;
GO

-- Menu order inside a category = ItemID order (the printed order).
CREATE OR ALTER PROCEDURE dbo.sp_GetMenuItems
  @CategoryID INT = NULL,
  @IsAvailable BIT = NULL
AS
BEGIN
  SELECT mi.*, c.Name AS CategoryName
  FROM dbo.MenuItems mi
  INNER JOIN dbo.Categories c ON mi.CategoryID = c.CategoryID
  WHERE (@CategoryID IS NULL OR mi.CategoryID = @CategoryID)
    AND (@IsAvailable IS NULL OR mi.IsAvailable = @IsAvailable)
  ORDER BY c.DisplayOrder, mi.ItemID;
END
GO

DECLARE @n INT = (SELECT COUNT(*) FROM #Menu);
PRINT CONCAT('Menu update applied: ', @n, ' items.');
GO
