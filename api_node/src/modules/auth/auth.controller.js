const authService = require("./auth.service");

async function login(req, res) {
  const { correo, contrasena } = req.body;
  try {
    const user = await authService.login(correo, contrasena);
    if (!user) return res.status(401).json({ error: "Credenciales inválidas" });
    res.json({ message: "Login exitoso", usuario: user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

async function register(req, res) {
  const { nombre, correo, contrasena } = req.body;
  try {
    if (!nombre || !correo || !contrasena) {
      return res.status(400).json({ error: "Faltan datos requeridos" });
    }
    const out = await authService.register({ nombre, correo, contrasena });
    res.status(201).json({ message: "Usuario registrado correctamente", ...out });
  } catch (err) {
    const msg = err.message || "Error en registro";
    const code = msg.includes("registrado") ? 409 : 500; // 409 para duplicado
    res.status(code).json({ error: msg });
  }
}

module.exports = { login, register };
