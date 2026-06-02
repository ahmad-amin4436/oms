<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="OMS._Default" %>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
<div class="row g-3 mb-3">
            <div class="col-xxl-6 col-xl-12">
              <div class="row g-3">
                <div class="col-12">
                  <div class="card bg-transparent-50 overflow-hidden">
                    <div class="card-header position-relative">
                      <div class="bg-holder d-none d-md-block bg-card z-1" style="background-image:url(assets/img/illustrations/ecommerce-bg.png);background-size:230px;background-position:right bottom;z-index:-1;"></div>
                      <!--/.bg-holder-->
                      <div class="position-relative z-2">
                        <div>
                          <h3 class="text-primary mb-1"><asp:Literal ID="litGreeting" runat="server" Text="Welcome!" /></h3>
                          <p>Here's what's happening with your store today </p>
                        </div>
                        <div class="d-flex py-3">
                          <div class="pe-3">
                            <p class="text-600 fs--1 fw-medium">Today's orders </p>
                            <h4 class="text-800 mb-0"><asp:Literal ID="litTodayVisits" runat="server" Text="0" /></h4>
                          </div>
                          <div class="ps-3">
                            <p class="text-600 fs--1">Today's total sales </p>
                            <h4 class="text-800 mb-0"><asp:Literal ID="litTodaySales" runat="server" Text="Rs. 0" /></h4>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="card-body p-0">
                      <ul class="mb-0 list-unstyled">
                        <li class="alert mb-0 rounded-0 py-3 px-x1 alert-warning border-x-0 border-top-0">
                          <div class="row flex-between-center">
                            <div class="col">
                              <div class="d-flex">
                                <div class="fas fa-circle mt-1 fs--2"></div>
                                <p class="fs--1 ps-2 mb-0"><strong><asp:Literal ID="litUnread" runat="server" Text="0" /> messages</strong> are unread in your inbox</p>
                              </div>
                            </div>
                            <div class="col-auto d-flex align-items-center"><a class="alert-link fs--1 fw-medium" href="Admin/Messages.aspx">View messages<i class="fas fa-chevron-right ms-1 fs--2"></i></a></div>
                          </div>
                        </li>
                        <li class="alert mb-0 rounded-0 py-3 px-x1 greetings-item border-top border-x-0 border-top-0">
                          <div class="row flex-between-center">
                            <div class="col">
                              <div class="d-flex">
                                <div class="fas fa-circle mt-1 fs--2 text-primary"></div>
                                <p class="fs--1 ps-2 mb-0"><strong><asp:Literal ID="litMenuCount" runat="server" Text="0" /> menu items</strong> are currently available</p>
                              </div>
                            </div>
                            <div class="col-auto d-flex align-items-center"><a class="alert-link fs--1 fw-medium" href="Menu/MenuItems.aspx">View menu<i class="fas fa-chevron-right ms-1 fs--2"></i></a></div>
                          </div>
                        </li>
                        <li class="alert mb-0 rounded-0 py-3 px-x1 greetings-item border-top  border-0">
                          <div class="row flex-between-center">
                            <div class="col">
                              <div class="d-flex">
                                <div class="fas fa-circle mt-1 fs--2 text-primary"></div>
                                <p class="fs--1 ps-2 mb-0"><strong><asp:Literal ID="litPendingFulfil" runat="server" Text="0" /> orders</strong> are pending fulfilment</p>
                              </div>
                            </div>
                            <div class="col-auto d-flex align-items-center"><a class="alert-link fs--1 fw-medium" href="Orders/OrderList.aspx">View orders<i class="fas fa-chevron-right ms-1 fs--2"></i></a></div>
                          </div>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
                <div class="col-lg-12">
                  <div class="row g-3">
                    <div class="col-md-6">
                      <div class="card h-md-100 ecommerce-card-min-width">
                        <div class="card-header pb-0">
                          <h6 class="mb-0 mt-2 d-flex align-items-center">Weekly Sales<span class="ms-1 text-400" data-bs-toggle="tooltip" data-bs-placement="top" title="Calculated according to last week's sales"><span class="far fa-question-circle" data-fa-transform="shrink-1"></span></span></h6>
                        </div>
                        <div class="card-body d-flex flex-column justify-content-end">
                          <div class="row">
                            <div class="col">
                              <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litWeeklySales" runat="server" Text="Rs. 0" /></p><span class="badge badge-subtle-success rounded-pill fs--2">7d</span>
                            </div>
                            <div class="col-auto ps-0">
                              <div class="echart-bar-weekly-sales h-100 echart-bar-weekly-sales-smaller-width"></div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="col-md-6">
                      <div class="card product-share-doughnut-width">
                        <div class="card-header pb-0">
                          <h6 class="mb-0 mt-2 d-flex align-items-center">Order Completion</h6>
                        </div>
                        <div class="card-body d-flex flex-column justify-content-end">
                          <div class="row align-items-end">
                            <div class="col">
                              <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litCompletionPct" runat="server" Text="0%" /></p><span class="badge badge-subtle-success rounded-pill">Delivered</span>
                            </div>
                            <div class="col-auto ps-0"><canvas class="my-n5" id="marketShareDoughnut" width="112" height="112"></canvas>
                              <p class="mb-0 text-center fs--2 mt-4 text-500">Target: <span class="text-800">100%</span></p>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="col-md-6">
                      <div class="card h-md-100 h-100">
                        <div class="card-body">
                          <div class="row h-100 justify-content-between g-0">
                            <div class="col-5 col-sm-6 col-xxl pe-2">
                              <h6 class="mt-1">Order Types</h6>
                              <div class="fs--2 mt-3">
                                <div class="d-flex flex-between-center mb-1">
                                  <div class="d-flex align-items-center"><span class="dot bg-primary"></span><span class="fw-semi-bold">Dine In</span></div>
                                  <div class="d-xxl-none"><asp:Literal ID="litDineInPct" runat="server" Text="0%" /></div>
                                </div>
                                <div class="d-flex flex-between-center mb-1">
                                  <div class="d-flex align-items-center"><span class="dot bg-info"></span><span class="fw-semi-bold">Takeaway</span></div>
                                  <div class="d-xxl-none"><asp:Literal ID="litTakeawayPct" runat="server" Text="0%" /></div>
                                </div>
                                <div class="d-flex flex-between-center mb-1">
                                  <div class="d-flex align-items-center"><span class="dot bg-warning"></span><span class="fw-semi-bold">Delivery</span></div>
                                  <div class="d-xxl-none"><asp:Literal ID="litDeliveryPct" runat="server" Text="0%" /></div>
                                </div>
                              </div>
                            </div>
                            <div class="col-auto position-relative">
                              <div class="echart-product-share"></div>
                              <div class="position-absolute top-50 start-50 translate-middle text-dark fs-2"><asp:Literal ID="litTotalOrdersCenter" runat="server" Text="0" /></div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div class="col-md-6">
                      <div class="card">
                        <div class="card-header pb-0">
                          <h6 class="mb-0 mt-2 d-flex align-items-center">Total Order</h6>
                        </div>
                        <div class="card-body">
                          <div class="row align-items-end">
                            <div class="col">
                              <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litTotalOrder" runat="server" Text="0" /></p>
                              <div class="badge badge-subtle-primary rounded-pill fs--2">All time</div>
                            </div>
                            <div class="col-auto ps-0">
                              <div class="total-order-ecommerce" data-echarts='{"series":[{"type":"line","data":[110,100,250,210,530,480,320,325]}],"grid":{"bottom":"-10px"}}'></div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="col-xxl-6 col-xl-12">
              <div class="card py-3 mb-3">
                <div class="card-body py-3">
                  <div class="row g-0">
                    <div class="col-6 col-md-4 border-200 border-bottom border-end pb-4">
                      <h6 class="pb-1 text-700">Orders </h6>
                      <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litOrders" runat="server" Text="0" /></p>
                      <div class="d-flex align-items-center">
                        <h6 class="fs--2 mb-0 text-primary">All time</h6>
                      </div>
                    </div>
                    <div class="col-6 col-md-4 border-200 border-bottom border-end-md pb-4 ps-3">
                      <h6 class="pb-1 text-700">Items sold </h6>
                      <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litItemsSold" runat="server" Text="0" /></p>
                      <div class="d-flex align-items-center">
                        <h6 class="fs--2 mb-0 text-warning">Units</h6>
                      </div>
                    </div>
                    <div class="col-6 col-md-4 border-200 border-bottom border-end border-end-md-0 pb-4 pt-4 pt-md-0 ps-md-3">
                      <h6 class="pb-1 text-700">Cancelled </h6>
                      <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litCancelled" runat="server" Text="0" /></p>
                      <div class="d-flex align-items-center">
                        <h6 class="fs--2 mb-0 text-danger">Orders</h6>
                      </div>
                    </div>
                    <div class="col-6 col-md-4 border-200 border-bottom border-bottom-md-0 border-end-md pt-4 pb-md-0 ps-3 ps-md-0">
                      <h6 class="pb-1 text-700">Gross sale </h6>
                      <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litGrossSale" runat="server" Text="Rs. 0" /></p>
                      <div class="d-flex align-items-center">
                        <h6 class="fs--2 mb-0 text-success">All time</h6>
                      </div>
                    </div>
                    <div class="col-6 col-md-4 border-200 border-bottom-md-0 border-end pt-4 pb-md-0 ps-md-3">
                      <h6 class="pb-1 text-700">Avg order </h6>
                      <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litAvgOrder" runat="server" Text="Rs. 0" /></p>
                      <div class="d-flex align-items-center">
                        <h6 class="fs--2 mb-0 text-success">Per order</h6>
                      </div>
                    </div>
                    <div class="col-6 col-md-4 pb-0 pt-4 ps-3">
                      <h6 class="pb-1 text-700">Processing </h6>
                      <p class="font-sans-serif lh-1 mb-1 fs-2"><asp:Literal ID="litProcessing" runat="server" Text="0" /></p>
                      <div class="d-flex align-items-center">
                        <h6 class="fs--2 mb-0 text-info">In progress</h6>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="card">
                <div class="card-header">
                  <div class="row flex-between-center g-0">
                    <div class="col-auto">
                      <h6 class="mb-0">Total Sales</h6>
                    </div>
                    <div class="col-auto d-flex">
                      <div class="form-check mb-0 d-flex"><input class="form-check-input form-check-input-primary" id="ecommerceLastMonth" type="checkbox" checked="checked" /><label class="form-check-label ps-2 fs--2 text-600 mb-0" for="ecommerceLastMonth">This Month<span class="text-dark d-none d-md-inline">: <asp:Literal ID="litSalesThisMonth" runat="server" Text="Rs. 0" /></span></label></div>
                      <div class="form-check mb-0 d-flex ps-0 ps-md-3"><input class="form-check-input ms-2 form-check-input-warning opacity-75" id="ecommercePrevYear" type="checkbox" checked="checked" /><label class="form-check-label ps-2 fs--2 text-600 mb-0" for="ecommercePrevYear">Last Month<span class="text-dark d-none d-md-inline">: <asp:Literal ID="litSalesLastMonth" runat="server" Text="Rs. 0" /></span></label></div>
                    </div>
                    <div class="col-auto">
                      <div class="dropdown font-sans-serif btn-reveal-trigger"><button class="btn btn-link text-600 btn-sm dropdown-toggle dropdown-caret-none btn-reveal" type="button" id="dropdown-total-sales-ecomm" data-bs-toggle="dropdown" data-boundary="viewport" aria-haspopup="true" aria-expanded="false"><span class="fas fa-ellipsis-h fs--2"></span></button>
                        <div class="dropdown-menu dropdown-menu-end border py-2" aria-labelledby="dropdown-total-sales-ecomm"><a class="dropdown-item" href="#!">View</a><a class="dropdown-item" href="#!">Export</a>
                          <div class="dropdown-divider"></div><a class="dropdown-item text-danger" href="#!">Remove</a>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="card-body pe-xxl-0">
                  <!-- Find the JS file for the following chart at: src/js/charts/echarts/total-sales-ecommerce.js-->
                  <!-- If you are not using gulp based workflow, you can find the transpiled code at: public/assets/js/theme.js-->
                  <div class="echart-line-total-sales-ecommerce" data-echart-responsive="true" data-options='{"optionOne":"ecommerceLastMonth","optionTwo":"ecommercePrevYear"}'></div>
                </div>
              </div>
            </div>
          </div>
          <div class="row g-3 mb-3">
            <div class="col-xxl-3 col-md-6 col-lg-5">
              <div class="card shopping-cart-bar-min-height h-100">
                <div class="card-header d-flex flex-between-center">
                  <h6 class="mb-0">Order Breakdown</h6>
                  <div class="dropdown font-sans-serif btn-reveal-trigger"><button class="btn btn-link text-600 btn-sm dropdown-toggle dropdown-caret-none btn-reveal" type="button" id="dropdown-shopping-cart-bar" data-bs-toggle="dropdown" data-boundary="viewport" aria-haspopup="true" aria-expanded="false"><span class="fas fa-ellipsis-h fs--2"></span></button>
                    <div class="dropdown-menu dropdown-menu-end border py-2" aria-labelledby="dropdown-shopping-cart-bar"><a class="dropdown-item" href="Orders/OrderList.aspx">View Orders</a>
                    </div>
                  </div>
                </div>
                <div class="card-body py-0 d-flex align-items-center h-100">
                  <div class="flex-1">
                    <asp:Repeater ID="rptBreakdown" runat="server">
                      <ItemTemplate>
                        <div class='<%# "row g-0 align-items-center pb-3" + ((Container.ItemIndex == 0) ? "" : " border-top pt-3") %>'>
                          <div class="col pe-4">
                            <h6 class="fs--2 text-600"><%# Server.HtmlEncode(Convert.ToString(Eval("Status"))) %></h6>
                            <div class="progress" style="height:5px" role="progressbar" aria-valuemin="0" aria-valuemax="100">
                              <div class='<%# "progress-bar rounded-3 " + Eval("BarClass") %>' style='<%# "width: " + Eval("Pct") + "%" %>'></div>
                            </div>
                          </div>
                          <div class="col-auto text-end">
                            <p class="mb-0 text-900 font-sans-serif"><%# Eval("Pct") %>%</p>
                            <p class="mb-0 fs--2 text-500 fw-semi-bold"><span class="text-600"><%# Eval("Count") %></span> orders</p>
                          </div>
                        </div>
                      </ItemTemplate>
                    </asp:Repeater>
                  </div>
                </div>
              </div>
            </div>
            <div class="col-xxl-4 col-md-6 col-lg-7 order-xxl-1">
              <div class="card h-100">
                <div class="card-header bg-light py-2 d-flex flex-between-center">
                  <h6 class="mb-0">Top Products</h6>
                  <div class="d-flex"><a class="btn btn-link btn-sm me-2" href="#!">View Details</a>
                    <div class="dropdown font-sans-serif btn-reveal-trigger"><button class="btn btn-link text-600 btn-sm dropdown-toggle dropdown-caret-none btn-reveal" type="button" id="dropdown-top-products" data-bs-toggle="dropdown" data-boundary="viewport" aria-haspopup="true" aria-expanded="false"><span class="fas fa-ellipsis-h fs--2"></span></button>
                      <div class="dropdown-menu dropdown-menu-end border py-2" aria-labelledby="dropdown-top-products"><a class="dropdown-item" href="#!">View</a><a class="dropdown-item" href="#!">Export</a>
                        <div class="dropdown-divider"></div><a class="dropdown-item text-danger" href="#!">Remove</a>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="card-body d-flex h-100 flex-column justify-content-end">
                  <!-- Find the JS file for the following chart at: src/js/charts/echarts/top-products.js-->
                  <!-- If you are not using gulp based workflow, you can find the transpiled code at: public/assets/js/theme.js-->
                  <div class="echart-bar-top-products echart-bar-top-products-ecommerce" data-echart-responsive="true"> </div>
                </div>
              </div>
            </div>
            <div class="col-xxl-9 col-md-12">
              <div class="card z-1" id="recentPurchaseTable" data-list='{"valueNames":["name","email","product","payment","amount"],"page":7,"pagination":true}'>
                <div class="card-header">
                  <div class="row flex-between-center">
                    <div class="col-6 col-sm-auto d-flex align-items-center pe-0">
                      <h5 class="fs-0 mb-0 text-nowrap py-2 py-xl-0">Recent Purchases</h5>
                    </div>
                    <div class="col-6 col-sm-auto ms-auto text-end ps-0">
                      <div class="d-none" id="table-purchases-actions">
                        <div class="d-flex"><select class="form-select form-select-sm" aria-label="Bulk actions">
                            <option selected="">Bulk actions</option>
                            <option value="Refund">Refund</option>
                            <option value="Delete">Delete</option>
                            <option value="Archive">Archive</option>
                          </select><button class="btn btn-falcon-default btn-sm ms-2" type="button">Apply</button></div>
                      </div>
                      <div id="table-purchases-replace-element"><button class="btn btn-falcon-default btn-sm" type="button"><span class="fas fa-plus" data-fa-transform="shrink-3 down-2"></span><span class="d-none d-sm-inline-block ms-1">New</span></button><button class="btn btn-falcon-default btn-sm mx-2" type="button"><span class="fas fa-filter" data-fa-transform="shrink-3 down-2"></span><span class="d-none d-sm-inline-block ms-1">Filter</span></button><button class="btn btn-falcon-default btn-sm" type="button"><span class="fas fa-external-link-alt" data-fa-transform="shrink-3 down-2"></span><span class="d-none d-sm-inline-block ms-1">Export</span></button></div>
                    </div>
                  </div>
                </div>
                <div class="card-body px-0 py-0">
                  <div class="table-responsive scrollbar">
                    <table class="table table-sm fs--1 mb-0 overflow-hidden">
                      <thead class="bg-200 text-900">
                        <tr>
                          <th class="white-space-nowrap">
                            <div class="form-check mb-0 d-flex align-items-center"><input class="form-check-input" id="checkbox-bulk-purchases-select" type="checkbox" data-bulk-select='{"body":"table-purchase-body","actions":"table-purchases-actions","replacedElement":"table-purchases-replace-element"}' /></div>
                          </th>
                          <th class="sort pe-1 align-middle white-space-nowrap" data-sort="name">Customer</th>
                          <th class="sort pe-1 align-middle white-space-nowrap" data-sort="email">Phone</th>
                          <th class="sort pe-1 align-middle white-space-nowrap" data-sort="product">Order #</th>
                          <th class="sort pe-1 align-middle white-space-nowrap text-center" data-sort="payment">Status</th>
                          <th class="sort pe-1 align-middle white-space-nowrap text-end" data-sort="amount">Amount</th>
                          <th class="no-sort pe-1 align-middle data-table-row-action"></th>
                        </tr>
                      </thead>
                      <tbody class="list" id="table-purchase-body">
                        <asp:Repeater ID="rptRecent" runat="server">
                          <ItemTemplate>
                            <tr class="btn-reveal-trigger">
                              <td class="align-middle" style="width: 28px;">
                                <div class="form-check mb-0"><input class="form-check-input" type="checkbox" data-bulk-select-row="data-bulk-select-row" /></div>
                              </td>
                              <th class="align-middle white-space-nowrap name">
                                <a href='<%# "Orders/OrderDetail.aspx?id=" + Eval("OrderID") %>'><%# Server.HtmlEncode(string.IsNullOrEmpty(Convert.ToString(Eval("CustomerName"))) ? "Walk-in" : Convert.ToString(Eval("CustomerName"))) %></a>
                              </th>
                              <td class="align-middle white-space-nowrap email"><%# Server.HtmlEncode(Convert.ToString(Eval("CustomerPhone"))) %></td>
                              <td class="align-middle white-space-nowrap product"><%# Server.HtmlEncode(Convert.ToString(Eval("OrderNumber"))) %></td>
                              <td class="align-middle text-center fs-0 white-space-nowrap payment">
                                <span class='badge badge rounded-pill <%# StatusBadge(Eval("Status")) %>'><%# Server.HtmlEncode(Convert.ToString(Eval("Status"))) %></span>
                              </td>
                              <td class="align-middle text-end amount"><%# Fmt(Eval("TotalAmount")) %></td>
                              <td class="align-middle white-space-nowrap text-end">
                                <a class="btn btn-sm btn-falcon-default" href='<%# "Orders/OrderDetail.aspx?id=" + Eval("OrderID") %>'>View</a>
                              </td>
                            </tr>
                          </ItemTemplate>
                        </asp:Repeater>
                      </tbody>
                    </table>
                  </div>
                </div>
                <div class="card-footer">
                  <div class="row align-items-center">
                    <div class="pagination d-none"></div>
                    <div class="col">
                      <p class="mb-0 fs--1"><span class="d-none d-sm-inline-block me-2" data-list-info="data-list-info"></span></p>
                    </div>
                    <div class="col-auto d-flex"><button class="btn btn-sm btn-primary" type="button" data-list-pagination="prev"><span>Previous</span></button><button class="btn btn-sm btn-primary px-4 ms-2" type="button" data-list-pagination="next"><span>Next</span></button></div>
                  </div>
                </div>
              </div>
            </div>
            <div class="col-xxl-4 col-md-6">
              <div class="card h-100">
                <div class="card-header bg-light">
                  <div class="row justify-content-between">
                    <div class="col-auto">
                      <h6>Returning Customer Rate</h6>
                      <div class="d-flex align-items-center">
                        <h4 class="text-primary mb-0">Rs. 59.09%</h4><span class="badge rounded-pill ms-3 badge-subtle-primary"><span class="fas fa-caret-up"></span> 3.5%</span>
                      </div>
                    </div>
                    <div class="col-auto"><select class="form-select form-select-sm pe-4" id="select-returning-customer-month">
                        <option value="0">Jan</option>
                        <option value="1">Feb</option>
                        <option value="2">Mar</option>
                        <option value="3">Apr</option>
                        <option value="4">May</option>
                        <option value="5">Jun</option>
                        <option value="6">Jul</option>
                        <option value="7">Aug</option>
                        <option value="8">Sep</option>
                        <option value="9">Oct</option>
                        <option value="10">Nov</option>
                        <option value="11">Dec</option>
                      </select></div>
                  </div>
                </div>
                <div class="card-body">
                  <!-- Find the JS file for the following chart at: src/js/charts/echarts/returning-customer-rate.js-->
                  <!-- If you are not using gulp based workflow, you can find the transpiled code at: public/assets/js/theme.js-->
                  <div class="echart-line-returning-customer-rate h-100" data-echart-responsive="true" data-options='{"target":"returning-customer-rate-footer","monthSelect":"select-returning-customer-month","optionOne":"newMonth","optionTwo":"returningMonth"}'></div>
                </div>
                <div class="card-footer border-top py-2">
                  <div class="row align-items-center gx-0" id="returning-customer-rate-footer">
                    <div class="col-auto me-2">
                      <div class="btn btn-sm btn-text d-flex align-items-center p-0 shadow-none" id="newMonth"><span class="fas fa-circle text-primary fs--2 me-1"></span>New </div>
                    </div>
                    <div class="col-auto">
                      <div class="btn btn-sm btn-text d-flex align-items-center p-0 shadow-none" id="returningMonth"><span class="fas fa-circle text-warning fs--2 me-1"></span>Returning </div>
                    </div>
                    <div class="col text-end"><a class="btn btn-link btn-sm px-0 fw-medium" href="#!">View report <span class="fas fa-chevron-right fs--2"></span></a></div>
                  </div>
                </div>
              </div>
            </div>
            <div class="col-xxl-4 col-md-6">
              <div class="card h-100">
                <div class="card-header bg-light py-2">
                  <div class="d-flex flex-between-center">
                    <h6 class="mb-0">Sales by POS location </h6><a class="btn btn-link btn-sm px-0" href="#!">View Details<span class="fas fa-chevron-right ms-1 fs--2"></span></a>
                  </div>
                </div>
                <div class="card-body px-0 pt-4 pb-0">
                  <table class="table table-borderless font-sans-serif fw-medium fs--1">
                    <tbody>
                      <tr>
                        <td class="pb-2 pt-0"> <span class="fas fa-circle fs--2 me-1 text-primary"></span>Allocated Budget</td>
                        <td class="pb-2 pt-0 text-end">Rs. 13,325.98</td>
                        <td class="pb-2 pt-0 text-end"><span class="me-1 fas fa-caret-up text-success"></span>10%</td>
                      </tr>
                      <tr>
                        <td class="pb-2 pt-0"> <span class="fas fa-circle fs--2 me-1 text-warning"></span>Actual Spending</td>
                        <td class="pb-2 pt-0 text-end">Rs. 12,348.46</td>
                        <td class="pb-2 pt-0 text-end"><span class="me-1 fas fa-caret-down text-success"></span>13%</td>
                      </tr>
                    </tbody>
                  </table><!-- Find the JS file for the following chart at: src/js/charts/echarts/sales-by-pos-location.js-->
                  <!-- If you are not using gulp based workflow, you can find the transpiled code at: public/assets/js/theme.js-->
                  <div class="echart-radar-sales-by-pos-location h-100 px-md-2 mt-md-5" data-echart-responsive="true"></div>
                </div>
              </div>
            </div>
          </div>
          <div class="row">
            <div class="col">
              <div class="card h-lg-100 overflow-hidden">
                <div class="card-body p-0">
                  <div class="table-responsive scrollbar">
                    <table class="table table-dashboard mb-0 table-borderless fs--1 border-200">
                      <thead class="bg-light">
                        <tr class="text-900">
                          <th>Best Selling Products</th>
                          <th class="text-center">Orders(<asp:Literal ID="litBestTotalOrders" runat="server" Text="0" />)</th>
                          <th class="text-center">Order(%)</th>
                          <th class="text-end">Revenue</th>
                          <th class="pe-x1 text-end" style="width: 8rem">Revenue (%)</th>
                        </tr>
                      </thead>
                      <tbody>
                        <asp:Repeater ID="rptBest" runat="server">
                          <ItemTemplate>
                            <tr class="border-bottom border-200">
                              <td>
                                <div class="d-flex align-items-center position-relative">
                                  <div class="flex-1">
                                    <h6 class="mb-1 fw-semi-bold text-nowrap"><a class="text-900 stretched-link" href="Menu/MenuItems.aspx"><%# Server.HtmlEncode(Convert.ToString(Eval("ItemName"))) %></a></h6>
                                    <p class="fw-semi-bold mb-0 text-500">Menu item</p>
                                  </div>
                                </div>
                              </td>
                              <td class="align-middle text-center fw-semi-bold"><%# Eval("OrderCount") %></td>
                              <td class="align-middle text-center fw-semi-bold"><%# Eval("OrderPct") %>%</td>
                              <td class="align-middle text-end fw-semi-bold"><%# Fmt(Eval("Revenue")) %></td>
                              <td class="align-middle pe-x1">
                                <div class="d-flex align-items-center">
                                  <div class="progress me-3 rounded-3 bg-200" style="height: 5px; width:80px" role="progressbar" aria-valuemin="0" aria-valuemax="100">
                                    <div class="progress-bar bg-primary rounded-pill" style='<%# "width: " + Eval("RevenuePct") + "%;" %>'></div>
                                  </div>
                                  <div class="fw-semi-bold ms-2"><%# Eval("RevenuePct") %>%</div>
                                </div>
                              </td>
                            </tr>
                          </ItemTemplate>
                        </asp:Repeater>
                      </tbody>
                    </table>
                  </div>
                </div>
                <div class="card-footer bg-light py-2">
                  <div class="row flex-between-center">
                    <div class="col-auto"><select class="form-select form-select-sm">
                        <option>Last 7 days</option>
                        <option>Last Month</option>
                        <option>Last Year</option>
                      </select></div>
                    <div class="col-auto"><a class="btn btn-sm btn-falcon-default" href="#!">View All</a></div>
                  </div>
                </div>
              </div>
            </div>
          </div>

  <%-- Feed the demo ECharts with real OMS data, after the Falcon theme has
       initialised each chart instance. We only override data/labels/tooltip —
       the chart styling and structure stay the template's. --%>
  <script>
    (function () {
      var moneyFmt = function (v) { return 'Rs. ' + Number(v).toLocaleString(); };

      // ---- Total Sales: This Month vs Last Month daily revenue ----
      var sales = <%= TotalSalesChartJson %>;  // { labels:[], thisMonth:[], lastMonth:[] }

      function applyTotalSales() {
        var el = document.querySelector('.echart-line-total-sales-ecommerce');
        if (!el || !window.echarts) return false;
        var chart = window.echarts.getInstanceByDom(el);
        if (!chart) return false;

        chart.setOption({
          tooltip: {
            formatter: function (params) {
              return params.map(function (p, i) {
                return '<span class="fas fa-circle" style="color:' + p.borderColor + '"></span> ' +
                       '<span class="text-600">' + (i === 0 ? 'This Month' : 'Last Month') + ': ' + moneyFmt(p.value) + '</span>';
              }).join('<br/>');
            }
          },
          xAxis: {
            data: sales.labels,
            axisLabel: { formatter: function (v) { return v; } } // day-of-month
          },
          series: [
            { name: 'lastMonth',    data: sales.thisMonth },  // primary line = This Month
            { name: 'previousYear', data: sales.lastMonth }   // secondary line = Last Month
          ]
        });
        return true;
      }

      // ---- Top Products: top menu items (units sold + revenue) ----
      var top = <%= TopProductsChartJson %>;  // { labels:[], units:[], revenue:[] }

      function applyTopProducts() {
        var el = document.querySelector('.echart-bar-top-products');
        if (!el || !window.echarts) return false;
        var chart = window.echarts.getInstanceByDom(el);
        if (!chart) return false;

        chart.setOption({
          // Replace the dataset-driven demo with explicit category + two series.
          dataset: { source: null },
          legend: { data: ['Units', 'Revenue'] },
          tooltip: {
            trigger: 'item',
            formatter: function (p) {
              var val = p.seriesName === 'Revenue' ? moneyFmt(p.value) : p.value;
              return '<div class="fw-semi-bold">' + p.seriesName + '</div>' +
                     '<div class="fs--1 text-600"><strong>' + p.name + ':</strong> ' + val + '</div>';
            }
          },
          xAxis: { type: 'category', data: top.labels },
          yAxis: [
            { type: 'value' },                                  // units (left)
            { type: 'value', position: 'right', splitLine: { show: false },
              axisLabel: { formatter: function (v) { return v >= 1000 ? (v/1000)+'k' : v; } } } // revenue (right)
          ],
          series: [
            { name: 'Units',   type: 'bar', data: top.units },
            { name: 'Revenue', type: 'bar', yAxisIndex: 1, data: top.revenue }
          ]
        });
        return true;
      }

      // Theme initialises charts on window load; retry briefly until each is ready.
      var done = { sales: false, top: false };
      var tries = 0;
      var timer = setInterval(function () {
        if (!done.sales) done.sales = applyTotalSales();
        if (!done.top)   done.top   = applyTopProducts();
        if ((done.sales && done.top) || ++tries > 50) clearInterval(timer);
      }, 150);
      window.addEventListener('load', function () { applyTotalSales(); applyTopProducts(); });
    })();
  </script>
</asp:Content>