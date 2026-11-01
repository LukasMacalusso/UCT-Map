// Script to seed test data into the Campus and Incident databases.
// To execute, open a terminal in the src/frontend directory and run: node seed.js

const API_URL = 'http://localhost:5000/api';

const SEED_USER = {
  name: 'Usuario Semilla',
  email: 'seed@uct.cl',
  password: 'Seed12345!',
};

const ADMIN_USER = {
  name: 'Administrador UCT',
  email: 'admin@uct.cl',
  password: 'Admin12345!',
};

const TEACHER_PASSWORD = 'Profesor12345!';

const SEED_TEACHERS = [
  {
    name: 'Dr. Carlos Silva',
    email: 'carlos.silva@uct.cl',
    password: TEACHER_PASSWORD,
    officeHours: [
      { dayOfWeek: 1, startTime: '09:00:00', endTime: '11:00:00', structureIdx: 0 },
      { dayOfWeek: 3, startTime: '14:30:00', endTime: '16:30:00', structureIdx: 0 },
    ],
  },
  {
    name: 'Dra. María González',
    email: 'maria.gonzalez@uct.cl',
    password: TEACHER_PASSWORD,
    officeHours: [
      { dayOfWeek: 2, startTime: '10:00:00', endTime: '12:00:00', structureIdx: 1 },
      { dayOfWeek: 4, startTime: '15:00:00', endTime: '17:00:00', structureIdx: 1 },
    ],
  },
  {
    name: 'Mg. Juan Pérez',
    email: 'juan.perez@uct.cl',
    password: TEACHER_PASSWORD,
    officeHours: [
      { dayOfWeek: 1, startTime: '11:00:00', endTime: '13:00:00', structureIdx: 2 },
      { dayOfWeek: 5, startTime: '09:30:00', endTime: '11:30:00', structureIdx: 2 },
    ],
  },
  {
    name: 'Dra. Ana Rojas',
    email: 'ana.rojas@uct.cl',
    password: TEACHER_PASSWORD,
    officeHours: [
      { dayOfWeek: 2, startTime: '08:30:00', endTime: '10:30:00', structureIdx: 0 },
      { dayOfWeek: 4, startTime: '11:00:00', endTime: '13:00:00', structureIdx: 0 },
    ],
  },
  {
    name: 'Dr. Pedro Fernández',
    email: 'pedro.fernandez@uct.cl',
    password: TEACHER_PASSWORD,
    officeHours: [],
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

async function postData(endpoint, data, token) {
  try {
    const result = await request('POST', endpoint, data, token);
    return result?.id ?? null;
  } catch (err) {
    console.error(err.message);
    return null;
  }
}

const daysAgo = (days) => new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

async function authenticate() {
  console.log('Registering seed user...');

  try {
    await request('POST', '/identity/register', { ...SEED_USER, role: 'Student' });
    console.log(`Seed user created: ${SEED_USER.email}`);
  } catch {
    console.log(`Seed user already exists: ${SEED_USER.email}`);
  }

  const login = await request('POST', '/identity/login', {
    email: SEED_USER.email,
    password: SEED_USER.password,
  });

  return { token: login.token, userId: login.userId };
}

function nextWeekdayAtUtc(targetDayOfWeek, hour, minute) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + 1);
  while (date.getUTCDay() !== targetDayOfWeek) {
    date.setUTCDate(date.getUTCDate() + 1);
  }
  date.setUTCHours(hour, minute, 0, 0);
  return date.toISOString().replace(/Z$/i, '');
}

