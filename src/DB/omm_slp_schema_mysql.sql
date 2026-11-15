-- OMM SLP - Esquema inicial de base de datos
-- Motor: MySQL 8.0.16 o superior (recomendado: MySQL 8.4 LTS)
-- Estado: borrador de desarrollo. Ejecutar en una base de datos nueva.
-- Codificacion: utf8mb4.
-- Las fechas DATETIME se almacenaran en UTC; la aplicacion convertira
-- las fechas a la zona horaria local cuando las muestre.

CREATE DATABASE IF NOT EXISTS omm_slp
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE omm_slp;

-- ============================================================
-- 1. CATALOGOS Y CUENTAS
-- ============================================================

CREATE TABLE escuela (
    id_escuela INT UNSIGNED NOT NULL AUTO_INCREMENT,
    cct VARCHAR(20) NULL,
    nombre VARCHAR(200) NOT NULL,
    municipio VARCHAR(120) NOT NULL,
    zona VARCHAR(120) NOT NULL,
    PRIMARY KEY (id_escuela),
    UNIQUE KEY uq_escuela_cct (cct),
    CONSTRAINT ck_escuela_cct_no_vacio
        CHECK (cct IS NULL OR TRIM(cct) <> ''),
    CONSTRAINT ck_escuela_nombre_no_vacio
        CHECK (TRIM(nombre) <> '')
) ENGINE=InnoDB;

CREATE TABLE edicion (
    id_edicion INT UNSIGNED NOT NULL AUTO_INCREMENT,
    anio SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (id_edicion),
    UNIQUE KEY uq_edicion_anio (anio),
    CONSTRAINT ck_edicion_anio_positivo CHECK (anio > 0)
) ENGINE=InnoDB;

CREATE TABLE participante (
    id_participante INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(120) NOT NULL,
    apellidos VARCHAR(180) NOT NULL,
    PRIMARY KEY (id_participante),
    CONSTRAINT ck_participante_nombre_no_vacio CHECK (TRIM(nombre) <> ''),
    CONSTRAINT ck_participante_apellidos_no_vacio CHECK (TRIM(apellidos) <> '')
) ENGINE=InnoDB;

CREATE TABLE categoria (
    id_categoria INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_categoria),
    UNIQUE KEY uq_categoria_nombre (nombre),
    CONSTRAINT ck_categoria_nombre_no_vacio CHECK (TRIM(nombre) <> '')
) ENGINE=InnoDB;

CREATE TABLE usuario (
    id_usuario INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(160) NOT NULL,
    correo VARCHAR(254) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo',
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario),
    -- La collation por defecto de la base de datos no distingue mayusculas;
    -- por ello este UNIQUE evita correos duplicados por capitalizacion.
    UNIQUE KEY uq_usuario_correo (correo),
    CONSTRAINT ck_usuario_estado
        CHECK (estado IN ('activo', 'suspendido', 'pendiente')),
    CONSTRAINT ck_usuario_nombre_no_vacio CHECK (TRIM(nombre) <> ''),
    CONSTRAINT ck_usuario_password_hash_no_vacio CHECK (TRIM(password_hash) <> '')
) ENGINE=InnoDB;

