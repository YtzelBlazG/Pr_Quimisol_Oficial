// src/middlewares/index.js
const requestLogger = require('./requestlogger');
const notFound = require('./notfound');
const errorHandler = require('./errorhandler');

module.exports = { requestLogger, notFound, errorHandler };
