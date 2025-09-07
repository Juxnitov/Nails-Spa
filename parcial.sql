-- ==============================================
-- Proyecto: Spa de Uñas - Base de Datos PostgreSQL
-- ==============================================

-- 1. Crear esquema
CREATE SCHEMA spa;
SET search_path TO spa;

-- ==============================================
-- 2. TABLAS
-- ==============================================

-- Clientes
CREATE TABLE clients (
  client_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT UNIQUE,
  email TEXT UNIQUE,
  registered_at TIMESTAMPTZ DEFAULT now()
);

-- Empleados (solo manicuristas)
CREATE TABLE employees (
  employee_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT UNIQUE,
  email TEXT UNIQUE,
  hire_date DATE DEFAULT CURRENT_DATE,
  active BOOLEAN DEFAULT TRUE
);

-- Servicios
CREATE TABLE services (
  service_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Citas
CREATE TABLE appointments (
  appointment_id BIGSERIAL PRIMARY KEY,
  client_id BIGINT NOT NULL REFERENCES clients(client_id),
  employee_id BIGINT NOT NULL REFERENCES employees(employee_id),
  service_id BIGINT NOT NULL REFERENCES services(service_id),
  appointment_date DATE NOT NULL,
  appointment_time TIME NOT NULL,
  status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled','completed','canceled')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ==============================================
-- 3. TRIGGER: máximo 30 citas por día/empleado
-- ==============================================
CREATE OR REPLACE FUNCTION check_daily_limit()
RETURNS TRIGGER AS $$
DECLARE
  citas_count INT;
BEGIN
  -- Contar citas del empleado en esa fecha
  SELECT COUNT(*) INTO citas_count
  FROM appointments
  WHERE employee_id = NEW.employee_id
    AND appointment_date = NEW.appointment_date
    AND status = 'scheduled';

  -- Validar límite
  IF citas_count >= 10 THEN
    RAISE EXCEPTION 'El empleado ya tiene 10 citas para la fecha %', NEW.appointment_date;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Asociar trigger
CREATE TRIGGER trg_daily_limit
BEFORE INSERT ON appointments
FOR EACH ROW
EXECUTE FUNCTION check_daily_limit();

-- ==============================================
-- 4. DATOS DE PRUEBA
-- ==============================================

-- Clientes
INSERT INTO clients (name, phone, email) VALUES
('Laura Pérez', '3001234567', 'laura@example.com'),
('Ana Gómez', '3109876543', 'ana@example.com');

-- Empleados (manicuristas)
INSERT INTO employees (name, phone, email) VALUES
('María Rodríguez', '3015551111', 'maria@example.com'),
('Sofía Hernández', '3024442222', 'sofia@example.com');

-- Servicios
INSERT INTO services (name, description, price) VALUES
('Manicure básico', 'Limpieza y esmalte tradicional', 25000),
('Manicure semipermanente', 'Con esmalte de larga duración', 40000),
('Spa de uñas completo', 'Exfoliación, hidratación y esmaltado', 60000);

-- ==============================================
-- 5. EJEMPLO DE CITA
-- ==============================================

INSERT INTO appointments (client_id, employee_id, service_id, appointment_date, appointment_time)
VALUES (1, 1, 1, '2025-09-05', '10:00');

