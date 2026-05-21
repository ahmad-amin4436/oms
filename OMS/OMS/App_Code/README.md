This project is an ASP.NET Web Application project, not a Web Site project.

ASP.NET dynamically compiles physical `.cs` files under `App_Code` at runtime. Web
Application projects also compile code-behind into the application assembly, so
placing shared `.cs` code here creates duplicate type conflicts during
precompilation.

For that reason, RMS shared code is compiled from `/RMSCode` while preserving the
same logical namespaces:

- `OMS.App_Code.DAL`
- `OMS.App_Code.BLL`
- `OMS.App_Code.Models`
- `OMS.App_Code.Helpers`

