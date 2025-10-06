/* ===========================================================
   CuidemJunts - MariaDB
   =========================================================== */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

/* ---------- DROPS en orden seguro ---------- */
DROP TABLE IF EXISTS `usuario_contacto`;
DROP TABLE IF EXISTS `notificacion`;
DROP TABLE IF EXISTS `comunicacion`;
DROP TABLE IF EXISTS `contacto_emergencia`;
DROP TABLE IF EXISTS `usuario`;
DROP TABLE IF EXISTS `teleoperador`;
DROP TABLE IF EXISTS `supervisor`;
DROP TABLE IF EXISTS `grupo`;
DROP TABLE IF EXISTS `trabajador`;

/* ===========================================================
   1) CREATE TABLES (sin FKs)
   =========================================================== */

/* trabajador (supertipo) */
CREATE TABLE `trabajador` (
  `id_trab` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(60) NOT NULL,
  `apellidos` VARCHAR(120) NOT NULL,
  `correo` VARCHAR(120) NOT NULL,
  `contrasena_hash` VARCHAR(100) NOT NULL,
  `tipo` ENUM('teleoperador','supervisor') NOT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_trab`),
  UNIQUE KEY `uq_trab_correo` (`correo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* grupo */
CREATE TABLE `grupo` (
  `id_grup` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(80) NOT NULL,
  `descripcion` VARCHAR(255) DEFAULT NULL,
  `activo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_grup`),
  UNIQUE KEY `uq_grupo_nombre` (`nombre`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* teleoperador (subtipo 1:1 con trabajador) */
CREATE TABLE `teleoperador` (
  `id_trab` INT NOT NULL,
  `nia` VARCHAR(20) NOT NULL,
  `id_grup` INT DEFAULT NULL,          -- Pertenece a un grupo
  `activo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_trab`),
  UNIQUE KEY `uq_teleoperador_nia` (`nia`),
  KEY `idx_teleoperador_grupo` (`id_grup`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* supervisor (subtipo 1:1 con trabajador) */
CREATE TABLE `supervisor` (
  `id_trab` INT NOT NULL,
  `dni` VARCHAR(12) NOT NULL,
  `id_grup` INT DEFAULT NULL,          -- Pertenece a un grupo
  `activo` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (`id_trab`),
  UNIQUE KEY `uq_supervisor_dni` (`dni`),
  KEY `idx_supervisor_grupo` (`id_grup`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* usuario (beneficiario) */
CREATE TABLE `usuario` (
  `dni` VARCHAR(12) NOT NULL,
  `nombre` VARCHAR(60) NOT NULL,
  `apellidos` VARCHAR(120) NOT NULL,
  `informacion` VARCHAR(255) DEFAULT NULL,
  `estado_cuenta` ENUM('activo','suspendido','baja') NOT NULL DEFAULT 'activo',
  `f_nac` DATE DEFAULT NULL,
  `nivel_dependencia` ENUM('ninguna','leve','moderada','severa') NOT NULL DEFAULT 'ninguna',
  `datos_medicos` TEXT,
  `medicacion` TEXT,
  /* extras inspirados en UI (opcionales) */
  `telefono` VARCHAR(20) DEFAULT NULL,
  `direccion` VARCHAR(180) DEFAULT NULL,
  `creado_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`dni`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* contacto_emergencia (puede referenciar a otro usuario o ser externo) */
CREATE TABLE `contacto_emergencia` (
  `id_cont` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(60) NOT NULL,
  `apellidos` VARCHAR(120) NOT NULL,
  `telefono` VARCHAR(20) NOT NULL,
  `relacion` VARCHAR(40) NOT NULL,           -- Hija, Esposo, Vecina…
  `dni_usuario_ref` VARCHAR(12) DEFAULT NULL, -- Si el contacto es un usuario registrado
  PRIMARY KEY (`id_cont`),
  KEY `idx_contacto_usuario_ref` (`dni_usuario_ref`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* relación N:M Usuario ⟷ Contacto de emergencia (ajusta el DER a la realidad de varios contactos) */
CREATE TABLE `usuario_contacto` (
  `dni_usuario` VARCHAR(12) NOT NULL,
  `id_cont` INT NOT NULL,
  PRIMARY KEY (`dni_usuario`,`id_cont`),
  KEY `idx_uc_contacto` (`id_cont`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* comunicacion (la realiza un grupo y va a un usuario) */
CREATE TABLE `comunicacion` (
  `id_com` BIGINT NOT NULL AUTO_INCREMENT,
  `id_grup` INT NOT NULL,                 -- Realiza (Grupo)
  `dni_usuario` VARCHAR(12) NOT NULL,     -- a (Usuario)
  `fecha` DATE NOT NULL,
  `hora` TIME NOT NULL,
  `duracion_min` SMALLINT NOT NULL,
  `resumen` VARCHAR(255) NOT NULL,
  `observaciones` TEXT,
  `estado` ENUM('completada','no_contesto','pendiente','cancelada','programada') NOT NULL DEFAULT 'pendiente',
  PRIMARY KEY (`id_com`),
  KEY `idx_com_grupo` (`id_grup`),
  KEY `idx_com_usuario` (`dni_usuario`),
  KEY `idx_com_fecha` (`fecha`,`hora`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* notificacion (pertenece a un teleoperador) */
CREATE TABLE `notificacion` (
  `id_not` BIGINT NOT NULL AUTO_INCREMENT,
  `id_teleoperador` INT NOT NULL,       -- Tiene (Teleoperador)
  `contenido` VARCHAR(500) NOT NULL,
  `estado` ENUM('sin_leer','leida','archivada','cancelada') NOT NULL DEFAULT 'sin_leer',
  `creada_en` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_not`),
  KEY `idx_not_teleop` (`id_teleoperador`),
  KEY `idx_not_estado` (`estado`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* ===========================================================
   2) FOREIGN KEYS
   =========================================================== */

ALTER TABLE `teleoperador`
  ADD CONSTRAINT `fk_tel_trab` FOREIGN KEY (`id_trab`) REFERENCES `trabajador`(`id_trab`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_tel_grupo` FOREIGN KEY (`id_grup`) REFERENCES `grupo`(`id_grup`);

ALTER TABLE `supervisor`
  ADD CONSTRAINT `fk_sup_trab` FOREIGN KEY (`id_trab`) REFERENCES `trabajador`(`id_trab`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_sup_grupo` FOREIGN KEY (`id_grup`) REFERENCES `grupo`(`id_grup`);

ALTER TABLE `contacto_emergencia`
  ADD CONSTRAINT `fk_contacto_usuario_ref` FOREIGN KEY (`dni_usuario_ref`) REFERENCES `usuario`(`dni`) ON DELETE SET NULL;

ALTER TABLE `usuario_contacto`
  ADD CONSTRAINT `fk_uc_usuario` FOREIGN KEY (`dni_usuario`) REFERENCES `usuario`(`dni`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_uc_contacto` FOREIGN KEY (`id_cont`) REFERENCES `contacto_emergencia`(`id_cont`) ON DELETE CASCADE;

ALTER TABLE `comunicacion`
  ADD CONSTRAINT `fk_com_grupo` FOREIGN KEY (`id_grup`) REFERENCES `grupo`(`id_grup`),
  ADD CONSTRAINT `fk_com_usuario` FOREIGN KEY (`dni_usuario`) REFERENCES `usuario`(`dni`);

ALTER TABLE `notificacion`
  ADD CONSTRAINT `fk_not_teleop` FOREIGN KEY (`id_teleoperador`) REFERENCES `teleoperador`(`id_trab`);

/* ===========================================================
   3) DUMMIES (muchos datos realistas)
   =========================================================== */

START TRANSACTION;

/* Hash de ejemplo (bcrypt de 'temporal123') */
SET @PWD := '$2b$12$oqtmAKfZU0z/VHWlXBjAHOxFT0azngUga6y2H0pWZRVjtIffhRSdy';

/* Grupos */
INSERT INTO grupo (nombre, descripcion, activo) VALUES
('Atención Mañanas','Turno 08:00–15:00',TRUE),
('Atención Tardes','Turno 15:00–22:00',TRUE),
('Atención Noches','Turno 22:00–08:00',TRUE),
('Seguimiento Crónicos','Casos con dependencia moderada/severa',TRUE);

SET @G_MAN := (SELECT id_grup FROM grupo WHERE nombre='Atención Mañanas');
SET @G_TAR := (SELECT id_grup FROM grupo WHERE nombre='Atención Tardes');
SET @G_NOC := (SELECT id_grup FROM grupo WHERE nombre='Atención Noches');
SET @G_CRO := (SELECT id_grup FROM grupo WHERE nombre='Seguimiento Crónicos');

/* Trabajadores (supertipo) */
INSERT INTO trabajador (nombre,apellidos,correo,contrasena_hash,tipo) VALUES
('Sofía','Martín Prado','sofia.martin@cuidem.local',@PWD,'supervisor'),
('Javier','Rovira Díaz','javier.rovira@cuidem.local',@PWD,'supervisor'),
('Laura','Gómez Vera','laura.gomez@cuidem.local',@PWD,'teleoperador'),
('Carlos','Navas Gil','carlos.navas@cuidem.local',@PWD,'teleoperador'),
('Noa','Benítez Pardo','noa.benitez@cuidem.local',@PWD,'teleoperador'),
('Pablo','Rey Serrano','pablo.rey@cuidem.local',@PWD,'teleoperador'),
('Inés','Campos León','ines.campos@cuidem.local',@PWD,'teleoperador'),
('Hugo','Santos Ibarra','hugo.santos@cuidem.local',@PWD,'teleoperador');

SET @SUP1 := (SELECT id_trab FROM trabajador WHERE correo='sofia.martin@cuidem.local');
SET @SUP2 := (SELECT id_trab FROM trabajador WHERE correo='javier.rovira@cuidem.local');
SET @TEL1 := (SELECT id_trab FROM trabajador WHERE correo='laura.gomez@cuidem.local');
SET @TEL2 := (SELECT id_trab FROM trabajador WHERE correo='carlos.navas@cuidem.local');
SET @TEL3 := (SELECT id_trab FROM trabajador WHERE correo='noa.benitez@cuidem.local');
SET @TEL4 := (SELECT id_trab FROM trabajador WHERE correo='pablo.rey@cuidem.local');
SET @TEL5 := (SELECT id_trab FROM trabajador WHERE correo='ines.campos@cuidem.local');
SET @TEL6 := (SELECT id_trab FROM trabajador WHERE correo='hugo.santos@cuidem.local');

/* Subtipos */
INSERT INTO supervisor (id_trab,dni,id_grup,activo) VALUES
(@SUP1,'49223311X',@G_MAN,TRUE),
(@SUP2,'12345678Z',@G_TAR,TRUE);

INSERT INTO teleoperador (id_trab,nia,id_grup,activo) VALUES
(@TEL1,'NIA0001',@G_MAN,TRUE),
(@TEL2,'NIA0002',@G_MAN,TRUE),
(@TEL3,'NIA0003',@G_TAR,TRUE),
(@TEL4,'NIA0004',@G_TAR,TRUE),
(@TEL5,'NIA0005',@G_NOC,TRUE),
(@TEL6,'NIA0006',@G_CRO,TRUE);

/* Usuarios (beneficiarios) */
INSERT INTO usuario
(dni,nombre,apellidos,informacion,estado_cuenta,f_nac,nivel_dependencia,datos_medicos,medicacion,telefono,direccion) VALUES
('11111111A','Carmen','Rodríguez Sanz','Vive sola, pulsera SOS','activo','1945-11-30','leve','HTA y artrosis','Lisinopril 10mg','634567890','Plaza España 8, Barcelona'),
('22222222B','José','Martínez Ruiz','Acompañamiento tardes','activo','1938-07-22','moderada','DM2 controlada','Metformina 850mg','687654321','Av. Diagonal 123, Barcelona'),
('33333333C','María','González López','Seguimiento telefónico semanal','activo','1942-01-15','ninguna',NULL,NULL,'612345678','C/ Alcalá 15, Madrid'),
('44444444D','Dolores','Quintana Lara','Refiere soledad no deseada','activo','1950-07-18','leve',NULL,NULL,'611223344','C/ Mayor 4, Zaragoza'),
('55555555E','Eduardo','Iglesias Vela','Alta reciente por caída','activo','1939-01-30','moderada','Frágil, caídas previas','Vitamina D','699112233','C/ Real 22, Sevilla'),
('66666666F','Felisa','Maroto Pina','Valorar derivación a TS','suspendido','1946-03-12','ninguna','Dolor lumbar','Paracetamol','633998877','C/ Sol 9, Valencia'),
('77777777G','Antonio','López García','Vive con su esposa Carmen','activo','1943-02-02','severa','EPOC severa','Broncodilatador PRN','678112233','Plaza España 8, Barcelona'),
('88888888H','Laura','Rodríguez Pérez','Hija de Carmen','activo','1972-06-10','ninguna',NULL,NULL,'645678901','C/ Marina 12, Barcelona'),
('99999999J','Pedro','Martínez Gómez','Hijo de José','activo','1970-04-04','ninguna',NULL,NULL,'698765432','C/ Bailén 30, Barcelona');

/* Contactos de emergencia:
   - Algunos referencian usuarios existentes (parejas/hijos)
   - Otros son externos (vecina, etc.) */
INSERT INTO contacto_emergencia (nombre,apellidos,telefono,relacion,dni_usuario_ref) VALUES
('Laura','Rodríguez Pérez','645678901','Hija','88888888H'),     -- también es usuario
('Antonio','López García','678112233','Esposo','77777777G'),     -- también es usuario
('Pedro','Martínez Gómez','698765432','Hijo','99999999J'),       -- también es usuario
('Marta','Vega Ríos','600400400','Vecina',NULL),
('Carmen','Ruiz Díaz','612398765','Hija',NULL);

/* Enlaces Usuario ↔ Contacto (múltiples por usuario) */
-- Carmen: su hija Laura y su esposo Antonio (que también es usuario)
INSERT INTO usuario_contacto (dni_usuario,id_cont)
SELECT '11111111A', id_cont FROM contacto_emergencia WHERE (telefono IN ('645678901','678112233'));

-- José: sus hijos Pedro y (externa) Carmen Ruiz
INSERT INTO usuario_contacto (dni_usuario,id_cont)
SELECT '22222222B', id_cont FROM contacto_emergencia WHERE (telefono IN ('698765432','612398765'));

-- Eduardo: vecina Marta
INSERT INTO usuario_contacto (dni_usuario,id_cont)
SELECT '55555555E', id_cont FROM contacto_emergencia WHERE telefono='600400400';

-- Antonio (pareja de Carmen): su contacto es Carmen (ya usuario) y su hija Laura
INSERT INTO contacto_emergencia (nombre,apellidos,telefono,relacion,dni_usuario_ref) VALUES
('Carmen','Rodríguez Sanz','634567890','Esposa','11111111A');
SET @CONT_CARMEN := LAST_INSERT_ID();
INSERT INTO usuario_contacto (dni_usuario,id_cont) VALUES
('77777777G', @CONT_CARMEN);
INSERT INTO usuario_contacto (dni_usuario,id_cont)
SELECT '77777777G', id_cont FROM contacto_emergencia WHERE telefono='645678901';

/* Comunicaciones (como en las capturas: Completada / No contestó / Pendiente) */
INSERT INTO comunicacion
(id_grup,dni_usuario,fecha,hora,duracion_min,resumen,observaciones,estado) VALUES
(@G_MAN,'33333333C', '2025-01-15','11:05:00',20,'Seguimiento semanal','Conversación fluida. Anima a continuar paseos.','completada'),
(@G_MAN,'22222222B', '2025-01-14','10:20:00',12,'Intento de llamada','No respondió, se reintenta mañana.','no_contesto'),
(@G_TAR,'33333333C', '2025-01-13','18:10:00',16,'Recordatorio de cita médica','Confirma asistencia al centro de salud.','completada'),
(@G_TAR,'11111111A', CURDATE(),'16:30:00',9,'Consulta sobre medicación','Aclara posología nocturna.','completada'),
(@G_NOC,'55555555E', DATE_SUB(CURDATE(),INTERVAL 1 DAY),'23:50:00',10,'Verificación nocturna','Descanso adecuado, sin incidencias.','completada'),
(@G_CRO,'77777777G', CURDATE(),'12:40:00',22,'Plan respiratorio revisado','Se pauta control de inhalador.','pendiente'),
(@G_MAN,'66666666F', CURDATE(),'11:40:00',14,'Derivación a Trabajo Social','Se agenda valoración.','programada'),
(@G_TAR,'22222222B', CURDATE(),'17:25:00',8,'Revisión glucemias','Lecturas correctas tras comida.','completada'),
(@G_MAN,'11111111A', DATE_SUB(CURDATE(),INTERVAL 2 DAY),'09:35:00',7,'Aviso sensor movimiento','Falsa alarma (gato).','completada'),
(@G_TAR,'44444444D', CURDATE(),'19:05:00',30,'Se siente triste','Se propone grupo de conversación.','pendiente');

/* Más comunicaciones para volumen */
INSERT INTO comunicacion
(id_grup,dni_usuario,fecha,hora,duracion_min,resumen,observaciones,estado)
SELECT
  CASE (n % 4) WHEN 0 THEN @G_MAN WHEN 1 THEN @G_TAR WHEN 2 THEN @G_NOC ELSE @G_CRO END,
  CASE (n % 7)
    WHEN 0 THEN '11111111A'
    WHEN 1 THEN '22222222B'
    WHEN 2 THEN '33333333C'
    WHEN 3 THEN '44444444D'
    WHEN 4 THEN '55555555E'
    WHEN 5 THEN '66666666F'
    ELSE '77777777G' END,
  DATE_SUB(CURDATE(), INTERVAL (n % 18) DAY),
  SEC_TO_TIME(8*3600 + (n % 840) * 60),
  5 + (n % 26),
  CONCAT('Seguimiento rutinario #', n),
  'Sin observaciones destacables.',
  CASE (n % 3) WHEN 0 THEN 'completada' WHEN 1 THEN 'pendiente' ELSE 'no_contesto' END
FROM (
  SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL
  SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL
  SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL
  SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
) t;

/* Notificaciones (estados: sin_leer, leida, archivada, cancelada) */
INSERT INTO notificacion (id_teleoperador,contenido,estado) VALUES
(@TEL1,'Tienes 3 llamadas programadas para hoy a partir de las 10:00.','sin_leer'),
(@TEL1,'La incidencia de centralita quedó resuelta.','leida'),
(@TEL2,'Recuerda registrar la comunicación con José Martínez.','sin_leer'),
(@TEL3,'Nueva pauta de comunicación empática — viernes 12:00.','leida'),
(@TEL4,'Caso escalado a psicología comunitaria.','archivada'),
(@TEL5,'Se cancela la formación de esta tarde.','cancelada'),
(@TEL6,'Actualiza el resumen de la llamada de Eduardo.','sin_leer');

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;

/* ==================== FIN CuidemJunts.sql ==================== */