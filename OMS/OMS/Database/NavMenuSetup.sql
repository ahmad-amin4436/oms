/*
  OMS - Restaurant Management System
  Navigation Menu Schema + Seed Data
  Run AFTER DatabaseSetup.sql
*/

SET NOCOUNT ON;
GO

-- ============================================================
-- TABLES
-- ============================================================

IF OBJECT_ID('dbo.NavGroupRoles', 'U') IS NOT NULL DROP TABLE dbo.NavGroupRoles;
IF OBJECT_ID('dbo.NavItems',      'U') IS NOT NULL DROP TABLE dbo.NavItems;
IF OBJECT_ID('dbo.NavGroups',     'U') IS NOT NULL DROP TABLE dbo.NavGroups;
IF OBJECT_ID('dbo.NavSections',   'U') IS NOT NULL DROP TABLE dbo.NavSections;
GO

CREATE TABLE dbo.NavSections (
    SectionID   INT           IDENTITY(1,1) PRIMARY KEY,
    SectionName NVARCHAR(100) NOT NULL,
    SortOrder   INT           NOT NULL DEFAULT 0,
    IsActive    BIT           NOT NULL DEFAULT 1
);
GO

CREATE TABLE dbo.NavGroups (
    GroupID    INT           IDENTITY(1,1) PRIMARY KEY,
    SectionID  INT           NULL,               -- NULL = top-level (no section label)
    GroupName  NVARCHAR(100) NOT NULL,
    IconClass  NVARCHAR(100) NOT NULL DEFAULT 'fas fa-circle',
    Url        NVARCHAR(500) NULL,               -- non-NULL = direct link (no children)
    CollapseId NVARCHAR(100) NULL,               -- non-NULL = collapsible group with items
    SortOrder  INT           NOT NULL DEFAULT 0,
    IsActive   BIT           NOT NULL DEFAULT 1,
    CONSTRAINT FK_NavGroups_Sections FOREIGN KEY (SectionID) REFERENCES dbo.NavSections(SectionID)
);
GO

CREATE TABLE dbo.NavItems (
    ItemID     INT           IDENTITY(1,1) PRIMARY KEY,
    GroupID    INT           NOT NULL,
    ItemName   NVARCHAR(100) NOT NULL,
    Url        NVARCHAR(500) NOT NULL,
    SortOrder  INT           NOT NULL DEFAULT 0,
    IsActive   BIT           NOT NULL DEFAULT 1,
    BadgeText  NVARCHAR(50)  NULL,
    BadgeClass NVARCHAR(100) NULL,
    CONSTRAINT FK_NavItems_Groups FOREIGN KEY (GroupID) REFERENCES dbo.NavGroups(GroupID)
);
GO

-- Role-based access: RoleName = 'All' means every authenticated user
CREATE TABLE dbo.NavGroupRoles (
    ID       INT           IDENTITY(1,1) PRIMARY KEY,
    GroupID  INT           NOT NULL,
    RoleName NVARCHAR(50)  NOT NULL,
    CONSTRAINT FK_NavGroupRoles_Groups FOREIGN KEY (GroupID) REFERENCES dbo.NavGroups(GroupID),
    CONSTRAINT UQ_NavGroupRoles UNIQUE (GroupID, RoleName)
);
GO

-- ============================================================
-- STORED PROCEDURE
-- ============================================================

