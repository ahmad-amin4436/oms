-- Hide the Messages item from the Admin Panel menu (soft: set IsActive = 1 to restore it).
UPDATE dbo.NavItems SET IsActive = 0 WHERE Url = '~/Admin/Messages.aspx';
PRINT 'Messages menu item hidden.';
