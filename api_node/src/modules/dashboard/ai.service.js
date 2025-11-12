// Helpers y stub del LLM (sin proveedor externo)

function extractBullets(text) {
  return String(text)
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l.startsWith("-") || l.startsWith("•"))
    .map((l) => l.replace(/^[-•]\s?/, ""));
}

function mergeIssues(base, extra) {
  const left = base || { issues: [], fixes: {} };
  const right = extra || {};
  const set = new Set([...(left.issues || []), ...((right.issues || []))]);
  return {
    issues: Array.from(set),
    fixes: { ...(left.fixes || {}), ...((right.fixes || {})) },
  };
}

/** IA simulada: devuelve texto “tipo IA” sin conectarse a ningún servicio */
async function callLLM(prompt) {
  // Genera una respuesta mock basada en el prompt (muy simple)
  const lines = [
    "• Resumen (IA simulada): ventas estables, ligera alza en ingresos diarios.",
    "• Riesgos: productos con stock bajo podrían afectar la disponibilidad.",
    "• Acciones: priorizar reposición de top productos y revisar pendientes.",
  ];
  // Si el prompt pide JSON estricto (irregularities), devolvemos JSON simulado
  if (String(prompt).includes('Devuelve EXACTAMENTE en JSON')) {
    return JSON.stringify({
      issues: ["Variación inusual de ingresos vs. promedio semanal (simulado)"],
      fixes: {
        checkReports: ["/admin/revenue/today", "/admin/revenue/month"],
        suggest: "Validar cortes de día y consistencia de estados de pedido.",
      },
    });
  }
  return lines.join("\n");
}

module.exports = { extractBullets, mergeIssues, callLLM };
