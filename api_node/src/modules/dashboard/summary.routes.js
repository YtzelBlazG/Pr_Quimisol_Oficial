const { Router } = require("express");
const ctrl = require("./summary.controller");

const adminSummaryRouter = Router();

// Endpoint consolidado (lo intenta primero el Flutter)
adminSummaryRouter.get("/summary", ctrl.adminSummary);

// Fallbacks (por si el consolidado no está disponible)
adminSummaryRouter.get("/users/count",     ctrl.usersCount);
adminSummaryRouter.get("/products/count",  ctrl.productsCount);
adminSummaryRouter.get("/orders/count",    ctrl.ordersCount);
adminSummaryRouter.get("/orders/pending",  ctrl.ordersPending);
adminSummaryRouter.get("/stock/low/count", ctrl.lowStockCount);
adminSummaryRouter.get("/revenue/today",   ctrl.revenueToday);
adminSummaryRouter.get("/revenue/month",   ctrl.revenueMonth);
adminSummaryRouter.get("/orders/recent",   ctrl.recentOrders);
adminSummaryRouter.get("/products/top",    ctrl.topProducts);
adminSummaryRouter.get("/stock/low",       ctrl.lowStock);

module.exports = { adminSummaryRouter };
