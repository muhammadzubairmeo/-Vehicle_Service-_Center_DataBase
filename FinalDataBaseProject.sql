DROP DATABASE IF EXISTS vehicle_service_center;
CREATE DATABASE vehicle_service_center
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE vehicle_service_center;
-- 1.1 Customers
CREATE TABLE customers (
  customer_id   INT          UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name     VARCHAR(100) NOT NULL,
  phone         VARCHAR(20)  NOT NULL UNIQUE,
  email         VARCHAR(120)          UNIQUE,
  address       VARCHAR(255),
  city          VARCHAR(60),
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 1.2 Vehicle Makes  (lookup — avoids repeating strings)
CREATE TABLE vehicle_makes (
  make_id   SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  make_name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 1.3 Vehicle Models
CREATE TABLE vehicle_models (
  model_id   SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  make_id    SMALLINT UNSIGNED NOT NULL,
  model_name VARCHAR(60)       NOT NULL,
  UNIQUE KEY uq_make_model (make_id, model_name),
  CONSTRAINT fk_model_make FOREIGN KEY (make_id)
    REFERENCES vehicle_makes(make_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 1.4 Vehicles
CREATE TABLE vehicles (
  vehicle_id    INT          UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id   INT          UNSIGNED NOT NULL,
  model_id      SMALLINT     UNSIGNED NOT NULL,
  year          YEAR         NOT NULL,
  reg_number    VARCHAR(20)  NOT NULL UNIQUE,
  color         VARCHAR(30),
  engine_cc     SMALLINT     UNSIGNED,
  mileage_km    INT          UNSIGNED DEFAULT 0,
  CONSTRAINT fk_vehicle_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id) ON DELETE CASCADE,
  CONSTRAINT fk_vehicle_model FOREIGN KEY (model_id)
    REFERENCES vehicle_models(model_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 1.5 Employees (Mechanics / Service Advisors)
CREATE TABLE employees (
  employee_id  INT         UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name    VARCHAR(100) NOT NULL,
  role         ENUM('Mechanic','Service Advisor','Supervisor','Parts Manager') NOT NULL,
  phone        VARCHAR(20),
  hire_date    DATE        NOT NULL,
  salary       DECIMAL(10,2)
) ENGINE=InnoDB;

-- 1.6 Service Types (catalogue)
CREATE TABLE service_types (
  service_type_id   SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  service_name      VARCHAR(100) NOT NULL UNIQUE,
  standard_duration_hrs DECIMAL(4,1) NOT NULL DEFAULT 1.0,
  base_labor_cost   DECIMAL(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB;

-- 1.7 Parts / Inventory
CREATE TABLE parts (
  part_id       INT          UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  part_name     VARCHAR(120) NOT NULL,
  part_number   VARCHAR(50)  NOT NULL UNIQUE,
  brand         VARCHAR(60),
  unit          VARCHAR(20)  NOT NULL DEFAULT 'piece',
  cost_price    DECIMAL(10,2) NOT NULL,
  selling_price DECIMAL(10,2) NOT NULL,
  stock_qty     INT          UNSIGNED NOT NULL DEFAULT 0,
  reorder_level INT          UNSIGNED NOT NULL DEFAULT 5
) ENGINE=InnoDB;

-- 1.8 Job Cards (header)
CREATE TABLE job_cards (
  job_id          INT          UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  vehicle_id      INT          UNSIGNED NOT NULL,
  advisor_id      INT          UNSIGNED NOT NULL,
  date_in         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  date_out        DATETIME,
  status          ENUM('Open','In Progress','Completed','Cancelled') NOT NULL DEFAULT 'Open',
  customer_complaint TEXT,
  total_labor     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  total_parts     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  discount        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  grand_total     DECIMAL(10,2) GENERATED ALWAYS AS
                  (total_labor + total_parts - discount) STORED,
  CONSTRAINT fk_jc_vehicle  FOREIGN KEY (vehicle_id)  REFERENCES vehicles(vehicle_id)  ON DELETE CASCADE,
  CONSTRAINT fk_jc_advisor  FOREIGN KEY (advisor_id)  REFERENCES employees(employee_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 1.9 Job Services (which services done on which job card)
CREATE TABLE job_services (
  job_service_id  INT          UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  job_id          INT          UNSIGNED NOT NULL,
  service_type_id SMALLINT     UNSIGNED NOT NULL,
  mechanic_id     INT          UNSIGNED NOT NULL,
  labor_cost      DECIMAL(10,2) NOT NULL,
  notes           VARCHAR(255),
  CONSTRAINT fk_js_job      FOREIGN KEY (job_id)          REFERENCES job_cards(job_id)         ON DELETE CASCADE,
  CONSTRAINT fk_js_service  FOREIGN KEY (service_type_id) REFERENCES service_types(service_type_id) ON DELETE RESTRICT,
  CONSTRAINT fk_js_mechanic FOREIGN KEY (mechanic_id)     REFERENCES employees(employee_id)    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 1.10 Job Parts (parts used on a job card)
CREATE TABLE job_parts (
  job_part_id   INT          UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  job_id        INT          UNSIGNED NOT NULL,
  part_id       INT          UNSIGNED NOT NULL,
  qty_used      INT          UNSIGNED NOT NULL DEFAULT 1,
  unit_price    DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_jp_job  FOREIGN KEY (job_id)  REFERENCES job_cards(job_id) ON DELETE CASCADE,
  CONSTRAINT fk_jp_part FOREIGN KEY (part_id) REFERENCES parts(part_id)    ON DELETE RESTRICT
) ENGINE=InnoDB;
-- 2. INDEXES  (beyond PKs/FKs — for fast lookups)
CREATE INDEX idx_vehicles_reg       ON vehicles(reg_number);
CREATE INDEX idx_vehicles_customer  ON vehicles(customer_id);
CREATE INDEX idx_job_cards_status   ON job_cards(status);
CREATE INDEX idx_job_cards_date_in  ON job_cards(date_in);
CREATE INDEX idx_parts_stock        ON parts(stock_qty);
CREATE INDEX idx_parts_number       ON parts(part_number);
CREATE INDEX idx_customers_phone    ON customers(phone);
CREATE INDEX idx_job_services_job   ON job_services(job_id);
-- 3. SAMPLE DATA
-- 3.1 Vehicle Makes
INSERT INTO vehicle_makes (make_name) VALUES
('Toyota'),('Honda'),('Suzuki'),('Hyundai'),('KIA'),
('Nissan'),('Mitsubishi'),('Daihatsu'),('Changan'),('DFSK');

-- 3.2 Vehicle Models
INSERT INTO vehicle_models (make_id, model_name) VALUES
(1,'Corolla'),(1,'Yaris'),(1,'Hilux'),
(2,'Civic'),(2,'City'),(2,'BR-V'),
(3,'Alto'),(3,'Cultus'),(3,'Swift'),
(4,'Tucson'),(4,'Sonata'),
(5,'Sportage'),(5,'Picanto'),
(6,'Sunny'),(6,'Dayz'),
(7,'Lancer'),(7,'Pajero'),
(8,'Cuore'),(8,'Move'),
(9,'Alsvin'),(9,'M9'),
(10,'Glory 580'),(10,'C37');

-- 3.3 Customers
INSERT INTO customers (full_name, phone, email, address, city) VALUES
('Ahmed Raza',        '0300-1234567', 'ahmed.raza@gmail.com',    'House 12, Gulberg', 'Lahore'),
('Sara Khan',         '0301-2345678', 'sara.khan@yahoo.com',     'Block C, DHA',      'Lahore'),
('Bilal Mahmood',     '0302-3456789', 'bilal.m@outlook.com',     'Street 7, Model Town','Lahore'),
('Fatima Noor',       '0303-4567890', 'fatima.n@gmail.com',      'Phase 5, Bahria',   'Rawalpindi'),
('Usman Tariq',       '0304-5678901', 'usman.t@gmail.com',       'Satellite Town',    'Gujranwala'),
('Hina Malik',        '0305-6789012', 'hina.m@hotmail.com',      'Cantt Area',        'Multan'),
('Zeeshan Iqbal',     '0306-7890123', 'zeeshan.i@gmail.com',     'Johar Town',        'Lahore'),
('Nadia Hussain',     '0307-8901234', 'nadia.h@gmail.com',       'Block A, PECHS',    'Karachi'),
('Tariq Butt',        '0308-9012345', 'tariq.b@gmail.com',       'Nazimabad',         'Karachi'),
('Amna Sheikh',       '0309-0123456', 'amna.s@yahoo.com',        'F-10 Markaz',       'Islamabad'),
('Kamran Ali',        '0310-1122334', 'kamran.a@gmail.com',      'G-11/2',            'Islamabad'),
('Raza Ul Haq',       '0311-2233445', 'raza.h@gmail.com',        'Township',          'Lahore'),
('Sobia Anwar',       '0312-3344556', 'sobia.a@gmail.com',       'Gulshan Iqbal',     'Karachi'),
('Faisal Karim',      '0313-4455667', 'faisal.k@gmail.com',      'Model Colony',      'Karachi'),
('Asma Javed',        '0314-5566778', 'asma.j@yahoo.com',        'Hayatabad',         'Peshawar'),
('Irfan Ul Islam',    '0315-6677889', 'irfan.i@gmail.com',       'University Road',   'Peshawar'),
('Mehwish Saleem',    '0316-7788990', 'mehwish.s@gmail.com',     'Gulistan Colony',   'Faisalabad'),
('Shoaib Rana',       '0317-8899001', 'shoaib.r@gmail.com',      'Samanabad',         'Faisalabad'),
('Uzma Bashir',       '0318-9900112', 'uzma.b@hotmail.com',      'Wapda Town',        'Multan'),
('Naeem Akhtar',      '0319-0011223', 'naeem.a@gmail.com',       'Civil Lines',       'Quetta'),
('Rabia Farooq',      '0320-1122335', 'rabia.f@gmail.com',       'Satellite Town',    'Rawalpindi'),
('Haroon Rashid',     '0321-2233446', 'haroon.r@gmail.com',      'Lalkurti',          'Rawalpindi'),
('Shazia Parveen',    '0322-3344557', 'shazia.p@gmail.com',      'Allama Iqbal Town', 'Lahore'),
('Danish Saeed',      '0323-4455668', 'danish.s@gmail.com',      'Barkat Market',     'Lahore'),
('Lubna Waheed',      '0324-5566779', 'lubna.w@yahoo.com',       'Khyaban-e-Amin',    'Lahore');

-- 3.4 Employees
INSERT INTO employees (full_name, role, phone, hire_date, salary) VALUES
('Touseef Subhani',   'Supervisor',        '0300-9876543', '2018-03-01', 85000.00),
('Abubakar Ilyas',    'Service Advisor',   '0301-8765432', '2019-06-15', 55000.00),
('Adil Shahzad',      'Mechanic',          '0302-7654321', '2020-01-10', 42000.00),
('Zubair Saeed',      'Mechanic',          '0303-6543210', '2020-01-10', 42000.00),
('Noman Farooqi',     'Parts Manager',     '0304-5432109', '2019-09-01', 50000.00),
('Kashif Mehmood',    'Mechanic',          '0305-4321098', '2021-03-20', 40000.00),
('Rizwan Shah',       'Mechanic',          '0306-3210987', '2021-07-05', 40000.00),
('Sana Mirza',        'Service Advisor',   '0307-2109876', '2022-02-14', 52000.00),
('Hamza Qureshi',     'Mechanic',          '0308-1098765', '2022-08-01', 38000.00),
('Imran Haider',      'Supervisor',        '0309-0987654', '2017-11-11', 90000.00);

-- 3.5 Service Types
INSERT INTO service_types (service_name, standard_duration_hrs, base_labor_cost) VALUES
('Engine Oil Change',          0.5,   800.00),
('Oil Filter Replacement',     0.5,   400.00),
('Air Filter Replacement',     0.5,   350.00),
('Tire Rotation',              1.0,   600.00),
('Brake Pad Replacement',      2.0,  2500.00),
('Battery Replacement',        0.5,   500.00),
('Wheel Alignment',            1.0,  1200.00),
('Wheel Balancing',            1.0,   800.00),
('Full Service (Major)',        5.0,  8000.00),
('AC Gas Recharge',            2.0,  3500.00),
('Spark Plug Replacement',     1.5,  1800.00),
('Coolant Flush',              1.0,  1500.00),
('Gearbox Service',            4.0,  6000.00),
('Suspension Inspection',      1.5,  2000.00),
('Engine Diagnostic Scan',     1.0,  1500.00);

-- 3.6 Parts
INSERT INTO parts (part_name, part_number, brand, unit, cost_price, selling_price, stock_qty, reorder_level) VALUES
('Engine Oil 1L (5W-30)',      'OIL-5W30-1L',  'Shell',     'litre',  800.00,  1050.00, 120,  20),
('Engine Oil 1L (10W-40)',     'OIL-10W40-1L', 'Castrol',   'litre',  750.00,   980.00,  95,  20),
('Oil Filter (Toyota)',        'OLF-TOY-001',  'Toyota',    'piece',  450.00,   650.00,  60,  10),
('Oil Filter (Honda)',         'OLF-HON-001',  'Honda',     'piece',  420.00,   600.00,  55,  10),
('Air Filter (Universal)',     'ARF-UNI-001',  'Bosch',     'piece',  800.00,  1100.00,  40,   8),
('Brake Pad Set (Front)',      'BRK-FRT-001',  'TRW',       'set',   2200.00,  3200.00,  25,   5),
('Brake Pad Set (Rear)',       'BRK-RER-001',  'TRW',       'set',   1800.00,  2600.00,  20,   5),
('Car Battery 45Ah',           'BAT-45AH-001', 'Exide',     'piece', 8000.00, 10500.00,  15,   3),
('Car Battery 65Ah',           'BAT-65AH-001', 'AGS',       'piece', 9500.00, 12500.00,  12,   3),
('Spark Plug (NGK)',           'SPK-NGK-001',  'NGK',       'piece',  350.00,   520.00,  80,  15),
('Coolant 1L',                 'CLT-1L-001',   'Zerex',     'litre',  600.00,   850.00,  50,  10),
('AC Refrigerant R134a 500g',  'ACR-134-500',  'Honeywell', 'can',   2200.00,  3200.00,  18,   5),
('Wiper Blade (Pair)',         'WPR-PR-001',   'Bosch',     'pair',  1200.00,  1700.00,  30,   8),
('Fuel Filter',                'FUF-001',      'Bosch',     'piece',  900.00,  1300.00,  35,   8),
('Cabin Air Filter',           'CAF-001',      'Mann',      'piece',  700.00,  1000.00,  28,   6),
('Gear Oil 1L (75W-90)',       'GRO-75W90-1L', 'Mobil',     'litre',  950.00,  1300.00,  40,  10),
('Timing Belt Kit',            'TBK-001',      'Gates',     'kit',   4500.00,  6500.00,  10,   3),
('Serpentine Belt',            'SBL-001',      'Dayco',     'piece', 1800.00,  2600.00,  14,   4),
('Suspension Bush Kit',        'SBK-001',      'Mevotech',  'kit',   3200.00,  4800.00,   8,   3),
('Radiator Hose Set',          'RHS-001',      'Gates',     'set',   1500.00,  2200.00,  12,   4),
('Throttle Body Cleaner 500ml','TBC-500',      'WD-40',     'can',    450.00,   700.00,  45,  10),
('Power Steering Fluid 1L',   'PSF-1L-001',   'Dexron',    'litre',  700.00,  1000.00,  30,   8),
('Brake Fluid DOT4 500ml',    'BRF-DOT4-500', 'Bosch',     'can',    800.00,  1150.00,  22,   6),
('Transmission Filter Kit',   'TFK-001',      'WIX',       'kit',   2800.00,  4000.00,   9,   3),
('Engine Mount (Front)',       'ENM-FRT-001',  'Febest',    'piece', 2500.00,  3800.00,   7,   2);

-- 3.7 Vehicles
INSERT INTO vehicles (customer_id, model_id, year, reg_number, color, engine_cc, mileage_km) VALUES
(1,  1, 2019, 'LHR-2019-001', 'White',       1800, 45000),
(2,  4, 2021, 'LHR-2021-002', 'Black',       1500, 22000),
(3,  7, 2018, 'LHR-2018-003', 'Silver',       660, 80000),
(4,  10,2020, 'RWP-2020-004', 'Red',         2000, 38000),
(5,  12,2022, 'GRW-2022-005', 'White',       2000, 15000),
(6,  8, 2017, 'MLT-2017-006', 'Blue',         800, 92000),
(7,  2, 2020, 'LHR-2020-007', 'Grey',        1000, 50000),
(8,  5, 2019, 'KHI-2019-008', 'Pearl White', 1200, 60000),
(9,  9, 2021, 'KHI-2021-009', 'Red',        1200, 20000),
(10, 11,2018, 'ISB-2018-010', 'Black',       2400, 75000),
(11, 14,2016, 'ISB-2016-011', 'White',       1300, 110000),
(12, 16,2015, 'LHR-2015-012', 'Silver',      1300, 130000),
(13, 20,2023, 'KHI-2023-013', 'White',       1400,  5000),
(14, 6, 2018, 'KHI-2018-014', 'Blue',        1500, 68000),
(15, 3, 2020, 'PSH-2020-015', 'White',       2700, 55000),
(16, 13,2021, 'PSH-2021-016', 'Red',          998, 18000),
(17, 17,2019, 'FSD-2019-017', 'Black',       2400, 72000),
(18, 18,2017, 'FSD-2017-018', 'Silver',       660, 85000),
(19, 8, 2022, 'MLT-2022-019', 'White',        800, 12000),
(20, 23,2021, 'QTA-2021-020', 'Grey',        1500, 33000),
(21, 21,2020, 'RWP-2020-021', 'Black',       2000, 41000),
(22, 4, 2022, 'RWP-2022-022', 'White',       1500, 17000),
(23, 1, 2017, 'LHR-2017-023', 'Silver',      1800, 98000),
(24, 5, 2019, 'LHR-2019-024', 'Blue',        1200, 57000),
(25, 2, 2023, 'LHR-2023-025', 'Red',         1000,  3000);

-- 3.8 Job Cards
INSERT INTO job_cards (vehicle_id, advisor_id, date_in, date_out, status, customer_complaint, total_labor, total_parts, discount) VALUES
( 1, 2, '2024-01-10 09:00', '2024-01-10 11:00', 'Completed', 'Engine oil change due',                          800.00,  1050.00,  0.00),
( 2, 2, '2024-01-12 10:00', '2024-01-12 12:30', 'Completed', 'Squeaky brakes',                                2500.00,  3200.00, 200.00),
( 3, 8, '2024-01-15 08:30', '2024-01-15 13:00', 'Completed', 'Full service required',                         8000.00,  5400.00, 500.00),
( 4, 2, '2024-01-18 11:00', '2024-01-18 13:00', 'Completed', 'AC not cooling',                                3500.00,  3200.00,  0.00),
( 5, 8, '2024-01-22 09:30', '2024-01-22 10:30', 'Completed', 'Tire rotation + balancing',                    1400.00,     0.00,  0.00),
( 6, 2, '2024-02-01 10:00', '2024-02-01 12:00', 'Completed', 'Battery dead',                                   500.00, 10500.00,  0.00),
( 7, 8, '2024-02-05 09:00', '2024-02-05 10:00', 'Completed', 'Oil change + air filter',                       1150.00,  1700.00,  0.00),
( 8, 2, '2024-02-10 14:00', '2024-02-10 16:00', 'Completed', 'Wheel alignment requested',                    1200.00,     0.00,  0.00),
( 9, 8, '2024-02-14 09:00', '2024-02-14 10:30', 'Completed', 'Spark plug replacement',                       1800.00,  2080.00,  0.00),
(10, 2, '2024-02-20 10:00', '2024-02-20 12:00', 'Completed', 'Coolant flush needed',                         1500.00,  1700.00,  0.00),
(11, 8, '2024-03-01 09:00', '2024-03-01 11:00', 'Completed', 'Engine diagnostic - check engine light',        1500.00,     0.00,  0.00),
(12, 2, '2024-03-05 10:00', '2024-03-05 15:00', 'Completed', 'Gearbox service overdue',                      6000.00,  5300.00,  0.00),
(13, 8, '2024-03-10 09:00', '2024-03-10 09:30', 'Completed', 'First service',                                 800.00,  1050.00,  0.00),
(14, 2, '2024-03-15 11:00', '2024-03-15 13:00', 'Completed', 'Suspension noise',                             2000.00,  4800.00, 300.00),
(15, 8, '2024-03-20 10:00', '2024-03-20 12:30', 'Completed', 'Oil change + fuel filter',                     1100.00,  2350.00,  0.00),
(16, 2, '2024-04-01 09:00', '2024-04-01 10:00', 'Completed', 'Battery check',                                 500.00, 12500.00,  0.00),
(17, 8, '2024-04-05 08:00', '2024-04-05 14:00', 'Completed', 'Full major service',                            8000.00,  7800.00, 1000.00),
(18, 2, '2024-04-10 10:00', '2024-04-10 11:00', 'Completed', 'Engine oil change',                             800.00,  1050.00,  0.00),
(19, 8, '2024-04-15 09:00', '2024-04-15 11:00', 'Completed', 'Brake pads worn',                              2500.00,  3200.00,  0.00),
(20, 2, '2024-04-20 10:00', '2024-04-20 12:00', 'Completed', 'AC service',                                   3500.00,  3200.00, 200.00),
(21, 8, '2024-05-01 09:00', '2024-05-01 11:00', 'Completed', 'Wheel alignment + balancing',                  2000.00,     0.00,  0.00),
(22, 2, '2024-05-05 10:00', '2024-05-05 11:00', 'Completed', 'Air filter + oil filter',                       750.00,  1250.00,  0.00),
(23, 8, '2024-05-10 09:00', '2024-05-10 14:00', 'Completed', 'Timing belt replacement',                      2200.00,  6500.00,  0.00),
(24, 2, '2024-05-15 10:00', '2024-05-15 12:30', 'Completed', 'Spark plugs + coolant flush',                  3300.00,  5480.00, 500.00),
( 1, 8, '2024-05-20 09:00',  NULL,               'In Progress','Engine rough idle complaint',                 1500.00,     0.00,  0.00);

-- 3.9 Job Services
INSERT INTO job_services (job_id, service_type_id, mechanic_id, labor_cost, notes) VALUES
(1,  1, 3,  800.00, 'Shell 5W-30 used'),
(2,  5, 4, 2500.00, 'Front brake pads replaced'),
(3,  9, 3, 8000.00, 'Full service completed'),
(4,  10,6, 3500.00, 'R134a recharged'),
(5,  4, 7,  600.00, 'Tire rotation done'),
(5,  8, 7,  800.00, 'All 4 wheels balanced'),
(6,  6, 4,  500.00, 'New 65Ah battery'),
(7,  1, 3,  800.00, 'Castrol 10W-40'),
(7,  3, 6,  350.00, 'Air filter replaced'),
(8,  7, 7, 1200.00, 'Alignment done'),
(9,  11,3, 1800.00, '4 NGK spark plugs'),
(10, 12,4, 1500.00, 'Coolant flush & refill'),
(11, 15,6, 1500.00, 'Fault codes diagnosed'),
(12, 13,3, 6000.00, 'Gear oil drained and refilled'),
(13, 1, 9,  800.00, 'First oil change'),
(14, 14,4, 2000.00, 'Suspension bushes replaced'),
(15, 1, 3,  800.00, 'Oil changed'),
(15, 2, 6,  300.00, 'Fuel filter replaced'),
(16, 6, 9,  500.00, 'New 65Ah battery fitted'),
(17, 9, 3, 8000.00, 'Major service'),
(18, 1, 4,  800.00, 'Oil change'),
(19, 5, 7, 2500.00, 'Rear brakes replaced'),
(20, 10,6, 3500.00, 'AC gas topped up'),
(21, 7, 7, 1200.00, 'Alignment'),
(21, 8, 7,  800.00, 'Balancing'),
(22, 2, 9,  400.00, 'Oil filter'),
(22, 3, 9,  350.00, 'Air filter'),
(23, 1, 3,  800.00, 'Oil change before belt'),
(23, 11,3, 1400.00, 'Timing belt kit installed'),
(24, 11,4, 1800.00, 'Spark plugs x4'),
(24, 12,6, 1500.00, 'Coolant flush'),
(25, 15,3, 1500.00, 'Scan in progress');

-- 3.10 Job Parts
INSERT INTO job_parts (job_id, part_id, qty_used, unit_price) VALUES
(1,  1, 4, 1050.00),   -- Oil x4
(2,  6, 1, 3200.00),   -- Front brake pads
(3,  1, 4, 1050.00),   -- Oil
(3,  3, 1,  650.00),   -- Oil filter Toyota
(3,  5, 1, 1100.00),   -- Air filter
(4,  12,1, 3200.00),   -- AC refrigerant
(6,  9, 1,10500.00),   -- Battery 65Ah
(7,  2, 4,  980.00),   -- Oil Castrol
(7,  15,1, 1000.00),   -- Cabin air filter
(9,  10,4,  520.00),   -- Spark plugs x4
(10, 11,2,  850.00),   -- Coolant x2
(12, 16,4, 1300.00),   -- Gear oil x4
(13, 1, 3, 1050.00),   -- Oil x3
(14, 19,1, 4800.00),   -- Suspension bush kit
(15, 1, 3, 1050.00),   -- Oil
(15, 14,1, 1300.00),   -- Fuel filter
(16, 9, 1,12500.00),   -- Battery 65Ah
(17, 1, 5, 1050.00),   -- Oil
(17, 3, 1,  650.00),   -- Oil filter
(17, 5, 1, 1100.00),   -- Air filter
(18, 1, 3, 1050.00),   -- Oil
(19, 7, 1, 2600.00),   -- Rear brake pads
(19, 23,1, 1150.00),   -- Brake fluid
(20, 12,1, 3200.00),   -- AC refrigerant
(22, 4, 1,  600.00),   -- Oil filter Honda
(22, 5, 1, 1100.00),   -- Air filter
(23, 17,1, 6500.00),   -- Timing belt kit
(23, 1, 4, 1050.00),   -- Oil
(24, 10,4,  520.00),   -- Spark plugs
(24, 11,4,  850.00);   -- Coolant

-- 4. VIEWS
-- 4.1 Full Job Summary
CREATE OR REPLACE VIEW vw_job_summary AS
SELECT
  j.job_id,
  c.full_name                              AS customer_name,
  c.phone                                  AS customer_phone,
  CONCAT(vm.make_name,' ',mo.model_name,' ',v.year) AS vehicle,
  v.reg_number,
  e.full_name                              AS service_advisor,
  j.date_in,
  j.date_out,
  j.status,
  j.customer_complaint,
  j.total_labor,
  j.total_parts,
  j.discount,
  j.grand_total
FROM job_cards      j
JOIN vehicles       v  ON v.vehicle_id  = j.vehicle_id
JOIN customers      c  ON c.customer_id = v.customer_id
JOIN vehicle_models mo ON mo.model_id   = v.model_id
JOIN vehicle_makes  vm ON vm.make_id    = mo.make_id
JOIN employees      e  ON e.employee_id = j.advisor_id;

-- 4.2 Inventory Alert View
CREATE OR REPLACE VIEW vw_low_stock_parts AS
SELECT
  part_id, part_name, part_number, brand,
  stock_qty, reorder_level,
  (reorder_level - stock_qty) AS shortage
FROM parts
WHERE stock_qty <= reorder_level;

-- 4.3 Revenue by Month
CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT
  DATE_FORMAT(date_in,'%Y-%m') AS month,
  COUNT(*)                      AS total_jobs,
  SUM(grand_total)              AS total_revenue,
  AVG(grand_total)              AS avg_job_value,
  SUM(discount)                 AS total_discounts_given
FROM job_cards
WHERE status = 'Completed'
GROUP BY DATE_FORMAT(date_in,'%Y-%m')
ORDER BY month;

-- 4.4 Mechanic Performance
CREATE OR REPLACE VIEW vw_mechanic_performance AS
SELECT
  e.employee_id,
  e.full_name         AS mechanic_name,
  COUNT(js.job_service_id) AS services_done,
  SUM(js.labor_cost)       AS total_labor_earned,
  AVG(js.labor_cost)       AS avg_labor_per_service
FROM employees e
JOIN job_services js ON js.mechanic_id = e.employee_id
GROUP BY e.employee_id, e.full_name;

-- 4.5 Vehicle Service History
CREATE OR REPLACE VIEW vw_vehicle_history AS
SELECT
  v.reg_number,
  CONCAT(vm.make_name,' ',mo.model_name,' ',v.year) AS vehicle,
  c.full_name          AS owner,
  j.job_id,
  j.date_in,
  j.status,
  GROUP_CONCAT(st.service_name ORDER BY st.service_name SEPARATOR ', ') AS services_performed,
  j.grand_total
FROM vehicles       v
JOIN customers      c  ON c.customer_id = v.customer_id
JOIN vehicle_models mo ON mo.model_id   = v.model_id
JOIN vehicle_makes  vm ON vm.make_id    = mo.make_id
JOIN job_cards      j  ON j.vehicle_id  = v.vehicle_id
JOIN job_services   js ON js.job_id     = j.job_id
JOIN service_types  st ON st.service_type_id = js.service_type_id
GROUP BY v.reg_number, vehicle, owner, j.job_id, j.date_in, j.status, j.grand_total;
-- 5. STORED PROCEDURES & FUNCTIONS
DELIMITER $$

-- 5.1 Get full customer profile + vehicles
CREATE PROCEDURE sp_get_customer_profile(IN p_customer_id INT)
BEGIN
  SELECT c.customer_id, c.full_name, c.phone, c.email, c.address, c.city,
         v.reg_number,
         CONCAT(vm.make_name,' ',mo.model_name,' ',v.year) AS vehicle,
         v.color, v.mileage_km
  FROM customers c
  LEFT JOIN vehicles       v  ON v.customer_id = c.customer_id
  LEFT JOIN vehicle_models mo ON mo.model_id   = v.model_id
  LEFT JOIN vehicle_makes  vm ON vm.make_id    = mo.make_id
  WHERE c.customer_id = p_customer_id;
END$$

-- 5.2 Create a new job card
CREATE PROCEDURE sp_create_job_card(
  IN p_vehicle_id INT,
  IN p_advisor_id INT,
  IN p_complaint  TEXT
)
BEGIN
  INSERT INTO job_cards (vehicle_id, advisor_id, customer_complaint, status)
  VALUES (p_vehicle_id, p_advisor_id, p_complaint, 'Open');
  SELECT LAST_INSERT_ID() AS new_job_id;
END$$

-- 5.3 Add a service to a job card & update labor total
CREATE PROCEDURE sp_add_service_to_job(
  IN p_job_id          INT,
  IN p_service_type_id SMALLINT,
  IN p_mechanic_id     INT,
  IN p_labor_cost      DECIMAL(10,2),
  IN p_notes           VARCHAR(255)
)
BEGIN
  INSERT INTO job_services (job_id, service_type_id, mechanic_id, labor_cost, notes)
  VALUES (p_job_id, p_service_type_id, p_mechanic_id, p_labor_cost, p_notes);

  UPDATE job_cards
  SET total_labor = (
    SELECT COALESCE(SUM(labor_cost),0)
    FROM job_services WHERE job_id = p_job_id
  )
  WHERE job_id = p_job_id;

  SELECT LAST_INSERT_ID() AS new_job_service_id;
END$$

-- 5.4 Issue a part, update inventory & job parts total
CREATE PROCEDURE sp_issue_part(
  IN p_job_id   INT,
  IN p_part_id  INT,
  IN p_qty      INT
)
BEGIN
  DECLARE v_stock INT;
  DECLARE v_sell_price DECIMAL(10,2);

  SELECT stock_qty, selling_price
    INTO v_stock, v_sell_price
    FROM parts WHERE part_id = p_part_id;

  IF v_stock < p_qty THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Insufficient stock for requested quantity.';
  END IF;

  INSERT INTO job_parts (job_id, part_id, qty_used, unit_price)
  VALUES (p_job_id, p_part_id, p_qty, v_sell_price);

  UPDATE parts
  SET stock_qty = stock_qty - p_qty
  WHERE part_id = p_part_id;

  UPDATE job_cards
  SET total_parts = (
    SELECT COALESCE(SUM(qty_used * unit_price),0)
    FROM job_parts WHERE job_id = p_job_id
  )
  WHERE job_id = p_job_id;

  SELECT ROW_COUNT() AS rows_affected,
         (SELECT stock_qty FROM parts WHERE part_id = p_part_id) AS remaining_stock;
END$$

-- 5.5 Close / complete a job card
CREATE PROCEDURE sp_complete_job(
  IN p_job_id    INT,
  IN p_discount  DECIMAL(10,2)
)
BEGIN
  UPDATE job_cards
  SET status   = 'Completed',
      date_out = NOW(),
      discount = p_discount
  WHERE job_id = p_job_id AND status IN ('Open','In Progress');

  SELECT job_id, status, grand_total
  FROM job_cards WHERE job_id = p_job_id;
END$$

-- 5.6 Search vehicles by registration or customer name
CREATE PROCEDURE sp_search_vehicle(IN p_keyword VARCHAR(100))
BEGIN
  SELECT v.vehicle_id, v.reg_number,
         CONCAT(vm.make_name,' ',mo.model_name,' ',v.year) AS vehicle,
         c.full_name AS owner, c.phone
  FROM vehicles       v
  JOIN vehicle_models mo ON mo.model_id   = v.model_id
  JOIN vehicle_makes  vm ON vm.make_id    = mo.make_id
  JOIN customers      c  ON c.customer_id = v.customer_id
  WHERE v.reg_number LIKE CONCAT('%',p_keyword,'%')
     OR c.full_name   LIKE CONCAT('%',p_keyword,'%');
END$$

-- 5.7 FUNCTION: Calculate total revenue for a date range
CREATE FUNCTION fn_revenue_in_range(
  p_start DATE,
  p_end   DATE
) RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
  DECLARE v_total DECIMAL(12,2);
  SELECT COALESCE(SUM(grand_total),0)
    INTO v_total
    FROM job_cards
   WHERE status = 'Completed'
     AND DATE(date_in) BETWEEN p_start AND p_end;
  RETURN v_total;
END$$

-- 5.8 FUNCTION: Count jobs for a specific vehicle
CREATE FUNCTION fn_vehicle_job_count(p_vehicle_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v_count INT;
  SELECT COUNT(*) INTO v_count
  FROM job_cards
  WHERE vehicle_id = p_vehicle_id;
  RETURN v_count;
END$$

-- 5.9 Restock a part
CREATE PROCEDURE sp_restock_part(
  IN p_part_id INT,
  IN p_qty_add INT
)
BEGIN
  UPDATE parts
  SET stock_qty = stock_qty + p_qty_add
  WHERE part_id = p_part_id;

  SELECT part_id, part_name, stock_qty AS updated_stock
  FROM parts WHERE part_id = p_part_id;
END$$

-- 5.10 Top spending customers report
CREATE PROCEDURE sp_top_customers(IN p_limit INT)
BEGIN
  SELECT c.customer_id,
         c.full_name,
         c.phone,
         COUNT(DISTINCT j.job_id)  AS total_jobs,
         SUM(j.grand_total)         AS total_spent,
         MAX(j.date_in)             AS last_visit
  FROM customers  c
  JOIN vehicles   v ON v.customer_id = c.customer_id
  JOIN job_cards  j ON j.vehicle_id  = v.vehicle_id
  WHERE j.status = 'Completed'
  GROUP BY c.customer_id, c.full_name, c.phone
  ORDER BY total_spent DESC
  LIMIT p_limit;
END$$

DELIMITER ;
-- 6. SAMPLE SELECT QUERIES  (run these to see output)
-- Q1: All customers
SELECT * FROM customers ORDER BY customer_id;

-- Q2: All vehicles with make, model, owner
SELECT v.vehicle_id, v.reg_number,
       CONCAT(vm.make_name,' ',mo.model_name) AS vehicle,
       v.year, v.color, c.full_name AS owner
FROM vehicles v
JOIN vehicle_models mo ON mo.model_id   = v.model_id
JOIN vehicle_makes  vm ON vm.make_id    = mo.make_id
JOIN customers      c  ON c.customer_id = v.customer_id
ORDER BY v.vehicle_id;
SELECT * FROM vw_job_summary ORDER BY job_id;
SELECT * FROM vw_monthly_revenue;
SELECT * FROM vw_mechanic_performance ORDER BY total_labor_earned DESC;
SELECT * FROM vw_vehicle_history ORDER BY reg_number, date_in;
SELECT * FROM vw_low_stock_parts;
SELECT part_id, part_name, part_number, brand, selling_price, stock_qty, reorder_level
FROM parts ORDER BY part_id;
SELECT * FROM vw_job_summary WHERE status IN ('Open','In Progress');
SELECT fn_revenue_in_range('2024-01-01','2024-03-31') AS q1_2024_revenue;
SELECT fn_revenue_in_range('2024-04-01','2024-06-30') AS q2_2024_revenue;
SELECT fn_vehicle_job_count(1) AS jobs_for_vehicle_1;
CALL sp_top_customers(5);
CALL sp_get_customer_profile(1);
CALL sp_search_vehicle('LHR');
SELECT jp.job_id, p.part_name, p.part_number, jp.qty_used,
       jp.unit_price, (jp.qty_used * jp.unit_price) AS line_total
FROM job_parts jp
JOIN parts p ON p.part_id = jp.part_id
ORDER BY jp.job_id;
SELECT js.job_id, e.full_name AS mechanic, st.service_name, js.labor_cost
FROM job_services js
JOIN service_types st ON st.service_type_id = js.service_type_id
JOIN employees     e  ON e.employee_id       = js.mechanic_id
ORDER BY js.job_id;
SELECT st.service_name,
       COUNT(*)          AS times_performed,
       SUM(js.labor_cost) AS total_labor_revenue
FROM job_services js
JOIN service_types st ON st.service_type_id = js.service_type_id
GROUP BY st.service_name
ORDER BY times_performed DESC;
SELECT p.part_name, p.brand,
       SUM(jp.qty_used)              AS total_qty_sold,
       SUM(jp.qty_used*jp.unit_price) AS total_revenue
FROM job_parts jp
JOIN parts p ON p.part_id = jp.part_id
GROUP BY p.part_name, p.brand
ORDER BY total_qty_sold DESC;

-- Q20: Employee list with roles
SELECT employee_id, full_name, role, phone, hire_date, salary
FROM employees ORDER BY role, full_name;
