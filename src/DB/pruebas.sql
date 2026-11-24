USE omm_slp;

START TRANSACTION;

-- 1. Escuelas
INSERT INTO escuela (id_escuela, cct, nombre, municipio, zona, tipo) VALUES
(1, '24DPR0001A', 'Primaria Benito Juarez', 'San Luis Potosi', 'Centro', 'PUBLICA'),
(2, '24PES0002B', 'Instituto del Valle', 'Soledad de Graciano Sanchez', 'Centro', 'PRIVADA'),
(3, '24DPR0003C', 'Escuela Miguel Hidalgo', 'Matehuala', 'Altiplano', 'PUBLICA'),
(4, '24PES0004D', 'Colegio del Saber', 'Ciudad Valles', 'Huasteca', 'PRIVADA');

-- 2. Ediciones
INSERT INTO edicion (id_edicion, anio) VALUES
(1, 2025),
(2, 2026);

-- 3. Participantes
INSERT INTO participante (id_participante, nombre, apellidos, genero) VALUES
(1, 'Ana', 'Lopez Hernandez', 'FEMENINO'),
(2, 'Luis', 'Garcia Martinez', 'MASCULINO'),
(3, 'Sofia', 'Torres Rivera', 'FEMENINO'),
(4, 'Diego', 'Mendez Casparticipanteparticipanteid_participantetillo', 'MASCULINO'),
(5, 'Alejandro', 'Ramirez Santos', 'NO_ESPECIFICADO'),
(6, 'Valeria', 'Cruz Flores', 'FEMENINO');

-- 4. Categorias
INSERT INTO categoria (id_categoria, nombre) VALUES
(1, '4to Primaria'),
(2, '5to Primaria'),
(3, '6to Primaria');

-- 5. Usuarios y roles
INSERT INTO usuario (id_usuario, nombre, correo, password_hash, estado) VALUES
(1, 'Yo', 'admin.prueba@omm.test', 'HASH1', 'activo'),
(2, 'Maestra', 'captura.prueba@omm.test', 'HASH2', 'activo');

INSERT INTO rol (id_rol, nombre, descripcion) VALUES
(1, 'administrador', 'Acceso de administracion de la plataforma'),
(2, 'capturista', 'Captura de resultados y aplicaciones');

INSERT INTO usuario_rol (id_usuario_rol, id_usuario, id_rol) VALUES
(1, 1, 1),
(2, 2, 2);

-- 6. Escuelas inscritas por edicion
INSERT INTO escuela_edicion
(id_escuela_edicion, id_escuela, id_edicion, fecha_registro) VALUES
(1, 1, 1, '2025-02-10'),
(2, 2, 1, '2025-02-12'),
(3, 1, 2, '2026-02-05'),
(4, 2, 2, '2026-02-07'),
(5, 3, 2, '2026-02-09');

-- 7. Participaciones
INSERT INTO participacion
(id_participacion, id_participante, id_edicion, id_escuela, id_categoria,
 id_escuela_edicion, medio_registro, fecha_registro) VALUES
(1, 1, 2, 1, 1, 3, 'escuela', '2026-02-10 10:00:00'),
(2, 2, 2, 2, 2, 4, 'escuela', '2026-02-11 11:00:00'),
(3, 3, 2, 3, 1, 5, 'escuela', '2026-02-12 12:00:00'),
(4, 4, 2, 4, 2, NULL, 'individual', '2026-02-13 13:00:00'),
(5, 5, 1, 1, 1, 1, 'escuela', '2025-02-14 09:00:00'),
(6, 6, 1, 2, 2, 2, 'escuela', '2025-02-15 09:30:00'),
(7, 6, 2, 2, 3, NULL, 'individual', '2026-02-15 11:30:00');

-- 8. Etapas
INSERT INTO etapa
(id_etapa, id_edicion, nombre, fecha_inicio, fecha_fin, estado) VALUES
(1, 2, 'Escolar', '2026-03-01 08:00:00', '2026-03-31 23:59:59', 'cerrada'),
(2, 2, 'Regional', '2026-04-15 08:00:00', '2026-05-15 23:59:59', 'activa'),
(3, 1, 'Etapa unica', '2025-03-01 08:00:00', '2025-04-01 23:59:59', 'cerrada');

-- 9. Examenes
INSERT INTO examen
(id_examen, id_etapa, titulo, disponible_desde, disponible_hasta, estado) VALUES
(1, 1, 'Examen de primera etapa - Primaria', '2026-03-01 08:00:00', '2026-03-31 23:59:59', 'cerrado'),
(2, 1, 'Examen de primera etapa - Secundaria', '2026-03-01 08:00:00', '2026-03-31 23:59:59', 'cerrado'),
(3, 2, 'Examen de segunda etapa - Primaria', '2026-04-15 08:00:00', '2026-05-15 23:59:59', 'publicado'),
(4, 3, 'Examen 2025 - Primaria', '2025-03-01 08:00:00', '2025-04-01 23:59:59', 'cerrado');

INSERT INTO examen_categoria (id_examen_categoria, id_examen, id_categoria) VALUES
(1, 1, 1),
(2, 2, 2),
(3, 3, 1),
(4, 4, 1),
(5, 4, 2);
