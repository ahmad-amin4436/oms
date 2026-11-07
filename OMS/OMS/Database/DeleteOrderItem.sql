/*
  OMS - delete an item from a placed order.
  1. Adds the "Delete Item" operation under Order Detail (Roles & Rights picks it up from the catalog).
  2. Adds sp_DeleteOrderItem: removes one line, re-prices the order and writes the audit log row, atomically.
  Additive and re-runnable. Run AFTER PermissionsAndAudit.sql and the order workflow scripts.
  Admin is granted the new operation; every other role gets it only when ticked on the Roles page.
*/
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.PermissionActions WHERE ActionKey = N'DeleteItem')
  INSERT INTO dbo.PermissionActions (ActionKey, ActionName) VALUES (N'DeleteItem', N'Delete Item');

INSERT INTO dbo.ModuleActions (ModuleID, ActionID, IsActive)
SELECT m.ModuleID, p.ActionID, 1
FROM dbo.Modules m
INNER JOIN dbo.PermissionActions p ON p.ActionKey = N'DeleteItem'
WHERE m.ModuleKey = N'OrderDetail'
  AND NOT EXISTS (SELECT 1 FROM dbo.ModuleActions x WHERE x.ModuleID = m.ModuleID AND x.ActionID = p.ActionID);

INSERT INTO dbo.RolePermissions (RoleID, ModuleActionID, IsAllowed)
SELECT r.RoleID, ma.ModuleActionID, 1
FROM dbo.Roles r
INNER JOIN dbo.Modules m ON m.ModuleKey = N'OrderDetail'
INNER JOIN dbo.PermissionActions p ON p.ActionKey = N'DeleteItem'
INNER JOIN dbo.ModuleActions ma ON ma.ModuleID = m.ModuleID AND ma.ActionID = p.ActionID AND ma.IsActive = 1
WHERE r.RoleName = N'Admin'
  AND NOT EXISTS (SELECT 1 FROM dbo.RolePermissions rp WHERE rp.RoleID = r.RoleID AND rp.ModuleActionID = ma.ModuleActionID);
GO

-- Same rules as sp_AddOrderItem: only a Pending (unpaid) order whose business day is open can change.
-- The last remaining item cannot be removed (cancel the order instead).
CREATE OR ALTER PROCEDURE dbo.sp_DeleteOrderItem
  @OrderID     INT,
  @OrderItemID INT,
  @DeletedBy   INT = NULL,
  @IPAddress   NVARCHAR(50) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  BEGIN TRANSACTION;

  DECLARE @Status NVARCHAR(20), @Sub DECIMAL(10,2), @Disc DECIMAL(10,2), @Tax DECIMAL(10,2),
          @Rate DECIMAL(9,4), @DayClosed BIT, @OrderNumber NVARCHAR(50), @OldTotal DECIMAL(10,2);

  SELECT @Status = o.Status, @Sub = o.SubTotal, @Disc = o.DiscountAmount, @Tax = o.TaxAmount,
         @Rate = o.TaxPercent, @OldTotal = o.TotalAmount, @OrderNumber = o.OrderNumber,
         @DayClosed = CASE WHEN bd.ClosedAt IS NOT NULL THEN 1 ELSE 0 END
  FROM dbo.Orders o WITH (UPDLOCK, HOLDLOCK)
  LEFT JOIN dbo.BusinessDays bd ON bd.BusinessDayID = o.BusinessDayID
  WHERE o.OrderID = @OrderID;

  IF @Status IS NULL
    THROW 50001, 'Order not found.', 1;
  IF @Status <> 'Pending' OR @DayClosed = 1
    THROW 50013, 'Items can only be deleted while the order is Pending (unpaid).', 1;

  DECLARE @ItemName NVARCHAR(120), @Qty INT, @Price DECIMAL(10,2), @Line DECIMAL(10,2);
  SELECT @ItemName = mi.Name, @Qty = oi.Quantity, @Price = oi.UnitPrice, @Line = oi.LineTotal
  FROM dbo.OrderItems oi
  INNER JOIN dbo.MenuItems mi ON mi.ItemID = oi.ItemID
  WHERE oi.OrderItemID = @OrderItemID AND oi.OrderID = @OrderID;

  IF @ItemName IS NULL
    THROW 50014, 'That item is not on this order (it may already have been deleted).', 1;
  IF (SELECT COUNT(*) FROM dbo.OrderItems WHERE OrderID = @OrderID) <= 1
    THROW 50015, 'An order must keep at least one item. Cancel the order instead.', 1;

  DELETE FROM dbo.OrderItemToppings WHERE OrderItemID = @OrderItemID;
  DELETE FROM dbo.KitchenPrintQueue WHERE OrderItemID = @OrderItemID AND QueueStatus <> 'Printed';  -- don't print a deleted dish
  DELETE FROM dbo.OrderItems WHERE OrderItemID = @OrderItemID AND OrderID = @OrderID;

  IF @Rate IS NULL
    SET @Rate = CASE WHEN @Sub - @Disc > 0 THEN ROUND(@Tax * 100.0 / (@Sub - @Disc), 2)
                     ELSE ISNULL(TRY_CONVERT(DECIMAL(9,4),
                                (SELECT SettingValue FROM dbo.AppSettings WHERE SettingKey = 'TaxPercent')), 16) END;

  DECLARE @NewSub  DECIMAL(10,2) = ISNULL((SELECT SUM(LineTotal) FROM dbo.OrderItems WHERE OrderID = @OrderID), 0);
  DECLARE @NewDisc DECIMAL(10,2) = CASE WHEN @Sub > 0 THEN ROUND(@NewSub * @Disc / @Sub, 2) ELSE 0 END;
  DECLARE @NewTax  DECIMAL(10,2) = ROUND((@NewSub - @NewDisc) * @Rate / 100.0, 2);
  DECLARE @NewTotal DECIMAL(10,2) = @NewSub - @NewDisc + @NewTax;

  UPDATE dbo.Orders
  SET SubTotal = @NewSub, DiscountAmount = @NewDisc, TaxAmount = @NewTax,
      TotalAmount = @NewTotal, UpdatedAt = SYSUTCDATETIME()
  WHERE OrderID = @OrderID;

  DECLARE @Desc NVARCHAR(500) = LEFT(CONCAT('Order ', @OrderNumber, ': deleted ', @Qty, ' x ', @ItemName,
                                            ' @ ', @Price, ' (line ', @Line, '). Total ', @OldTotal, ' -> ', @NewTotal), 500);
  DECLARE @Prev NVARCHAR(MAX) = CONCAT(@Qty, ' x ', @ItemName, ' @ ', @Price, ' = ', @Line);

  EXEC dbo.sp_LogActivity
       @UserID = @DeletedBy, @Action = 'DeleteOrderItem', @Description = @Desc, @IPAddress = @IPAddress,
       @Module = 'Orders', @OrderID = @OrderID, @EntityType = 'OrderItem', @EntityID = @OrderItemID,
       @FieldName = 'Item', @PreviousValue = @Prev, @NewValue = 'Deleted';

  COMMIT TRANSACTION;
END
GO
PRINT 'Delete Item permission and sp_DeleteOrderItem applied.';
GO