CREATE TABLE rol (
    id_rol INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(60) NOT NULL,
    descripcion TEXT NULL,
    PRIMARY KEY (id_rol),
    UNIQUE KEY uq_rol_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE usuario_rol (
    id_usuario_rol INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_usuario INT UNSIGNED NOT NULL,
    id_rol INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_usuario_rol),
    UNIQUE KEY uq_usuario_rol (id_usuario, id_rol),
    KEY ix_usuario_rol_rol (id_rol),
    CONSTRAINT fk_usuario_rol_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_usuario_rol_rol
        FOREIGN KEY (id_rol) REFERENCES rol (id_rol)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 2. ESCUELAS INSCRITAS EN CADA EDICION
-- ============================================================

CREATE TABLE escuela_edicion (
    id_escuela_edicion INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_escuela INT UNSIGNED NOT NULL,
    id_edicion INT UNSIGNED NOT NULL,
    fecha_registro DATE NOT NULL DEFAULT (CURRENT_DATE),
    PRIMARY KEY (id_escuela_edicion),
    UNIQUE KEY uq_escuela_por_edicion (id_escuela, id_edicion),
    -- Clave compuesta para asegurar que la participacion use la misma
    -- escuela y edicion que el registro escolar al que apunta.
    UNIQUE KEY uq_escuela_edicion_referencia
        (id_escuela_edicion, id_escuela, id_edicion),
    KEY ix_escuela_edicion_edicion (id_edicion),
    CONSTRAINT fk_escuela_edicion_escuela
        FOREIGN KEY (id_escuela) REFERENCES escuela (id_escuela)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_escuela_edicion_edicion
        FOREIGN KEY (id_edicion) REFERENCES edicion (id_edicion)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 3. PARTICIPACIONES E HISTORIAL
-- ============================================================

CREATE TABLE participacion (
    id_participacion INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_participante INT UNSIGNED NOT NULL,
    id_edicion INT UNSIGNED NOT NULL,
    id_escuela INT UNSIGNED NOT NULL,
    id_categoria INT UNSIGNED NOT NULL,
    id_escuela_edicion INT UNSIGNED NULL,
    medio_registro VARCHAR(20) NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_participacion),
    -- El mismo participante solo tiene una inscripcion por edicion.
    UNIQUE KEY uq_participante_por_edicion (id_participante, id_edicion),
    KEY ix_participacion_edicion_categoria (id_edicion, id_categoria),
    KEY ix_participacion_escuela (id_escuela),
    CONSTRAINT ck_participacion_medio
        CHECK (medio_registro IN ('escuela', 'individual')),
    -- En el registro escolar debe existir la inscripcion de la escuela.
    -- En el registro individual se conserva la escuela de procedencia,
    -- aunque esta no se haya inscrito en esa edicion.
    CONSTRAINT ck_participacion_tipo_registro
        CHECK (
            (medio_registro = 'escuela' AND id_escuela_edicion IS NOT NULL)
            OR
            (medio_registro = 'individual' AND id_escuela_edicion IS NULL)
        ),
    CONSTRAINT fk_participacion_participante
        FOREIGN KEY (id_participante) REFERENCES participante (id_participante)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_participacion_edicion
        FOREIGN KEY (id_edicion) REFERENCES edicion (id_edicion)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_participacion_escuela
        FOREIGN KEY (id_escuela) REFERENCES escuela (id_escuela)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_participacion_categoria
        FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- Si id_escuela_edicion no es NULL, obliga a que coincidan escuela
    -- y edicion con el registro escolar referenciado.
    CONSTRAINT fk_participacion_escuela_edicion
        FOREIGN KEY (id_escuela_edicion, id_escuela, id_edicion)
        REFERENCES escuela_edicion
            (id_escuela_edicion, id_escuela, id_edicion)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 4. ETAPAS Y EXAMENES
-- ============================================================

CREATE TABLE etapa (
    id_etapa INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_edicion INT UNSIGNED NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    orden SMALLINT UNSIGNED NOT NULL,
    fecha_inicio DATETIME NULL,
    fecha_fin DATETIME NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'borrador',
    PRIMARY KEY (id_etapa),
    UNIQUE KEY uq_etapa_orden_edicion (id_edicion, orden),
    UNIQUE KEY uq_etapa_nombre_edicion (id_edicion, nombre),
    CONSTRAINT ck_etapa_orden_positivo CHECK (orden > 0),
    CONSTRAINT ck_etapa_estado
        CHECK (estado IN ('borrador', 'programada', 'activa', 'cerrada')),
    CONSTRAINT ck_etapa_fechas
        CHECK (fecha_inicio IS NULL OR fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT fk_etapa_edicion
        FOREIGN KEY (id_edicion) REFERENCES edicion (id_edicion)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE examen (
    id_examen INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_etapa INT UNSIGNED NOT NULL,
    titulo VARCHAR(180) NOT NULL,
    disponible_desde DATETIME NULL,
    disponible_hasta DATETIME NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'borrador',
    PRIMARY KEY (id_examen),
    KEY ix_examen_etapa (id_etapa),
    CONSTRAINT ck_examen_estado
        CHECK (estado IN ('borrador', 'publicado', 'cerrado')),
    CONSTRAINT ck_examen_fechas
        CHECK (
            disponible_desde IS NULL
            OR disponible_hasta IS NULL
            OR disponible_hasta >= disponible_desde
        ),
    CONSTRAINT ck_examen_titulo_no_vacio CHECK (TRIM(titulo) <> ''),
    CONSTRAINT fk_examen_etapa
        FOREIGN KEY (id_etapa) REFERENCES etapa (id_etapa)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE examen_categoria (
    id_examen_categoria INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_examen INT UNSIGNED NOT NULL,
    id_categoria INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_examen_categoria),
    UNIQUE KEY uq_examen_categoria (id_examen, id_categoria),
    KEY ix_examen_categoria_categoria (id_categoria),
    CONSTRAINT fk_examen_categoria_examen
        FOREIGN KEY (id_examen) REFERENCES examen (id_examen)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_examen_categoria_categoria
        FOREIGN KEY (id_categoria) REFERENCES categoria (id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 5. PROBLEMAS Y ARCHIVOS
-- ============================================================

CREATE TABLE problema (
    id_problema INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_examen INT UNSIGNED NOT NULL,
    orden INT UNSIGNED NOT NULL,
    contenido_editor JSON NOT NULL,
    respuesta_correcta TEXT NOT NULL,
    puntaje INT NOT NULL,
    solucion_privada TEXT NULL,
    PRIMARY KEY (id_problema),
    UNIQUE KEY uq_problema_orden_examen (id_examen, orden),
    CONSTRAINT ck_problema_orden_positivo CHECK (orden > 0),
    CONSTRAINT ck_problema_puntaje_no_negativo CHECK (puntaje >= 0),
    CONSTRAINT ck_problema_contenido_objeto
        CHECK (JSON_TYPE(contenido_editor) = 'OBJECT'),
    CONSTRAINT fk_problema_examen
        FOREIGN KEY (id_examen) REFERENCES examen (id_examen)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE archivo_problema (
    id_archivo INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_problema INT UNSIGNED NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_archivo VARCHAR(700) NOT NULL,
    tipo_mime VARCHAR(120) NOT NULL,
    tamano_bytes BIGINT UNSIGNED NOT NULL,
    orden INT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (id_archivo),
    UNIQUE KEY uq_archivo_ruta (ruta_archivo),
    UNIQUE KEY uq_archivo_orden_problema (id_problema, orden),
    CONSTRAINT ck_archivo_tamano_positivo CHECK (tamano_bytes > 0),
    CONSTRAINT ck_archivo_orden_positivo CHECK (orden > 0),
    CONSTRAINT fk_archivo_problema
        FOREIGN KEY (id_problema) REFERENCES problema (id_problema)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 6. APLICACIONES DE EXAMEN Y RESPUESTAS
-- ============================================================

CREATE TABLE aplicacion_examen (
    id_aplicacion INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_participacion INT UNSIGNED NOT NULL,
    id_examen INT UNSIGNED NOT NULL,
    id_usuario_captura INT UNSIGNED NULL,
    modalidad VARCHAR(30) NOT NULL,
    tipo_datos_recibidos VARCHAR(20) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    fecha_inicio DATETIME NULL,
    fecha_entrega DATETIME NULL,
    puntaje_total INT NULL,
    tipo_calificacion VARCHAR(20) NULL,
    PRIMARY KEY (id_aplicacion),
    -- Suposicion inicial: una sola aplicacion por participante y examen.
    UNIQUE KEY uq_participacion_examen (id_participacion, id_examen),
    KEY ix_aplicacion_examen (id_examen),
    CONSTRAINT ck_aplicacion_modalidad
        CHECK (modalidad IN ('impreso_escuela', 'en_linea_escuela', 'en_linea_individual')),
    CONSTRAINT ck_aplicacion_tipo_datos
        CHECK (tipo_datos_recibidos IN ('puntaje_total', 'respuestas')),
    CONSTRAINT ck_aplicacion_estado
        CHECK (estado IN ('pendiente', 'en_progreso', 'entregada', 'calificada', 'cancelada')),
    CONSTRAINT ck_aplicacion_tipo_calificacion
        CHECK (
            tipo_calificacion IS NULL
            OR tipo_calificacion IN ('automatica', 'capturada', 'mixta')
        ),
    CONSTRAINT ck_aplicacion_puntaje_no_negativo
        CHECK (puntaje_total IS NULL OR puntaje_total >= 0),
    CONSTRAINT ck_aplicacion_fechas
        CHECK (fecha_inicio IS NULL OR fecha_entrega IS NULL OR fecha_entrega >= fecha_inicio),
    CONSTRAINT fk_aplicacion_participacion
        FOREIGN KEY (id_participacion) REFERENCES participacion (id_participacion)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aplicacion_examen
        FOREIGN KEY (id_examen) REFERENCES examen (id_examen)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aplicacion_usuario_captura
        FOREIGN KEY (id_usuario_captura) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE respuesta (
    id_respuesta INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_aplicacion INT UNSIGNED NOT NULL,
    id_problema INT UNSIGNED NOT NULL,
    valor_respuesta TEXT NULL,
    puntaje_obtenido INT NULL,
    es_correcta BOOLEAN NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_respuesta),
    UNIQUE KEY uq_respuesta_problema_aplicacion (id_aplicacion, id_problema),
    KEY ix_respuesta_problema (id_problema),
    CONSTRAINT ck_respuesta_puntaje_no_negativo
        CHECK (puntaje_obtenido IS NULL OR puntaje_obtenido >= 0),
    CONSTRAINT ck_respuesta_es_correcta
        CHECK (es_correcta IS NULL OR es_correcta IN (0, 1)),
    CONSTRAINT fk_respuesta_aplicacion
        FOREIGN KEY (id_aplicacion) REFERENCES aplicacion_examen (id_aplicacion)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_respuesta_problema
        FOREIGN KEY (id_problema) REFERENCES problema (id_problema)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- 7. DECISIONES DEL COMITE
-- ============================================================

CREATE TABLE decision_avance (
    id_decision INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_participacion INT UNSIGNED NOT NULL,
    id_etapa INT UNSIGNED NOT NULL,
    id_usuario_decisor INT UNSIGNED NOT NULL,
    avanza BOOLEAN NOT NULL,
    fecha_decision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT NULL,
    PRIMARY KEY (id_decision),
    -- Una decision vigente por participante y etapa.
    UNIQUE KEY uq_decision_participacion_etapa (id_participacion, id_etapa),
    CONSTRAINT ck_decision_avanza CHECK (avanza IN (0, 1)),
    KEY ix_decision_etapa (id_etapa),
    CONSTRAINT fk_decision_participacion
        FOREIGN KEY (id_participacion) REFERENCES participacion (id_participacion)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_decision_etapa
        FOREIGN KEY (id_etapa) REFERENCES etapa (id_etapa)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_decision_usuario
        FOREIGN KEY (id_usuario_decisor) REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================================
-- NOTAS DE DISENO Y VALIDACIONES PENDIENTES
-- ============================================================
-- 1. CCT es UNIQUE y puede ser NULL para escuelas sin CCT disponible.
-- 2. La participacion guarda escuela y categoria propias de esa edicion.
-- 3. id_escuela_edicion es NULL para participantes registrados individualmente.
-- 4. Los puntajes son INTEGER. valor_respuesta se conserva como texto para
--    almacenar exactamente la respuesta numerica capturada.
-- 5. contenido_editor usa JSON nativo; las imagenes se guardan como archivos
--    y archivo_problema conserva sus rutas y metadatos.
-- 6. Las fechas DATETIME deben guardarse en UTC desde el backend.
-- 7. El backend debe validar que la categoria del participante este asociada
--    al examen, que el examen corresponda a la edicion de la participacion y
--    que cada respuesta corresponda a un problema del examen presentado.
-- 8. El esquema supone una sola aplicacion por participante y examen y una
--    sola decision por participante y etapa. Revisar si habra reintentos o
--    si se necesita conservar cambios sucesivos de decisiones.
-- 9. MySQL aplica CHECK constraints a partir de MySQL 8.0.16.
