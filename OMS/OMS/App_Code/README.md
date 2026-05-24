This project is an ASP.NET Web Application project, not a Web Site project.

ASP.NET dynamically compiles physical `.cs` files under `App_Code` at runtime. Web
Application projects also compile code-behind into the application assembly, so
placing shared `.cs` code here creates duplicate type conflicts during
precompilation.

For that reason, RMS shared code lives in the separate `OMS.Common` class library
project (referenced by the web project) under these namespaces:

- `OMS.Common.DAL`
- `OMS.Common.BLL`
- `OMS.Common.Models`
- `OMS.Common.Helpers`