async function seedTeachersAndSchedules(studentUserId, structureIds, fallbackToken) {
  console.log('Registering and configuring sample teachers...');

  let adminToken = null;
  try {
    await request('POST', '/identity/register', { ...ADMIN_USER, role: 'Admin' });
    console.log(`Admin user created: ${ADMIN_USER.email}`);
  } catch {
    // Admin already exists or backend restricts self-registration of Admin role
  }

  try {
    const adminLogin = await request('POST', '/identity/login', {
      email: ADMIN_USER.email,
      password: ADMIN_USER.password,
    });
    adminToken = adminLogin.token;
  } catch {
    // Admin may not exist if identity container has not been seeded yet
  }

  for (const teacher of SEED_TEACHERS) {
    let teacherId = null;

    try {
      const created = await request('POST', '/identity/register', {
        name: teacher.name,
        email: teacher.email,
        password: teacher.password,
        role: 'Teacher',
      });
      teacherId = created?.userId ?? null;
      console.log(`Teacher created: ${teacher.name} (${teacher.email})`);
    } catch {
      try {
        const createdAsStudent = await request('POST', '/identity/register', {
          name: teacher.name,
          email: teacher.email,
          password: teacher.password,
          role: 'Student',
        });
        teacherId = createdAsStudent?.userId ?? null;
      } catch {
        console.log(`Teacher already exists: ${teacher.email}`);
      }
    }

    if (!teacherId) {
      try {
        const teacherLogin = await request('POST', '/identity/login', {
          email: teacher.email,
          password: teacher.password,
        });
        teacherId = teacherLogin?.userId ?? null;
      } catch (err) {
        console.error(`Could not login as ${teacher.email}: ${err.message}`);
        continue;
      }
    }

    if (adminToken && teacherId) {
      try {
        await request(
          'PUT',
          `/identity/${teacherId}/roles`,
          { roles: ['Teacher'] },
          adminToken,
        );
      } catch (err) {
        console.warn(`Could not update role for ${teacher.email}: ${err.message}`);
      }
    }

    const existingHours = await request(
      'GET',
      `/schedule/office-hours?teacherId=${teacherId}`,
      null,
      fallbackToken,
    ).catch(() => []);

    if (!existingHours || existingHours.length === 0) {
      for (const block of teacher.officeHours) {
        const structureRefId = structureIds[block.structureIdx % structureIds.length] ?? null;
        await postData(
          '/schedule/office-hours',
          {
            teacherRefId: teacherId,
            structureRefId,
            dayOfWeek: block.dayOfWeek,
            startTime: block.startTime,
            endTime: block.endTime,
          },
          fallbackToken,
        );
      }
    }

    if (studentUserId && teacher.officeHours.length > 0) {
      const firstBlock = teacher.officeHours[0];
      const [hourStr, minStr] = firstBlock.startTime.split(':');
      const scheduledAt = nextWeekdayAtUtc(
        firstBlock.dayOfWeek,
        Number(hourStr),
        Number(minStr),
      );
      const structureRefId =
        structureIds[firstBlock.structureIdx % structureIds.length] ?? null;

      await postData(
        '/schedule/meetings',
        {
          teacherRefId: teacherId,
          studentRefId: studentUserId,
          structureRefId,
          scheduledAt,
          durationMinutes: 30,
        },
        fallbackToken,
      );
    }
  }
}

