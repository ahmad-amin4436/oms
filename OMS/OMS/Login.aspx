<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="OMS.Login" %>

<!DOCTYPE html>
<html data-bs-theme="light" lang="en-US" dir="ltr">
<head runat="server">
    <meta charset="utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Login - RMS</title>
    <link rel="icon" type="image/png" href="favicon.png" />
    <script src="assets/js/config.js"></script>
    <link href="vendors/simplebar/simplebar.min.css" rel="stylesheet" />
    <link href="assets/css/theme.min.css" rel="stylesheet" />
    <link href="assets/css/user.min.css" rel="stylesheet" />
    <link href="Assets/css/rms-custom.css" rel="stylesheet" />
</head>
<body>
    <form id="form1" runat="server">
        <main class="main" id="top">
            <div class="container">
                <div class="row flex-center min-vh-100 py-6">
                    <div class="col-sm-10 col-md-8 col-lg-5 col-xl-4 col-xxl-3">
                        <a class="d-flex flex-center mb-4" href="Login.aspx">
                            <img src="assets/img/icons/spot-illustrations/logo.png" alt="RMS" width="220" />
                        </a>
                        <div class="card">
                            <div class="card-body p-4 p-sm-5">
                                <h5 class="text-center">Restaurant Management System</h5>
                                <p class="text-center fs--1 text-600">Sign in to continue</p>
                                <asp:Panel ID="pnlAlert" runat="server" CssClass="alert alert-danger" Visible="false">
                                    <asp:Literal ID="litAlert" runat="server" />
                                </asp:Panel>
                                <div class="mb-3">
                                    <label class="form-label" for="<%= txtEmail.ClientID %>">Email address</label>
                                    <asp:TextBox ID="txtEmail" runat="server" CssClass="form-control" TextMode="Email" />
                                    <asp:RequiredFieldValidator runat="server" ControlToValidate="txtEmail" CssClass="text-danger fs--1" ErrorMessage="Email is required." Display="Dynamic" />
                                </div>
                                <div class="mb-3">
                                    <label class="form-label" for="<%= txtPassword.ClientID %>">Password</label>
                                    <asp:TextBox ID="txtPassword" runat="server" CssClass="form-control" TextMode="Password" />
                                    <asp:RequiredFieldValidator runat="server" ControlToValidate="txtPassword" CssClass="text-danger fs--1" ErrorMessage="Password is required." Display="Dynamic" />
                                </div>
                                <div class="row flex-between-center">
                                    <div class="col-auto">
                                        <div class="form-check mb-0">
                                            <asp:CheckBox ID="chkRememberMe" runat="server" CssClass="form-check-input" />
                                            <label class="form-check-label mb-0" for="<%= chkRememberMe.ClientID %>">Remember me</label>
                                        </div>
                                    </div>
                                </div>
                                <div class="mb-3 mt-3">
                                    <asp:Button ID="btnLogin" runat="server" CssClass="btn btn-primary d-block w-100" Text="Log in" OnClick="btnLogin_Click" />
                                </div>
                                <p class="mb-0 text-center fs--1 text-600">Default admin: admin@rms.com / Admin@123</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    </form>
    <script src="vendors/bootstrap/bootstrap.min.js"></script>
    <script src="vendors/fontawesome/all.min.js"></script>
    <script src="assets/js/theme.js"></script>
</body>
</html>
