const svc = require("./summary.service");

async function adminSummary(_req, res, next) {
  try {
    const data = await svc.getSummary();
    res.json({ data });
  } catch (err) { next(err); }
}

async function usersCount(_req, res, next)     { try { res.json(await svc.countUsers()); } catch (e) { next(e); } }
async function productsCount(_req, res, next)  { try { res.json(await svc.countProducts()); } catch (e) { next(e); } }
async function ordersCount(_req, res, next)    { try { res.json(await svc.countOrders()); } catch (e) { next(e); } }
async function ordersPending(_req, res, next)  { try { res.json(await svc.countPending()); } catch (e) { next(e); } }
async function lowStockCount(_req, res, next)  { try { res.json(await svc.lowStockCount()); } catch (e) { next(e); } }
async function revenueToday(_req, res, next)   { try { res.json(await svc.revenueToday()); } catch (e) { next(e); } }
async function revenueMonth(_req, res, next)   { try { res.json(await svc.revenueMonth()); } catch (e) { next(e); } }
async function recentOrders(_req, res, next)   { try { res.json(await svc.recentOrders()); } catch (e) { next(e); } }
async function topProducts(_req, res, next)    { try { res.json(await svc.topProducts()); } catch (e) { next(e); } }
async function lowStock(_req, res, next)       { try { res.json(await svc.lowStock()); } catch (e) { next(e); } }

module.exports = {
  adminSummary,
  usersCount,
  productsCount,
  ordersCount,
  ordersPending,
  lowStockCount,
  revenueToday,
  revenueMonth,
  recentOrders,
  topProducts,
  lowStock,
};
