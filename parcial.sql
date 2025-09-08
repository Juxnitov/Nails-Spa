-- ==============================================
-- Proyecto: Tienda de Juegos Digitales - Base de Datos PostgreSQL
-- ==============================================

-- =====================================
-- 1. Creación de Roles según requisitos
-- =====================================

-- Rol administrador (superusuario personalizado, no confundir con postgres)
-- LOGIN: significa que puede iniciar sesión.
-- PASSWORD: clave del rol.
-- SUPERUSER: tendrá todos los privilegios, pero es un usuario distinto de 'postgres'.
CREATE ROLE administrador LOGIN PASSWORD 'admin123' SUPERUSER;

-- Rol empleados
-- LOGIN: puede iniciar sesión.
-- PASSWORD: clave asignada.
-- NOCREATEDB: no puede crear nuevas bases de datos.
-- NOCREATEROLE: no puede crear ni administrar otros roles.
-- Este rol podrá modificar (UPDATE) y eliminar (DELETE) registros, pero no insertar (INSERT).
CREATE ROLE empleado LOGIN PASSWORD 'empleado123' NOCREATEDB NOCREATEROLE;

-- Rol clientes
-- LOGIN: puede iniciar sesión.
-- PASSWORD: clave asignada.
-- NOCREATEDB: no puede crear bases de datos.
-- NOCREATEROLE: no puede crear ni administrar otros roles.
-- Este rol solo podrá leer datos (SELECT).
CREATE ROLE cliente LOGIN PASSWORD 'cliente123' NOCREATEDB NOCREATEROLE;

-- =====================================
-- Asignación de privilegios (aplicados al esquema TIENDA)
-- =====================================

-- Permisos para clientes: solo SELECT en todas las tablas de TIENDA
GRANT SELECT ON ALL TABLES IN SCHEMA tienda TO cliente;

-- Permisos para empleados: UPDATE y DELETE en todas las tablas de TIENDA
GRANT UPDATE, DELETE ON ALL TABLES IN SCHEMA tienda TO empleado;

-- Permisos para admin: todo en todas las tablas de TIENDA
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA tienda TO admin;

-- =====================================
-- Configuración de privilegios por defecto para tablas futuras
-- Así, cuando se creen nuevas tablas en el esquema TIENDA,
-- automáticamente heredarán los permisos definidos aquí.
-- =====================================

ALTER DEFAULT PRIVILEGES IN SCHEMA tienda
GRANT SELECT ON TABLES TO cliente;

ALTER DEFAULT PRIVILEGES IN SCHEMA tienda
GRANT UPDATE, DELETE ON TABLES TO empleado;

ALTER DEFAULT PRIVILEGES IN SCHEMA tienda
GRANT ALL PRIVILEGES ON TABLES TO admin;

-- =====================================
-- Cómo probar los roles en psql
-- =====================================
-- 1. Conectarse como cliente:
--    psql -U cliente -d basedatos
--    Luego intenta hacer un SELECT: debería funcionar.
--    Si intentas un INSERT/UPDATE/DELETE: dará error de permisos.

-- 2. Conectarse como empleado:
--    psql -U empleado -d basedatos
--    UPDATE o DELETE deberían funcionar.
--    INSERT debería dar error de permisos.

-- 3. Conectarse como admin:
--    psql -U admin -d basedatos
--    Tiene todos los permisos (como superusuario).

-- ==============================================
-- 2. TABLAS
-- ==============================================

SELECT * FROM juegos;

-- Usuarios del sistema (clientes que compran juegos)
CREATE TABLE usuarios (
  usuario_id SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  registrado_en TIMESTAMP DEFAULT now()
);

-- Juegos disponibles en la tienda
CREATE TABLE juegos (
  juego_id SERIAL PRIMARY KEY,
  titulo TEXT NOT NULL,
  descripcion TEXT,
  precio DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
  stock INT DEFAULT 100 CHECK (stock >= 0),
  activo BOOLEAN DEFAULT TRUE,
  creado_en TIMESTAMP DEFAULT now()
);

-- Pedidos (ventas de juegos)
CREATE TABLE pedidos (
  pedido_id SERIAL PRIMARY KEY,
  usuario_id INT NOT NULL REFERENCES usuarios(usuario_id),
  juego_id INT NOT NULL REFERENCES juegos(juego_id),
  cantidad INT NOT NULL CHECK (cantidad > 0),
  total DECIMAL(12,2) NOT NULL CHECK (total >= 0),
  fecha TIMESTAMP DEFAULT now()
);

-- Cancelaciones (equivalente a devoluciones)
CREATE TABLE cancelaciones (
  cancel_id SERIAL PRIMARY KEY,
  pedido_id INT NOT NULL REFERENCES pedidos(pedido_id),
  motivo TEXT,
  fecha TIMESTAMP DEFAULT now()
);

-- ==============================================
-- 3. PROCEDURE: Registrar un pedido
-- ==============================================
CREATE OR REPLACE PROCEDURE registrar_pedido(p_usuario INT, p_juego INT, p_cantidad INT)
LANGUAGE plpgsql AS $$
DECLARE
  v_precio DECIMAL(12,2);
BEGIN
  SELECT precio INTO v_precio FROM juegos WHERE juego_id = p_juego;
  INSERT INTO pedidos (usuario_id, juego_id, cantidad, total)
  VALUES (p_usuario, p_juego, p_cantidad, v_precio * p_cantidad);
END;
$$;

-- ==============================================
-- 4. FUNCTION: Ventas totales
-- ==============================================
CREATE OR REPLACE FUNCTION ventas_totales()
RETURNS DECIMAL(12,2) AS $$
DECLARE
  v_total DECIMAL(12,2);
BEGIN
  SELECT COALESCE(SUM(total),0) INTO v_total FROM pedidos;
  RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- 5. TRIGGER: Actualizar stock
-- ==============================================
CREATE OR REPLACE FUNCTION actualizar_stock()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE juegos
  SET stock = stock - NEW.cantidad
  WHERE juego_id = NEW.juego_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_stock
AFTER INSERT ON pedidos
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock();

-- ==============================================
-- 6. DATOS DE PRUEBA
-- ==============================================

INSERT INTO usuarios (nombre, email, password) VALUES
('Carlos Pérez', 'carlos@example.com', '1234'),
('Lucía Gómez', 'lucia@example.com', 'abcd');

INSERT INTO juegos (titulo, descripcion, precio, stock) VALUES
('Elden Ring', 'Juego RPG de mundo abierto', 250000, 10),
('Minecraft', 'Sandbox de construcción y aventura', 120000, 20),
('FIFA 25', 'Simulación de fútbol', 200000, 15);

-- Ejemplo de pedido
--CALL registrar_pedido(1, 2, 1);
SELECT ventas_totales();
