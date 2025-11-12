const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

const query = (text, params) => pool.query(text, params);

async function withTransaction(work) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const res = await work(client);
    await client.query('COMMIT');
    return res;
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch {}
    throw e;
  } finally {
    client.release();
  }
}

module.exports = { pool, query, withTransaction };
