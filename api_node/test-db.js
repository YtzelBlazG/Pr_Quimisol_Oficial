// test-db.js
require('dotenv').config();
const { pool } = require('./src/config/db');

(async () => {
  try {
    const { rows } = await pool.query('select current_database() db, current_user usr;');
    console.log(rows[0]); // { db: '...', usr: '...' }
  } catch (err) {
    console.error('DB error:', err);
  } finally {
    await pool.end();
  }
})();
