# Restaurant Management System (RMS)

ASP.NET WebForms restaurant management system scaffold integrated with the Falcon Bootstrap Admin Template.

## Setup

1. Create a SQL Server database named `RMS`.
2. Run `Database/DatabaseSetup.sql` against that database.
3. Update `Web.config` if your SQL Server is not local:

   ```xml
   <add name="RMSConnection" connectionString="Data Source=.;Initial Catalog=RMS;Integrated Security=True;MultipleActiveResultSets=True" providerName="System.Data.SqlClient" />
   ```

4. Build the project in Visual Studio or with MSBuild.
5. Open `Login.aspx`.

Default login:

- Email: `admin@rms.com`
- Password: `Admin@123`

## Implemented Foundation

- Falcon template integration in `Site.Master`
- Logo-based RMS theme overrides in `assets/css/user.min.css` and `assets/css/user-rtl.min.css`
- RMS custom overrides in `Assets/css/rms-custom.css`
- Forms Authentication configuration
- Role-based folder protection for Admin and Reports
- SQL Server schema, seed data, indexes, and stored procedures
- Stored-procedure-only `DBHelper`
- Authentication service with SHA256 password verification and lockout support
- Activity/error logging helpers
- Upload image validation helper
- Login/logout pages
- Dashboard page with WebForms `UpdatePanel` + `Timer`
- Orders list, new order scaffold, order detail, and print invoice scaffold
- Menu item list, public menu, and pricing matrix scaffold
- Offers, coupons, admin, messages, analytics, and error page scaffolds

## Project Note

This is a Web Application project. Physical `.cs` files under `App_Code` are dynamically compiled by ASP.NET and conflict with Web Application precompilation when also compiled into the project assembly. Shared RMS code is therefore compiled from `RMSCode` while keeping the logical namespaces requested by the spec:

- `OMS.App_Code.DAL`
- `OMS.App_Code.BLL`
- `OMS.App_Code.Models`
- `OMS.App_Code.Helpers`

`App_Code/README.md` documents this decision.

## Verification

These checks passed during implementation:

```powershell
MSBuild OMS.csproj /p:Configuration=Debug /p:Platform=AnyCPU
aspnet_compiler -v /OMS -p . PrecompiledRMS2
```

## Next Implementation Passes

- Complete full CRUD modals for Users, Menu Items, Categories, Toppings, Offers, and Coupons
- Complete New Order wizard cart state, size/topping modal, coupon validation, and item inserts
- Add Chart.js bindings to Dashboard and Analytics
- Add Crystal Reports `.rpt` invoice option
- Add CSV/Excel/PDF exports
- Add SMTP reply support for Messages
