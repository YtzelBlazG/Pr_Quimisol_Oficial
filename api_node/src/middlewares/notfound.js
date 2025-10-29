// Respuesta 404 para rutas no existentes
module.exports = function notFound(req, res, _next) {
  res.status(404).json({ error: "Not Found", path: req.originalUrl });
};
