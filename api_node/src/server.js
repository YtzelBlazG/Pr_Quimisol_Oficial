/**
 * server.js
 * Punto de entrada de la API.
 * - Carga variables de entorno
 * - Inicializa middlewares globales
 * - Monta routers de cada módulo
 * - Maneja errores y 404
 * - Levanta el servidor HTTP
 */

require('dotenv').config(); // 1) Cargar variables de entorno lo primero

// =============================
// Core & Middlewares básicos
// =============================
const express = require('express');
const cors = require('cors');

const app = express();

// Middlewares propios centralizados
// Asegúrate de que './middlewares' exporte: { requestLogger, notFound, errorHandler }
const { requestLogger, notFound, errorHandler } = require('./middlewares');

// ---------- Middlewares globales (antes de rutas) ----------
app.use(cors());                 // CORS abierto (ajusta si necesitas restringir orígenes)
app.use(express.json());         // Parseo JSON del body
app.use(requestLogger);          // Log por request (si lo tienes implementado)

// =============================
// Healthcheck
// =============================
// Útil para verificar que el servicio está vivo (k8s, Docker, etc.)
app.get('/health', (_req, res) => res.json({ ok: true }));

// =============================
// Routers (import)
// =============================

// --- Mail (códigos por correo)
const mailRouter = require('./modules/mail/mail.router');

// --- Auth / Personas / Ubicaciones / Usuarios
const authRouter = require('./modules/auth/auth.router');
const personaRouter = require('./modules/persona/persona.router');
const ubicacionRouter = require('./modules/ubicacion/ubicacion.router');
const usuarioRouter = require('./modules/usuario/usuario.router');

// --- Dashboard / Admin
const { aiDashboardRouter } = require('./modules/dashboard/ai.routes');
const { adminSummaryRouter } = require('./modules/dashboard/summary.routes');

// --- Productos / Unidades / Extras
const productoRouter = require('./modules/producto/producto.router');
const unidadRouter = require('./modules/unidad/unidad.router');
const detalleProductoRoutes = require('./modules/detalleproducto/detalleproducto.router');
const carritoRoutes = require('./modules/carrito/carrito.router');
const favoritosRoutes = require('./modules/favoritos/favoritos.router');

// --- Pedidos
const pedidoRouter = require('./modules/pedidos/pedido.router');

// --- Ubicación-Pedido
const ubicacionPedidoRouter = require('./modules/ubicacion-pedido/ubicacionPedido.router');

// --- Ciclos de Entrega
const cicloEntregaRouter = require('./modules/ciclo-entrega/ciclo-entrega.router');

// =============================
// Montaje de Rutas
// =============================

// Núcleo (auth, personas, ubicaciones, usuarios)
app.use('/auth', authRouter);
app.use('/personas', personaRouter);
app.use('/ubicaciones', ubicacionRouter);
app.use('/usuarios', usuarioRouter);

// Mail
app.use('/mail', mailRouter);

// Dashboard / Admin
app.use('/ai/dashboard', aiDashboardRouter);
app.use('/admin', adminSummaryRouter);

// Productos / Unidades / Extras
app.use('/productos', productoRouter);
app.use('/unidades', unidadRouter);
app.use('/detalleproducto', detalleProductoRoutes);
app.use('/carrito', carritoRoutes);
app.use('/favoritos', favoritosRoutes);

// Pedidos (cabecera + detalles, crear desde carrito, listar por usuario, repartidor, etc.)
app.use('/pedidos', pedidoRouter);

// Ubicación-Pedido (relación pedido ↔ ubicaciones)
app.use('/ubicacion-pedido', ubicacionPedidoRouter);

// Ciclos de entrega (planificación mensual de entregas)
app.use('/ciclos-entrega', cicloEntregaRouter);

// =============================
// Middlewares de cierre
// =============================

// 404 para rutas no definidas
app.use(notFound);

// Manejo centralizado de errores (llega cualquier error con next(err))
app.use(errorHandler);

// =============================
// Boot (levantar servidor)
// =============================
const PORT = process.env.PORT || 3005;
const HOST = '0.0.0.0'; // 👈 importante para que responda también al celular

app.listen(PORT, HOST, () => {
  console.log(`🚀 API en http://${HOST}:${PORT}`);
});