async function runSeed() {
  console.log('Initializing test data injection...');

  const auth = await authenticate();
  const token = auth?.token;
  const studentUserId = auth?.userId;

  if (!token) return console.error('Authentication failed.');

  console.log('Creating Campus...');
  const campusId = await postData(
    '/campus/campuses',
    {
      name: 'Campus San Francisco',
      address: 'Manuel Montt 056, Temuco',
      latitude: 50,
      longitude: 50,
    },
    token,
  );

  if (!campusId) return console.error('Campus creation failed.');

  console.log('Creating Category Groups...');
  const categoryGroupId = await postData(
    '/campus/category-groups',
    { name: 'Infraestructura' },
    token,
  );

  if (!categoryGroupId) return console.error('Category group creation failed.');

  console.log('Creating Categories...');
  const classroomCategoryId = await postData(
    '/campus/categories',
    {
      categoryGroupId,
      name: 'Sala de Clases',
      icon: 'book',
      description: 'Sala de uso general para clases teóricas',
    },
    token,
  );

  const commonCategoryId = await postData(
    '/campus/categories',
    {
      categoryGroupId,
      name: 'Espacio Común',
      icon: 'users',
      description: 'Patios, pasillos y áreas de descanso',
    },
    token,
  );

  if (!classroomCategoryId) return console.error('Category creation failed.');

  console.log('Creating Buildings and Structures...');
  const buildings = [
    { name: 'Edificio T', floorsCount: 4, latitude: 35, longitude: 45 },
    { name: 'Biblioteca Central', floorsCount: 2, latitude: 60, longitude: 70 },
    { name: 'Edificio C', floorsCount: 3, latitude: 20, longitude: 80 },
  ];

  const structureIds = [];

  for (const building of buildings) {
    const buildingId = await postData(
      '/campus/buildings',
      {
        campusId,
        name: building.name,
        floorsCount: building.floorsCount,
        latitude: building.latitude,
        longitude: building.longitude,
      },
      token,
    );

    if (buildingId) {
      console.log(`Creating rooms for ${building.name}...`);

      for (let i = 1; i <= 3; i++) {
        await postData(
          '/campus/rooms',
          {
            buildingId,
            categoryId: classroomCategoryId,
            name: `Sala ${building.name[building.name.length - 1]}-${i}01`,
            floor: i,
            number: `${i}01`,
          },
          token,
        );
      }
    }

    const structureId = await postData(
      '/campus/structures',
      {
        campusId,
        categoryId: classroomCategoryId,
        name: building.name,
        latitude: building.latitude,
        longitude: building.longitude,
      },
      token,
    );

    if (structureId) structureIds.push(structureId);
  }

  const plazaStructureId = await postData(
    '/campus/structures',
    {
      campusId,
      categoryId: commonCategoryId ?? classroomCategoryId,
      name: 'Plaza Central',
      latitude: 50,
      longitude: 50,
    },
    token,
  );

  if (plazaStructureId) structureIds.push(plazaStructureId);

  if (structureIds.length === 0) return console.error('Structure creation failed.');

  console.log('Creating lost objects...');
  const lostObjects = [
    { title: 'Mochila negra', description: 'Mochila con un notebook y su cargador dentro.', status: 0 },
    { title: 'Llaves con llavero rojo', description: 'Tres llaves y un llavero de plástico rojo.', status: 0 },
    { title: 'Botella de agua azul', description: 'Botella metálica azul con stickers.', status: 1 },
    { title: 'Calculadora científica', description: 'Calculadora Casio fx-991 dentro de su estuche.', status: 1 },
    { title: 'Auriculares inalámbricos', description: 'Estuche blanco con los audífonos dentro.', status: 2 },
    { title: 'Billetera de cuero', description: 'Billetera café con documentos y tarjetas.', status: 2 },
    { title: 'Polerón gris', description: 'Polerón gris talla M olvidado en la sala.', status: 3 },
    { title: 'Cuaderno universitario', description: 'Cuaderno con apuntes de cálculo.', status: 0 },
    { title: 'Cargador de notebook', description: 'Cargador Lenovo de 65W con cable.', status: 1 },
    { title: 'Paraguas negro', description: 'Paraguas plegable con mango de madera.', status: 2 },
    { title: 'Carnet universitario', description: 'Carnet con nombre y carrera del estudiante.', status: 0 },
    { title: 'Gorro de lana', description: 'Gorro tejido de color verde.', status: 3 },
  ];

  const lostObjectIds = [];

  for (const [index, lostObject] of lostObjects.entries()) {
    const lostObjectId = await postData(
      '/incident/lost-objects',
      {
        title: lostObject.title,
        description: lostObject.description,
        status: lostObject.status,
        photoUrl: `https://picsum.photos/seed/uct-${index + 1}/600/400`,
        structureId: structureIds[index % structureIds.length],
      },
      token,
    );

    if (lostObjectId) lostObjectIds.push(lostObjectId);
  }

  console.log('Creating reports...');
  const reports = [
    { title: 'Baño roto en el segundo piso', description: 'La puerta del baño no cierra y el lavamanos gotea.', ticketType: 0, complaintStatus: 0, days: 1 },
    { title: 'Luz intermitente en sala de estudio', description: 'El tubo fluorescente de la mesa 4 parpadea constantemente.', ticketType: 1, complaintStatus: 0, days: 2 },
    { title: 'Silla rota en la sala 301', description: 'Una silla tiene la pata trasera quebrada.', ticketType: 2, complaintStatus: 0, days: 4 },
    { title: 'Basura acumulada en el pasillo', description: 'Hay bolsas de basura en el pasillo desde el viernes.', ticketType: 0, complaintStatus: 0, days: 5 },
    { title: 'Proyector sin señal', description: 'El proyector de la sala 102 no entrega imagen.', ticketType: 1, complaintStatus: 1, days: 7 },
    { title: 'Puerta de emergencia bloqueada', description: 'La salida de emergencia está bloqueada con cajas.', ticketType: 3, complaintStatus: 0, days: 9 },
    { title: 'Enchufe suelto en laboratorio', description: 'El enchufe de la mesa 2 está suelto y hace chispas.', ticketType: 0, complaintStatus: 0, days: 11 },
    { title: 'Filtración de agua en el techo', description: 'El techo de la biblioteca gotea cuando llueve.', ticketType: 1, complaintStatus: 0, days: 13 },
    { title: 'Ventana sin vidrio', description: 'La ventana de la sala 204 perdió el vidrio.', ticketType: 2, complaintStatus: 0, days: 16 },
    { title: 'Pizarra rayada', description: 'La pizarra de la sala 105 está rayada y no se borra bien.', ticketType: 2, complaintStatus: 0, days: 20 },
    { title: 'Extintor vencido', description: 'El extintor del pasillo del primer piso está vencido.', ticketType: 0, complaintStatus: 0, days: 25 },
    { title: 'Ruido en la sala de clases', description: 'Hay ruido constante desde el edificio vecino.', ticketType: 3, complaintStatus: 0, days: 30 },
  ];

  for (const [index, report] of reports.entries()) {
    const referencesLostObject = index % 4 === 0 && lostObjectIds.length > 0;

    await postData(
      '/incident/reports',
      {
        structureRefId: structureIds[index % structureIds.length],
        ticketType: report.ticketType,
        isActive: true,
        reportedAt: daysAgo(report.days),
        ...(referencesLostObject
          ? { lostObjectId: lostObjectIds[Math.floor(index / 4) % lostObjectIds.length] }
          : {}),
        complaint: {
          title: report.title,
          description: report.description,
          status: report.complaintStatus,
        },
      },
      token,
    );
  }

  await seedTeachersAndSchedules(studentUserId, structureIds, token);

  console.log('Data injection completed successfully.');
  console.log(`Seed student: ${SEED_USER.email} / ${SEED_USER.password}`);
  console.log(`Seed admin:   ${ADMIN_USER.email} / ${ADMIN_USER.password}`);
  console.log(
    `Seed teacher: ${SEED_TEACHERS[0].email} / ${TEACHER_PASSWORD}`,
  );
  console.log('Reload the application to see the seeded data.');
}

runSeed();
