// src/modules/pedidos/pedido.controller.js
const {
  crearPedidoDesdeCarritoService,
  listarPedidosDeUsuarioService,
  obtenerPedidoConDetallesService,
  guardarUbicacionesDePedidoService,
  listarTodosLosPedidosService,
  listarPedidosPorUbicacionService,
  listarPedidosDeRepartidorService,
  actualizarPosicionRepartidorService, // 👈 NUEVO
} = require('./pedido.service');

async function crearPedidoDesdeCarrito(req, res) {
  try {
    const { idUsuario } = req.params;
    const { pedido, detalles, total } =
      await crearPedidoDesdeCarritoService(idUsuario);
    return res.status(201).json({
      message: 'Pedido creado correctamente.',
      pedido,
      detalles,
      total,
    });
  } catch (err) {
    const status = err.status || 500;
    console.error('crearPedidoDesdeCarrito:', err);
    return res
      .status(status)
      .json({ message: err.message || 'Error al crear el pedido.' });
  }
}

/**
 * Lista pedidos de un usuario (app cliente)
 */
async function listarPedidosDeUsuario(req, res) {
  try {
    const { idUsuario } = req.params;
    const pedidos = await listarPedidosDeUsuarioService(idUsuario);
    return res.json(pedidos);
  } catch (err) {
    console.error('listarPedidosDeUsuario:', err);
    return res.status(500).json({ message: 'Error al listar pedidos.' });
  }
}

/**
 * Lista TODOS los pedidos (panel admin)
 */
async function listarTodosLosPedidos(req, res) {
  try {
    const pedidos = await listarTodosLosPedidosService();
    return res.json(pedidos);
  } catch (err) {
    console.error('listarTodosLosPedidos:', err);
    return res
      .status(500)
      .json({ message: 'Error al listar todos los pedidos.' });
  }
}

/**
 * Lista pedidos por ubicación (una fila por cada (pedido, ubicación)).
 * Útil para ver cada entrega como un "sub-pedido".
 */
async function listarPedidosPorUbicacion(req, res) {
  try {
    const data = await listarPedidosPorUbicacionService();
    return res.json(data);
  } catch (err) {
    console.error('listarPedidosPorUbicacion:', err);
    return res
      .status(500)
      .json({ message: 'Error al listar pedidos por ubicación.' });
  }
}

async function obtenerPedidoConDetalles(req, res) {
  try {
    const { idPedido } = req.params;
    const data = await obtenerPedidoConDetallesService(idPedido);
    return res.json(data);
  } catch (err) {
    const status = err.status || 500;
    console.error('obtenerPedidoConDetalles:', err);
    return res
      .status(status)
      .json({ message: err.message || 'Error al obtener el pedido.' });
  }
}

/**
 * PUT /pedidos/:idPedido/ubicaciones
 * body: { ubicaciones_ids: [1,2,3] }
 */
async function guardarUbicacionesDePedido(req, res) {
  try {
    const idPedido = Number(req.params.idPedido);
    const { ubicaciones_ids } = req.body || {};

    if (!Number.isFinite(idPedido)) {
      return res.status(400).json({ message: 'idPedido inválido.' });
    }
    if (!Array.isArray(ubicaciones_ids) || ubicaciones_ids.length === 0) {
      return res.status(400).json({
        message: 'ubicaciones_ids debe ser un arreglo no vacío.',
      });
    }

    await guardarUbicacionesDePedidoService(idPedido, ubicaciones_ids);

    return res
      .status(200)
      .json({ message: 'Ubicaciones guardadas correctamente.' });
  } catch (err) {
    const status = err.status || 500;
    console.error('guardarUbicacionesDePedido:', err);
    return res.status(status).json({
      message: err.message || 'Error al guardar ubicaciones del pedido.',
    });
  }
}

/**
 * 🔹 GET /repartidores/:idPersona/pedidos
 * idPersona = persona del repartidor
 */
async function listarPedidosDeRepartidor(req, res) {
  try {
    const { idPersona } = req.params;
    const idNum = Number(idPersona);
    if (!Number.isFinite(idNum)) {
      return res.status(400).json({ message: 'idPersona inválido.' });
    }

    const pedidos = await listarPedidosDeRepartidorService(idNum);
    return res.json(pedidos);
  } catch (err) {
    console.error('listarPedidosDeRepartidor:', err);
    return res
      .status(500)
      .json({ message: 'Error al listar pedidos del repartidor.' });
  }
}

/**
 * 🔹 PATCH /pedidos/repartidores/:idPersona/posicion
 * body: { latitud, longitud }
 */
async function actualizarPosicionRepartidor(req, res) {
  try {
    const { idPersona } = req.params;
    const { latitud, longitud } = req.body || {};

    const idNum = Number(idPersona);
    if (!Number.isFinite(idNum)) {
      return res.status(400).json({ message: 'idPersona inválido.' });
    }

    if (latitud == null || longitud == null) {
      return res
        .status(400)
        .json({ message: 'latitud y longitud son requeridos.' });
    }

    await actualizarPosicionRepartidorService(idNum, latitud, longitud);

    // 204 = sin contenido, solo OK
    return res.status(204).send();
  } catch (err) {
    const status = err.status || 500;
    console.error('actualizarPosicionRepartidor:', err);
    return res.status(status).json({
      message: err.message || 'Error al actualizar posición del repartidor.',
    });
  }
}

module.exports = {
  crearPedidoDesdeCarrito,
  listarPedidosDeUsuario,
  listarTodosLosPedidos,
  listarPedidosPorUbicacion,
  obtenerPedidoConDetalles,
  guardarUbicacionesDePedido,
  listarPedidosDeRepartidor,
  actualizarPosicionRepartidor, // 👈 NUEVO
};