IF OBJECT_ID('dbo.sp_GetNavMenuByRole', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_GetNavMenuByRole;
GO

CREATE PROCEDURE dbo.sp_GetNavMenuByRole
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Sections that have at least one visible group for this role
    SELECT DISTINCT s.SectionID, s.SectionName, s.SortOrder
    FROM   dbo.NavSections s
    INNER JOIN dbo.NavGroups     g   ON g.SectionID = s.SectionID AND g.IsActive = 1
    INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID  = g.GroupID
    WHERE  s.IsActive = 1
      AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
    ORDER BY s.SortOrder;

    -- Result Set 2: Distinct groups visible to this role, in display order
    SELECT DISTINCT
           g.GroupID, g.SectionID, g.GroupName, g.IconClass,
           g.Url, g.CollapseId, g.SortOrder
    FROM   dbo.NavGroups     g
    INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID = g.GroupID
    WHERE  g.IsActive = 1
      AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
    ORDER BY g.SortOrder;

    -- Result Set 3: Distinct items for groups visible to this role
    SELECT DISTINCT
           i.ItemID, i.GroupID, i.ItemName, i.Url,
           i.SortOrder, i.BadgeText, i.BadgeClass
    FROM   dbo.NavItems      i
    INNER JOIN dbo.NavGroups     g   ON g.GroupID   = i.GroupID  AND g.IsActive = 1
    INNER JOIN dbo.NavGroupRoles ngr ON ngr.GroupID  = g.GroupID
    WHERE  i.IsActive = 1
      AND (ngr.RoleName = @RoleName OR ngr.RoleName = 'All')
    ORDER BY i.GroupID, i.SortOrder;
END;
GO

-- ============================================================
-- SEED DATA
-- Nav order mirrors the intended OMS sidebar layout:
--   1. Dashboard           (top-level, no section label)
--   2. Restaurant section  Orders | Menu Mgmt | Offers | Analytics
--   3. Administration      Admin Panel
--   4. Reports             Print Invoice
-- ============================================================

DECLARE @secRestaurant INT, @secAdmin INT, @secReports INT;

INSERT INTO dbo.NavSections (SectionName, SortOrder) VALUES ('Restaurant',     10); SET @secRestaurant = SCOPE_IDENTITY();
INSERT INTO dbo.NavSections (SectionName, SortOrder) VALUES ('Administration', 20); SET @secAdmin      = SCOPE_IDENTITY();
INSERT INTO dbo.NavSections (SectionName, SortOrder) VALUES ('Reports',        30); SET @secReports    = SCOPE_IDENTITY();

-- ----------------------------------------------------------------
-- Groups
-- SortOrder controls vertical display order across all sections.
-- SectionID = NULL  → top-level (rendered without a section divider)
-- Url = non-NULL    → direct link (no children, no CollapseId)
-- CollapseId = non-NULL → collapsible group (children in NavItems)
-- ----------------------------------------------------------------

DECLARE @grpDashboard INT,
        @grpOrders    INT, @grpMenu     INT,
        @grpOffers    INT, @grpAnalytics INT,
        @grpAdmin     INT,
        @grpReports   INT;

-- Top-level: Dashboard (direct link — no sub-items)
INSERT INTO dbo.NavGroups (SectionID, GroupName,    IconClass, Url,              CollapseId, SortOrder)
     VALUES               (NULL,      'Dashboard',  '',        '~/Default.aspx', NULL,        1);
SET @grpDashboard = SCOPE_IDENTITY();

-- Restaurant section
INSERT INTO dbo.NavGroups (SectionID,       GroupName,          IconClass, Url,   CollapseId,   SortOrder)
     VALUES               (@secRestaurant,  'Orders',           '',        NULL,  'grpOrders',  11);
SET @grpOrders = SCOPE_IDENTITY();

INSERT INTO dbo.NavGroups (SectionID,       GroupName,          IconClass, Url,   CollapseId,  SortOrder)
     VALUES               (@secRestaurant,  'Menu Management',  '',        NULL,  'grpMenu',   12);
SET @grpMenu = SCOPE_IDENTITY();

INSERT INTO dbo.NavGroups (SectionID,       GroupName, IconClass, Url,   CollapseId,   SortOrder)
     VALUES               (@secRestaurant,  'Deals',   '',        NULL,  'grpOffers',  13);
SET @grpOffers = SCOPE_IDENTITY();

INSERT INTO dbo.NavGroups (SectionID,       GroupName,    IconClass, Url,                           CollapseId, SortOrder)
     VALUES               (@secRestaurant,  'Analytics',  '',        '~/Analytics/Analytics.aspx',  NULL,        14);
SET @grpAnalytics = SCOPE_IDENTITY();

-- Administration section
INSERT INTO dbo.NavGroups (SectionID,  GroupName,     IconClass, Url,   CollapseId,  SortOrder)
     VALUES               (@secAdmin,  'Admin Panel', '',        NULL,  'grpAdmin',  21);
SET @grpAdmin = SCOPE_IDENTITY();

-- Reports section (direct link)
INSERT INTO dbo.NavGroups (SectionID,   GroupName,       IconClass, Url,                           CollapseId, SortOrder)
     VALUES               (@secReports, 'Print Invoice', '',        '~/Reports/PrintInvoice.aspx',  NULL,       31);
SET @grpReports = SCOPE_IDENTITY();

-- ----------------------------------------------------------------
-- Items  (only for collapsible groups)
-- ----------------------------------------------------------------

INSERT INTO dbo.NavItems (GroupID,      ItemName,          Url,                             SortOrder) VALUES
    -- Orders
    (@grpOrders,  'New Order',          '~/Orders/NewOrder.aspx',         1),
    (@grpOrders,  'Order List',         '~/Orders/OrderList.aspx',        2),
    (@grpOrders,  'Order Detail',       '~/Orders/OrderDetail.aspx',      3),
    -- Menu Management
    (@grpMenu,    'Menu Items',         '~/Menu/MenuItems.aspx',          1),
    (@grpMenu,    'Menu Page',          '~/Menu/MenuPage.aspx',           2),
    (@grpMenu,    'Pricing',            '~/Menu/Pricing.aspx',            3),
    -- Deals
    (@grpOffers,  'Create Deals',       '~/Deals/CreateDeals.aspx',       1),
    (@grpOffers,  'Deals List',         '~/Deals/DealsList.aspx',         2),
    -- Admin Panel
    (@grpAdmin,   'Admin Dashboard',    '~/Admin/AdminDashboard.aspx',    1),
    (@grpAdmin,   'Users',              '~/Admin/Users.aspx',             2),
    (@grpAdmin,   'Roles & Rights',     '~/Admin/Roles.aspx',             3),
    (@grpAdmin,   'Messages',           '~/Admin/Messages.aspx',          4);

-- ----------------------------------------------------------------
-- Role-based access
--   'All'     = every authenticated user
--   'Admin'   = Administrator
--   'Manager' = Restaurant manager
--   'Cashier' = Front desk / cashier
--   'Waiter'  = Server / waiter
--   'Kitchen' = Kitchen staff
-- ----------------------------------------------------------------

INSERT INTO dbo.NavGroupRoles (GroupID,        RoleName) VALUES
    -- Dashboard: everyone
    (@grpDashboard, 'All'),

    -- Orders: operational staff
    (@grpOrders,    'Admin'),
    (@grpOrders,    'Manager'),
    (@grpOrders,    'Cashier'),
    (@grpOrders,    'Waiter'),

    -- Menu Management: management only
    (@grpMenu,      'Admin'),
    (@grpMenu,      'Manager'),

    -- Offers & Coupons: management only
    (@grpOffers,    'Admin'),
    (@grpOffers,    'Manager'),

    -- Analytics: management only
    (@grpAnalytics, 'Admin'),
    (@grpAnalytics, 'Manager'),

    -- Admin Panel: admin only
    (@grpAdmin,     'Admin'),

    -- Print Invoice: admin, manager, cashier
    (@grpReports,   'Admin'),
    (@grpReports,   'Manager'),
    (@grpReports,   'Cashier');

PRINT 'NavMenu schema and seed data created successfully.';
PRINT 'Nav order: Dashboard | Restaurant (Orders, Menu Mgmt, Offers, Analytics) | Administration (Admin Panel) | Reports (Print Invoice)';
GO
