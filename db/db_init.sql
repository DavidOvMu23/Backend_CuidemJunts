/* ===========================================================
    CuidemJunts - MariaDB
   =========================================================== */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

/* ---------- DROPS (orden seguro) ---------- */
DROP TABLE IF EXISTS `alerta`;
DROP TABLE IF EXISTS `comunicacion`;
DROP TABLE IF EXISTS `cita`;
DROP TABLE IF EXISTS `contacto_emergencia`;
DROP TABLE IF EXISTS `persona_mayor`;
DROP TABLE IF EXISTS `trabajador`;
DROP TABLE IF EXISTS `supervisor`;
DROP TABLE IF EXISTS `teleoperador`;
DROP TABLE IF EXISTS `notificacion_usuario`;
DROP TABLE IF EXISTS `notificacion`;
DROP TABLE IF EXISTS `rol_usuario`;
DROP TABLE IF EXISTS `rol`;
DROP TABLE IF EXISTS `usuario`;

/* ===========================================================
    1) CREATE TABLES (sin claves foráneas)
   =========================================================== */

/* usuario (base para login: teleoperador, supervisor) */
CREATE TABLE `usuario` (
  `usuario_id` CHAR(36) NOT NULL,
  `nombre` VARCHAR(100) NOT NULL,
  `apellido` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `telefono` VARCHAR(20) DEFAULT NULL,
  `activo` BOOLEAN DEFAULT TRUE,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`usuario_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* rol (para definir tipo de usuario: supervisor o teleoperador) */
CREATE TABLE `rol` (
  `rol_id` INT NOT NULL AUTO_INCREMENT,
  `nombre` ENUM('supervisor','teleoperador') NOT NULL,
  PRIMARY KEY (`rol_id`),
  UNIQUE KEY `uq_rol_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* rol_usuario */
CREATE TABLE `rol_usuario` (
  `usuario_id` CHAR(36) NOT NULL,
  `rol_id` INT NOT NULL,
  PRIMARY KEY (`usuario_id`,`rol_id`),
  KEY `idx_rol_usuario_rol` (`rol_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* trabajador (extiende usuario, contiene datos comunes) */
CREATE TABLE `trabajador` (
  `trabajador_id` CHAR(36) NOT NULL,
  `dni` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`trabajador_id`),
  UNIQUE KEY `uq_trabajador_dni` (`dni`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* supervisor */
CREATE TABLE `supervisor` (
  `supervisor_id` CHAR(36) NOT NULL,
  PRIMARY KEY (`supervisor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* teleoperador */
CREATE TABLE `teleoperador` (
  `teleoperador_id` CHAR(36) NOT NULL,
  `supervisor_id` CHAR(36) NOT NULL,
  PRIMARY KEY (`teleoperador_id`),
  KEY `idx_teleoperador_supervisor` (`supervisor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* persona_mayor */
CREATE TABLE `persona_mayor` (
  `persona_id` CHAR(36) NOT NULL,
  `nombre` VARCHAR(100) NOT NULL,
  `apellido` VARCHAR(100) NOT NULL,
  `telefono` VARCHAR(20) NOT NULL,
  `fecha_nacimiento` DATE NOT NULL,
  `direccion` VARCHAR(255) DEFAULT NULL,
  `nivel_dependencia` ENUM('Leve','Moderado','Grave') DEFAULT 'Leve',
  `frecuencia_llamadas` ENUM('Diaria','Semanal','Mensual') DEFAULT 'Semanal',
  `hora_preferida` TIME DEFAULT NULL,
  `estado` ENUM('Activo','Inactivo') DEFAULT 'Activo',
  `intereses` TEXT DEFAULT NULL,
  `notas_medicas` TEXT DEFAULT NULL,
  `teleoperador_asignado` CHAR(36) DEFAULT NULL,
  PRIMARY KEY (`persona_id`),
  KEY `idx_persona_teleoperador` (`teleoperador_asignado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* contacto_emergencia */
CREATE TABLE `contacto_emergencia` (
  `contacto_id` BIGINT NOT NULL AUTO_INCREMENT,
  `persona_id` CHAR(36) NOT NULL,
  `nombre` VARCHAR(100) NOT NULL,
  `relacion` VARCHAR(50) DEFAULT NULL,
  `telefono` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`contacto_id`),
  KEY `idx_contacto_persona` (`persona_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* cita (las llamadas programadas) */
CREATE TABLE `cita` (
  `cita_id` BIGINT NOT NULL AUTO_INCREMENT,
  `persona_id` CHAR(36) NOT NULL,
  `teleoperador_id` CHAR(36) NOT NULL,
  `fecha` DATE NOT NULL,
  `hora_inicio` TIME NOT NULL,
  `hora_fin` TIME DEFAULT NULL,
  PRIMARY KEY (`cita_id`),
  KEY `idx_cita_persona` (`persona_id`),
  KEY `idx_cita_teleoperador` (`teleoperador_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* comunicacion (resultado de la llamada) */
CREATE TABLE `comunicacion` (
  `comunicacion_id` BIGINT NOT NULL AUTO_INCREMENT,
  `cita_id` BIGINT NOT NULL,
  `estado_animo` VARCHAR(100) DEFAULT NULL,
  `temas_tratados` TEXT DEFAULT NULL,
  `observaciones` TEXT DEFAULT NULL,
  `fecha` DATE NOT NULL DEFAULT (CURRENT_DATE),
  `hora_inicio` TIME DEFAULT NULL,
  `hora_fin` TIME DEFAULT NULL,
  PRIMARY KEY (`comunicacion_id`),
  KEY `idx_comunicacion_cita` (`cita_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* alerta (por ejemplo si no responde la persona mayor) */
CREATE TABLE `alerta` (
  `alerta_id` BIGINT NOT NULL AUTO_INCREMENT,
  `cita_id` BIGINT NOT NULL,
  `tipo` ENUM('No contesta','Emergencia','Otro') NOT NULL,
  `descripcion` TEXT DEFAULT NULL,
  `creada_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`alerta_id`),
  KEY `idx_alerta_cita` (`cita_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* notificacion */
CREATE TABLE `notificacion` (
  `notificacion_id` BIGINT NOT NULL AUTO_INCREMENT,
  `tipo` ENUM('recordatorio','llamada_proxima','alerta') NOT NULL,
  `titulo` VARCHAR(100) NOT NULL,
  `mensaje` VARCHAR(255) NOT NULL,
  `prioridad` ENUM('baja','media','alta') DEFAULT 'baja',
  `creada_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notificacion_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* notificacion_usuario */
CREATE TABLE `notificacion_usuario` (
  `usuario_id` CHAR(36) NOT NULL,
  `notificacion_id` BIGINT NOT NULL,
  `leida` BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (`usuario_id`,`notificacion_id`),
  KEY `idx_notificacion_usuario_notificacion` (`notificacion_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* ===========================================================
    2) FOREIGN KEYS
   =========================================================== */

ALTER TABLE `rol_usuario`
  ADD CONSTRAINT `fk_rol_usuario_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario`(`usuario_id`),
  ADD CONSTRAINT `fk_rol_usuario_rol` FOREIGN KEY (`rol_id`) REFERENCES `rol`(`rol_id`);

ALTER TABLE `trabajador`
  ADD CONSTRAINT `fk_trabajador_usuario` FOREIGN KEY (`trabajador_id`) REFERENCES `usuario`(`usuario_id`);

ALTER TABLE `supervisor`
  ADD CONSTRAINT `fk_supervisor_trabajador` FOREIGN KEY (`supervisor_id`) REFERENCES `trabajador`(`trabajador_id`);

ALTER TABLE `teleoperador`
  ADD CONSTRAINT `fk_teleoperador_trabajador` FOREIGN KEY (`teleoperador_id`) REFERENCES `trabajador`(`trabajador_id`),
  ADD CONSTRAINT `fk_teleoperador_supervisor` FOREIGN KEY (`supervisor_id`) REFERENCES `supervisor`(`supervisor_id`);

ALTER TABLE `persona_mayor`
  ADD CONSTRAINT `fk_persona_teleoperador` FOREIGN KEY (`teleoperador_asignado`) REFERENCES `teleoperador`(`teleoperador_id`);

ALTER TABLE `contacto_emergencia`
  ADD CONSTRAINT `fk_contacto_persona` FOREIGN KEY (`persona_id`) REFERENCES `persona_mayor`(`persona_id`) ON DELETE CASCADE;

ALTER TABLE `cita`
  ADD CONSTRAINT `fk_cita_persona` FOREIGN KEY (`persona_id`) REFERENCES `persona_mayor`(`persona_id`),
  ADD CONSTRAINT `fk_cita_teleoperador` FOREIGN KEY (`teleoperador_id`) REFERENCES `teleoperador`(`teleoperador_id`);

ALTER TABLE `comunicacion`
  ADD CONSTRAINT `fk_comunicacion_cita` FOREIGN KEY (`cita_id`) REFERENCES `cita`(`cita_id`) ON DELETE CASCADE;

ALTER TABLE `alerta`
  ADD CONSTRAINT `fk_alerta_cita` FOREIGN KEY (`cita_id`) REFERENCES `cita`(`cita_id`) ON DELETE CASCADE;

ALTER TABLE `notificacion_usuario`
  ADD CONSTRAINT `fk_notificacion_usuario_usuario` FOREIGN KEY (`usuario_id`) REFERENCES `usuario`(`usuario_id`),
  ADD CONSTRAINT `fk_notificacion_usuario_notificacion` FOREIGN KEY (`notificacion_id`) REFERENCES `notificacion`(`notificacion_id`);

SET FOREIGN_KEY_CHECKS = 1;

/* ===========================================================
    3) DUMMIES - Datos de ejemplo
   =========================================================== */

START TRANSACTION;

/* Roles */
INSERT INTO rol (nombre) VALUES ('supervisor'), ('teleoperador');
SET @ROL_SUPERVISOR := (SELECT rol_id FROM rol WHERE nombre='supervisor');
SET @ROL_TELEOPERADOR := (SELECT rol_id FROM rol WHERE nombre='teleoperador');

/* IDs de usuario */
SET @U_SUPERVISOR := '00000000-0000-0000-0000-000000000001';
SET @U_TELEOP1 := '00000000-0000-0000-0000-000000000002';
SET @U_TELEOP2 := '00000000-0000-0000-0000-000000000003';

/* Passwords hash bcrypt de 'temporal123' */
SET @PWD := '$2b$12$oqtmAKfZU0z/VHWlXBjAHOxFT0azngUga6y2H0pWZRVjtIffhRSdy';

/* Usuarios base */
INSERT INTO usuario (usuario_id, nombre, apellido, email, password_hash, telefono, activo)
VALUES
(@U_SUPERVISOR, 'Laura', 'Martínez', 'supervisor@cuidemjunts.local', @PWD, '600000001', TRUE),
(@U_TELEOP1, 'Javier', 'Sánchez', 'teleop1@cuidemjunts.local', @PWD, '600000002', TRUE),
(@U_TELEOP2, 'Marta', 'Ruiz', 'teleop2@cuidemjunts.local', @PWD, '600000003', TRUE);

/* Roles asignados */
INSERT INTO rol_usuario (usuario_id, rol_id)
VALUES
(@U_SUPERVISOR, @ROL_SUPERVISOR),
(@U_TELEOP1, @ROL_TELEOPERADOR),
(@U_TELEOP2, @ROL_TELEOPERADOR);

/* Trabajadores */
INSERT INTO trabajador (trabajador_id, dni)
VALUES
(@U_SUPERVISOR, '12345678A'),
(@U_TELEOP1, '87654321B'),
(@U_TELEOP2, '11223344C');

/* Supervisor */
INSERT INTO supervisor (supervisor_id) VALUES (@U_SUPERVISOR);

/* Teleoperadores asignados al supervisor */
INSERT INTO teleoperador (teleoperador_id, supervisor_id)
VALUES
(@U_TELEOP1, @U_SUPERVISOR),
(@U_TELEOP2, @U_SUPERVISOR);

/* Personas mayores */
SET @P1 := UUID();
SET @P2 := UUID();
SET @P3 := UUID();

INSERT INTO persona_mayor (
  persona_id, nombre, apellido, telefono, fecha_nacimiento, direccion, nivel_dependencia,
  frecuencia_llamadas, hora_preferida, estado, intereses, notas_medicas, teleoperador_asignado
)
VALUES
(@P1, 'María', 'González López', '612345678', '1940-03-15', 'Calle Mayor 45, Barcelona', 'Leve',
 'Semanal', '10:00:00', 'Activo', 'Le gusta la jardinería y hablar de sus nietos', 'Hipertensión controlada con medicación', @U_TELEOP1),

(@P2, 'Antonio', 'Pérez Torres', '611223344', '1938-05-22', 'Av. Cataluña 12, Girona', 'Moderado',
 'Diaria', '09:30:00', 'Activo', 'Aficionado al fútbol y los crucigramas', 'Artrosis leve', @U_TELEOP2),

(@P3, 'Carmen', 'López Díaz', '633445566', '1945-09-10', 'Calle Montserrat 8, Tarragona', 'Grave',
 'Semanal', '11:00:00', 'Activo', 'Le gusta escuchar música clásica', 'Diabética tipo 2 controlada', @U_TELEOP1);

/* Contactos de emergencia */
INSERT INTO contacto_emergencia (persona_id, nombre, relacion, telefono)
VALUES
(@P1, 'Ana González', 'Hija', '654321098'),
(@P2, 'Luis Pérez', 'Hijo', '699887766'),
(@P3, 'Teresa López', 'Hermana', '677554433');

/* Citas (llamadas programadas) */
INSERT INTO cita (persona_id, teleoperador_id, fecha, hora_inicio)
VALUES
(@P1, @U_TELEOP1, '2025-01-15', '10:00:00'),
(@P2, @U_TELEOP2, '2025-01-16', '09:30:00'),
(@P3, @U_TELEOP1, '2025-01-17', '11:00:00');

SET @CITA1 := LAST_INSERT_ID() - 2;
SET @CITA2 := LAST_INSERT_ID() - 1;
SET @CITA3 := LAST_INSERT_ID();

/* Comunicaciones (resultado de llamadas) */
INSERT INTO comunicacion (cita_id, estado_animo, temas_tratados, observaciones, fecha, hora_inicio, hora_fin)
VALUES
(@CITA1, 'Muy Bien', 'Hablamos sobre su jardín y sus nietos.', 'Muy buen ánimo, activa y conversadora.', '2025-01-15', '10:00:00', '10:20:00'),
(@CITA2, 'Normal', 'Comentamos el partido del Barça.', 'Estaba algo distraído pero tranquilo.', '2025-01-16', '09:30:00', '09:50:00');

/* Alerta (ejemplo: no contesta) */
INSERT INTO alerta (cita_id, tipo, descripcion)
VALUES
(@CITA3, 'No contesta', 'No respondió a la llamada programada. Se recomienda contactar con su hermana.');

/* Notificaciones */
INSERT INTO notificacion (tipo, titulo, mensaje, prioridad)
VALUES
('recordatorio', 'Recordatorio', 'No olvides registrar los detalles de tu última llamada.', 'baja'),
('llamada_proxima', 'Llamada Próxima', 'Tienes una llamada programada con María González.', 'media'),
('alerta', 'Posible Incidencia', 'Carmen López no respondió a la llamada prevista.', 'alta');

SET @N1 := (SELECT notificacion_id FROM notificacion WHERE tipo='recordatorio' LIMIT 1);
SET @N2 := (SELECT notificacion_id FROM notificacion WHERE tipo='llamada_proxima' LIMIT 1);
SET @N3 := (SELECT notificacion_id FROM notificacion WHERE tipo='alerta' LIMIT 1);

/* Notificaciones asignadas a teleoperadores */
INSERT INTO notificacion_usuario (usuario_id, notificacion_id, leida)
VALUES
(@U_TELEOP1, @N1, TRUE),
(@U_TELEOP1, @N2, FALSE),
(@U_TELEOP1, @N3, FALSE);

COMMIT;
