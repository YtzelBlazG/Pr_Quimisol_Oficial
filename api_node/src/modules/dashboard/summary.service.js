// Datos FIXTOS (mock). No se conecta a BD.
const SUMMARY_MOCK = {
  totalUsers: 128,
  totalProducts: 342,
  totalOrders: 57,
  ordersPending: 9,
  lowStockCount: 5,
  revenueToday: 1240.5,
  revenueMonth: 18350.75,
  recentOrders: [
    { id: 1012, code: "QMS-1012", customer: "Juan Pérez", items: 4, total: 220.9, status: "Paid" },
    { id: 1011, code: "QMS-1011", customer: "María Gómez", items: 2, total: 95.0,  status: "Pending" },
    { id: 1010, code: "QMS-1010", customer: "Carlos Rivas", items: 1, total: 48.5, status: "Paid" },
  ],
  topProducts: [
    { name: "Desengrasante X", sold: 84, revenue: 2450 },
    { name: "Detergente Y",   sold: 65, revenue: 1800 },
    { name: "Ambientador Z",  sold: 41, revenue: 980 },
  ],
  lowStock: [
    { name: "Cloro 5L",           stock: 8,  minStock: 15 },
    { name: "Guantes Nitrilo M",  stock: 12, minStock: 25 },
  ],
};

async function getSummary()        { return SUMMARY_MOCK; }
async function countUsers()        { return { count: SUMMARY_MOCK.totalUsers }; }
async function countProducts()     { return { count: SUMMARY_MOCK.totalProducts }; }
async function countOrders()       { return { count: SUMMARY_MOCK.totalOrders }; }
async function countPending()      { return { count: SUMMARY_MOCK.ordersPending }; }
async function lowStockCount()     { return { count: SUMMARY_MOCK.lowStockCount }; }
async function revenueToday()      { return { amount: SUMMARY_MOCK.revenueToday }; }
async function revenueMonth()      { return { amount: SUMMARY_MOCK.revenueMonth }; }
async function recentOrders()      { return SUMMARY_MOCK.recentOrders; }
async function topProducts()       { return SUMMARY_MOCK.topProducts; }
async function lowStock()          { return SUMMARY_MOCK.lowStock; }

module.exports = {
  getSummary,
  countUsers,
  countProducts,
  countOrders,
  countPending,
  lowStockCount,
  revenueToday,
  revenueMonth,
  recentOrders,
  topProducts,
  lowStock,
};
