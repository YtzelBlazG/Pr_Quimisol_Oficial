const { Router } = require("express");
const { aiReport, aiIrregularities, aiQA } = require("./ai.controller");

const aiDashboardRouter = Router();

aiDashboardRouter.post("/report", aiReport);
aiDashboardRouter.post("/irregularities", aiIrregularities);
aiDashboardRouter.post("/qa", aiQA);

module.exports = { aiDashboardRouter };
