// src/modules/ciclo-entrega/ciclo-entrega.controller.js

const {
  listarCiclosPorAnioService,
  generarCiclosParaAnioService,
  actualizarCicloEntregaService,
  obtenerCicloPorIdService,

  // repartidores
  listarRepartidoresActivosService,
  obtenerRepartidoresDeCicloService,
  guardarRepartidoresDeCicloService,
} = require('./ciclo-entrega.service');

/**
 * GET /ciclos-entrega?anio=2025
 * GET /ciclos-entrega/anio/:anio
 */
async function listarPorAnio(req, res, next) {
  try {
    const anioRaw = req.params.anio ?? req.query.anio ?? new Date().getFullYear();
    const anio = parseInt(anioRaw, 10);

    if (Number.isNaN(anio)) {
      return res.status(400).json({ message: 'Año inválido.' });
    }

    const ciclos = await listarCiclosPorAnioService(anio);
    return res.json(ciclos);
  } catch (e) {
    next(e);
  }
}

/**
 * POST /ciclos-entrega/anio/:anio/generar
 * body opcional: { dia: number } (1..28 aprox)
 */
async function generarParaAnio(req, res, next) {
  try {
    const anio = parseInt(req.params.anio, 10);
    if (Number.isNaN(anio)) {
      return res.status(400).json({ message: 'Año inválido.' });
    }

    const diaBody = req.body && req.body.dia;
    let dia = parseInt(diaBody, 10);
    if (Number.isNaN(dia) || dia < 1 || dia > 28) {
      // Para evitar líos con Febrero, etc. usamos 15 por defecto
      dia = 15;
    }

    const ciclos = await generarCiclosParaAnioService(anio, dia);
    return res.status(201).json({
      message: `Ciclos de entrega para ${anio} generados/actualizados.`,
      ciclos,
    });
  } catch (e) {
    next(e);
  }
}

/**
 * GET /ciclos-entrega/:idciclo
 */
async function obtenerPorId(req, res, next) {
  try {
    const id = parseInt(req.params.idciclo, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ message: 'ID de ciclo inválido.' });
    }
    const ciclo = await obtenerCicloPorIdService(id);
    return res.json(ciclo);
  } catch (e) {
    next(e);
  }
}

/**
 * PUT /ciclos-entrega/:idciclo
 * body: { fecha_entrega?: 'YYYY-MM-DD', estado?: 'activo' | 'inactivo' | ... }
 */
async function actualizarCiclo(req, res, next) {
  try {
    const id = parseInt(req.params.idciclo, 10);
    if (Number.isNaN(id)) {
      return res.status(400).json({ message: 'ID de ciclo inválido.' });
    }

    const { fecha_entrega, estado } = req.body || {};

    const ciclo = await actualizarCicloEntregaService(id, {
      fecha_entrega,
      estado,
    });

    return res.json({
      message: 'Ciclo actualizado correctamente.',
      ciclo,
    });
  } catch (e) {
    next(e);
  }
}

/* ============================================================
 * REPARTIDORES POR CICLO
 * ============================================================
 */

/**
 * GET /ciclos-entrega/repartidores
 * Lista todos los repartidores activos (rol = 'repartidor').
 */
async function listarRepartidoresActivos(req, res) {
  try {
    const repartidores = await listarRepartidoresActivosService();
    return res.json(repartidores);
  } catch (err) {
    console.error('listarRepartidoresActivos:', err);
    return res.status(500).json({ message: 'Error al listar repartidores.' });
  }
}

/**
 * GET /ciclos-entrega/:idciclo/repartidores
 * Devuelve un array de idusuario asignados a ese ciclo.
 */
async function obtenerRepartidoresDeCiclo(req, res) {
  try {
    const idciclo = Number(req.params.idciclo);
    if (!Number.isFinite(idciclo)) {
      return res.status(400).json({ message: 'idciclo inválido.' });
    }
    const ids = await obtenerRepartidoresDeCicloService(idciclo);
    return res.json(ids);
  } catch (err) {
    console.error('obtenerRepartidoresDeCiclo:', err);
    return res
      .status(500)
      .json({ message: 'Error al obtener repartidores del ciclo.' });
  }
}

/**
 * PUT /ciclos-entrega/:idciclo/repartidores
 * body: { repartidores_ids: [1,2,3] }
 */
async function guardarRepartidoresDeCiclo(req, res) {
  try {
    const idciclo = Number(req.params.idciclo);
    const { repartidores_ids } = req.body || {};

    if (!Number.isFinite(idciclo)) {
      return res.status(400).json({ message: 'idciclo inválido.' });
    }
    if (!Array.isArray(repartidores_ids)) {
      return res.status(400).json({
        message: 'repartidores_ids debe ser un arreglo (puede estar vacío).',
      });
    }

    await guardarRepartidoresDeCicloService(idciclo, repartidores_ids);
    return res.json({ message: 'Repartidores asignados correctamente.' });
  } catch (err) {
    console.error('guardarRepartidoresDeCiclo:', err);
    return res
      .status(500)
      .json({ message: 'Error al guardar repartidores del ciclo.' });
  }
}

module.exports = {
  listarPorAnio,
  generarParaAnio,
  obtenerPorId,
  actualizarCiclo,

  listarRepartidoresActivos,
  obtenerRepartidoresDeCiclo,
  guardarRepartidoresDeCiclo,
};
