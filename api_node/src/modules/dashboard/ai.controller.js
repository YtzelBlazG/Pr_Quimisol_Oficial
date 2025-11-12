const { extractBullets, mergeIssues, callLLM } = require("./ai.service");

// Normalizador simple del payload
function toNumber(n, def = 0) {
  const v = Number(n);
  return Number.isFinite(v) ? v : def;
}
function normalizeSummary(body = {}) {
  return {
    totalUsers:     toNumber(body.totalUsers),
    totalProducts:  toNumber(body.totalProducts),
    totalOrders:    toNumber(body.totalOrders),
    ordersPending:  toNumber(body.ordersPending),
    lowStockCount:  toNumber(body.lowStockCount),
    revenueToday:   toNumber(body.revenueToday),
    revenueMonth:   toNumber(body.revenueMonth),
    recentOrders:   Array.isArray(body.recentOrders) ? body.recentOrders : [],
    topProducts:    Array.isArray(body.topProducts) ? body.topProducts : [],
    lowStock:       Array.isArray(body.lowStock) ? body.lowStock : [],
  };
}

// Reglas determinísticas base (sin IA)
function baseIrregularities(ctx) {
  const issues = [];
  if (ctx.ordersPending > ctx.totalOrders) issues.push("Pendientes mayor que total de órdenes.");
  if (ctx.revenueMonth < ctx.revenueToday) issues.push("Ingresos del mes menores que los del día.");
  if (ctx.totalOrders === 0 && ctx.revenueToday > 0) issues.push("Ingresos positivos sin órdenes hoy.");
  if (ctx.totalProducts > 0 && ctx.lowStockCount > ctx.totalProducts * 0.5) {
    issues.push("Más del 50% del catálogo en stock bajo.");
  }
  return issues;
}

async function aiReport(req, res, next) {
  try {
    const ctx = normalizeSummary(req.body);
    const prompt = `Eres un analista. Redacta un reporte ejecutivo breve (máx 10 frases) en español.
Datos JSON:
${JSON.stringify(ctx)}
Incluye: tendencias, riesgos, variaciones relevantes. Formatea con viñetas.`;
    const summary = await callLLM(prompt);
    const highlights = extractBullets(summary);
    res.json({ summary, highlights });
  } catch (err) { next(err); }
}

async function aiIrregularities(req, res, next) {
  try {
    const ctx = normalizeSummary(req.body);
    const issues = baseIrregularities(ctx);

    const prompt = `Eres auditor. Revisa el JSON y devuelve SOLO irregularidades justificadas y acciones sugeridas.
JSON:
${JSON.stringify(ctx)}
Devuelve EXACTAMENTE en JSON: {"issues": [..], "fixes": {..}}`;

    let llmJson = {};
    try {
      const llmRaw = await callLLM(prompt);
      llmJson = JSON.parse(llmRaw); // si devuelve JSON (nuestro stub lo hace)
    } catch {
      llmJson = {};
    }

    const merged = mergeIssues({ issues, fixes: {} }, llmJson);
    res.json(merged);
  } catch (err) { next(err); }
}

async function aiQA(req, res, next) {
  try {
    const question = String(req.body?.question || "");
    const context = normalizeSummary(req.body?.context || {});
    if (!question || question.length < 2) {
      return res.status(400).json({ error: "Pregunta inválida" });
    }
    const prompt = `Contesta en español y de forma directa la pregunta del admin usando SOLO este JSON:
${JSON.stringify(context)}
Pregunta: ${question}`;
    const answer = await callLLM(prompt);
    res.json({ answer });
  } catch (err) { next(err); }
}

module.exports = { aiReport, aiIrregularities, aiQA };
