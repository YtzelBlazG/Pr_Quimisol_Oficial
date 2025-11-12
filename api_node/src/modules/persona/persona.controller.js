const personaService = require("./persona.service");

async function list(req, res) {
  res.json(await personaService.list());
}

async function getById(req, res) {
  const persona = await personaService.getById(req.params.id);
  if (!persona) return res.status(404).json({ error: "No encontrado" });
  res.json(persona);
}

async function update(req, res) {
  await personaService.update(req.params.id, req.body);
  res.json({ ok: true });
}

async function remove(req, res) {
  await personaService.remove(req.params.id);
  res.json({ ok: true });
}

module.exports = { list, getById, update, remove };
