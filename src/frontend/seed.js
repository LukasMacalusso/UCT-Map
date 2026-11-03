// Script to seed ONLY users into the Identity database.
// To execute, open a terminal in the src/frontend directory and run: node seed.js

const API_URL = 'http://localhost:5000/api';

const ADMIN_USER = {
  name: 'Administrador UCT',
  email: 'admin@uct.cl',
  password: 'Admin12345!',
  role: 'Admin',
};

const SEED_USERS = [
  {
    name: 'Usuario Semilla',
    email: 'seed@uct.cl',
    password: 'Seed12345!',
    role: 'Student',
  },
  {
    name: 'Encargado de Objetos',
    email: 'objetos@uct.cl',
    password: 'Objetos12345!',
    role: 'ObjectsOfficer',
  },
  {
    name: 'Encargado de Incidentes',
    email: 'reclamos@uct.cl',
    password: 'Reclamos12345!',
    role: 'ComplaintsOfficer',
  },
  {
    name: 'Dr. Carlos Silva',
    email: 'carlos.silva@uct.cl',
    password: 'Profesor12345!',
    role: 'Teacher',
  },
  {
    name: 'Dra. María González',
    email: 'maria.gonzalez@uct.cl',
    password: 'Profesor12345!',
    role: 'Teacher',
  },
  {
    name: 'Mg. Juan Pérez',
    email: 'juan.perez@uct.cl',
    password: 'Profesor12345!',
    role: 'Teacher',
  },
  {
    name: 'Dra. Ana Rojas',
    email: 'ana.rojas@uct.cl',
    password: 'Profesor12345!',
    role: 'Teacher',
  },
  {
    name: 'Dr. Pedro Fernández',
    email: 'pedro.fernandez@uct.cl',
    password: 'Profesor12345!',
    role: 'Teacher',
  },
];

async function request(method, endpoint, data, token) {
  const response = await fetch(`${API_URL}${endpoint}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: data ? JSON.stringify(data) : undefined,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`${method} ${endpoint}: ${response.status} - ${errorText}`);
  }

  if (response.status === 204) return null;

  return response.json();
}

async function runSeed() {
  console.log('--- Sembrando únicamente usuarios ---');

  // 1. Crear o loguear Admin
  try {
    await request('POST', '/identity/register', ADMIN_USER);
    console.log(`Admin creado: ${ADMIN_USER.email}`);
  } catch {
    console.log(`Admin ya registrado: ${ADMIN_USER.email}`);
  }

  let adminToken = null;
  try {
    const adminLogin = await request('POST', '/identity/login', {
      email: ADMIN_USER.email,
      password: ADMIN_USER.password,
    });
    adminToken = adminLogin.token;
  } catch (err) {
    console.error(`Error al iniciar sesión como admin: ${err.message}`);
  }

  // Asegurar rol Admin
  if (adminToken) {
    try {
      const adminLogin = await request('POST', '/identity/login', {
        email: ADMIN_USER.email,
        password: ADMIN_USER.password,
      });
      await request('PUT', `/identity/${adminLogin.userId}/roles`, { roles: ['Admin'] }, adminToken);
    } catch {
      // Ignorar si ya tiene rol
    }
  }

  // 2. Crear y asignar roles para cada usuario
  for (const user of SEED_USERS) {
    let userId = null;

    try {
      const created = await request('POST', '/identity/register', {
        name: user.name,
        email: user.email,
        password: user.password,
        role: 'Student',
      });
      userId = created?.userId ?? null;
      console.log(`Usuario creado: ${user.name} (${user.email})`);
    } catch {
      try {
        const login = await request('POST', '/identity/login', {
          email: user.email,
          password: user.password,
        });
        userId = login?.userId ?? null;
        console.log(`Usuario ya existe: ${user.email}`);
      } catch (err) {
        console.error(`No se pudo registrar ni loguear a ${user.email}: ${err.message}`);
      }
    }

    if (adminToken && userId && user.role) {
      try {
        await request(
          'PUT',
          `/identity/${userId}/roles`,
          { roles: [user.role] },
          adminToken,
        );
        console.log(`Rol ${user.role} asignado a ${user.email}`);
      } catch (err) {
        console.warn(`No se pudo actualizar rol para ${user.email}: ${err.message}`);
      }
    }
  }

  console.log('\n--- Resumen de usuarios listos ---');
  console.log(`Admin:             ${ADMIN_USER.email} / ${ADMIN_USER.password}`);
  for (const u of SEED_USERS) {
    console.log(`${u.role.padEnd(19)}: ${u.email} / ${u.password}`);
  }
}

runSeed();
