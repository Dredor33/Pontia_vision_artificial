
###############################################
/*

Proyecto Jupiter Vision Artificial

# INDICE
	1. CREACIÓN DE LAS TABLAS 
	2. IMPORTACIÓN DE DATOS
	3. ANALISIS INCIAL DE KPIS
    4. OTRAS KPIS
    5. CONCLUSIONES

*/
###############################################

###############################################
# 1. CREACIÓN DE LAS TABLAS 
###############################################


######################################################################################################################################
DROP DATABASE IF EXISTS VA_Pontia_Logistica;

CREATE SCHEMA VA_Pontia_Logistica;

-- para entrar en esta base de datos
USE VA_Pontia_Logistica;
######################################################################################################################################

-- Para poder importar archivos y ver la ruta permitida en MySQL Workbench

SET SQL_SAFE_UPDATES = 0;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'secure_file_priv';


-- Creamos el mapa relacions sql con las tablas principales () y las tablas de apoyo () y creamos la relación entre ellas. 

################################

-- Empezamos con las tablas de apoyo

DROP TABLE IF EXISTS TABLA_MARCA;

CREATE TABLE TABLA_MARCA (
    marca_id TINYINT PRIMARY KEY, -- yo haria un AUTO_INCREMENT PRIMARY KEY para que se pueda incorporar nuevos tipos
    marca_fruta VARCHAR(20)
);

DROP TABLE IF EXISTS TABLA_TIPO;

CREATE TABLE TABLA_TIPO (
     tipo_id TINYINT PRIMARY KEY, -- yo haria un AUTO_INCREMENT PRIMARY KEY para que se pueda incorporar nuevos tipos
     tipo_fruta VARCHAR(25)
);

DROP TABLE IF EXISTS TABLA_TIENDA;

CREATE TABLE TABLA_TIENDA (
    tienda_id TINYINT PRIMARY KEY,
	tienda_nombre VARCHAR(40)
);

DROP TABLE IF EXISTS TABLA_PROVEEDOR;

CREATE TABLE TABLA_PROVEEDOR (
	proveedor_id TINYINT PRIMARY KEY,
    proveedor_nombre VARCHAR(50)
);


################################

-- Continuamos con las tablas principales

DROP TABLE IF EXISTS PRODUCTOS;

CREATE TABLE PRODUCTOS (
    t_id VARCHAR(40) PRIMARY KEY,
    marca_id TINYINT,
    identificador VARCHAR(60),
    tipo_id TINYINT,
    peso FLOAT,
    FOREIGN KEY (marca_id) REFERENCES TABLA_MARCA(marca_id),
    FOREIGN KEY (tipo_id) REFERENCES TABLA_TIPO(tipo_id)
);

DROP TABLE IF EXISTS COMPRAS;

CREATE TABLE COMPRAS (
    t_id VARCHAR(40),
	proveedor_id TINYINT,
	coste_inicial VARCHAR(20), -- se inicializa como VARCHAR porque DECIMAL no permite valores vacios, en la carga lo solventamos
	fecha_hora_recogida DATETIME,
	FOREIGN KEY (t_id) REFERENCES PRODUCTOS(t_id),
    FOREIGN KEY (proveedor_id) REFERENCES TABLA_PROVEEDOR(proveedor_id)
);

DROP TABLE IF EXISTS VENTAS;

CREATE TABLE VENTAS (
    t_id VARCHAR(40),
    tienda_id TINYINT,
    fecha_hora_venta DATETIME,
	precio_venta DECIMAL(20,16),
	FOREIGN KEY (t_id) REFERENCES PRODUCTOS(t_id),
    FOREIGN KEY (tienda_id) REFERENCES TABLA_TIENDA(tienda_id)
);



###############################################
# 2. IMPORTACIÓN DE DATOS
###############################################

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/productos.csv'
INTO TABLE PRODUCTOS
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM PRODUCTOS LIMIT 10;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/compras.csv'
INTO TABLE COMPRAS
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(t_id, proveedor_id, coste_inicial, fecha_hora_recogida)
SET coste_inicial = NULLIF(coste_inicial, '');

SELECT * FROM COMPRAS LIMIT 10;

SET SQL_SAFE_UPDATES = 0;

-- Cambiamos a NULL los valores vacios para poder cambiarlo luego a DECIMAL

UPDATE COMPRAS 
SET coste_inicial = NULL 
WHERE t_id IN (
    SELECT t_id FROM (SELECT t_id FROM COMPRAS WHERE coste_inicial NOT REGEXP '^[0-9]+(\.[0-9]+)?$') AS temp
);
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM COMPRAS WHERE coste_inicial IS NULL;
ALTER TABLE COMPRAS MODIFY coste_inicial DECIMAL(20,16) NULL;
SELECT * FROM COMPRAS WHERE coste_inicial IS NOT NULL;



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ventas.csv'
INTO TABLE VENTAS
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(t_id, tienda, @fecha_hora_venta, precio_venta)
SET fecha_hora_venta = NULLIF(@fecha_hora_venta, '');

SELECT * FROM VENTAS LIMIT 10;

SET SQL_SAFE_UPDATES = 0;
UPDATE VENTAS 
SET precio_venta = NULL 
WHERE t_id IN (
    SELECT t_id FROM (SELECT t_id FROM VENTAS WHERE precio_venta NOT REGEXP '^[0-9]+(\.[0-9]+)?$') AS temp
);
SET SQL_SAFE_UPDATES = 1;
SELECT * FROM VENTAS WHERE precio_venta IS NULL;
ALTER TABLE VENTAS MODIFY precio_venta DECIMAL(18,6) NULL;
SELECT * FROM VENTAS WHERE precio_venta IS NOT NULL;



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/tabla_marca.csv'
INTO TABLE TABLA_MARCA
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT*FROM TABLA_MARCA LIMIT 10;



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/tabla_proveedor.csv'
INTO TABLE TABLA_PROVEEDOR
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT*FROM TABLA_PROVEEDOR LIMIT 10;



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/tabla_tienda.csv'
INTO TABLE TABLA_TIENDA
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT*FROM TABLA_TIENDA LIMIT 10;



LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/tabla_tipo.csv'
INTO TABLE TABLA_tipo
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT*FROM TABLA_TIPO LIMIT 10;



###############################################
# 3. ANALISIS INCIAL DE KPIS
###############################################


-- Calcular la media diaria de la cuantía de las distribuciones

SELECT AVG(total_dia) AS media_diaria
FROM(SELECT DATE (fecha_hora_venta) AS fecha, SUM(precio_venta) AS total_dia
FROM VENTAS
WHERE precio_venta IS NOT NULL
GROUP BY DATE(fecha_hora_venta))
AS venta_por_dia;

SELECT DATE(fecha_hora_venta) AS fecha, AVG(precio_venta) AS media_diaria
FROM VENTAS
WHERE precio_venta IS NOT NULL
GROUP BY DATE(fecha_hora_venta)
ORDER BY fecha;

-- Calcular la cuantía total de las distribuciones 
SELECT SUM(precio_venta) AS cuantia_total_distribuciones
FROM VENTAS
WHERE precio_venta IS NOT NULL;

-- ¿Qué días del mes se han producido más distribuciones y cuántas?
-- Deberíamos eliminar aquellas fechas de Agosto y Octubre

SELECT DAY(fecha_hora_venta) AS dia, COUNT(*) AS total_distribuciones
FROM VENTAS
WHERE fecha_hora_venta IS NOT NULL
GROUP BY DAY(fecha_hora_venta)
ORDER BY total_distribuciones DESC;

-- ¿A qué horas del día se producen más recogidas de alimentos y cuántas? 

SELECT HOUR(fecha_hora_recogida) AS hora, COUNT(*) AS total_recogidas
FROM COMPRAS
WHERE fecha_hora_recogida IS NOT NULL
AND MONTH(fecha_hora_recogida) = 9
GROUP BY HOUR(fecha_hora_recogida)
ORDER BY total_recogidas DESC;

-- ¿Cuáles son los 5 clientes que más dinero han gastado comprando la fruta y cuánto?
-- En primer lugar relacionamos la tabla de tienda con la de ventas
SELECT v.tienda, tt.tienda AS nombre_tienda, v.precio_venta
FROM VENTAS v
JOIN TABLA_TIENDA tt
ON v.tienda=tt.número_asignado_tienda;
-- Después realizamos el cálculo
SELECT tt.tienda AS nombre_tienda, SUM(v.precio_venta) AS total_tienda
FROM VENTAS v
JOIN TABLA_TIENDA tt
ON v.tienda=tt.número_asignado_tienda
WHERE v.precio_venta IS NOT NULL
GROUP BY tt.tienda
ORDER BY total_tienda DESC
LIMIT 5;

-- ¿Cuáles son los 5 clientes que menos dinero han gastado comprando la fruta y cuánto? 
SELECT v.tienda, tt.tienda AS nombre_tienda, v.precio_venta
FROM VENTAS v
JOIN TABLA_TIENDA tt
ON v.tienda=tt.número_asignado_tienda;

SELECT tt.tienda AS nombre_tienda, SUM(v.precio_venta) AS total_tienda
FROM VENTAS v
JOIN TABLA_TIENDA tt
ON v.tienda=tt.número_asignado_tienda
WHERE v.precio_venta IS NOT NULL
GROUP BY tt.tienda
ORDER BY total_tienda ASC
LIMIT 5;

-- ¿Cuáles son los 10 proveedores que han recibido más dinero y cuánto?
SELECT c.proveedor, tp.proveedor AS nombre_proveedor, c.coste_inicial
FROM COMPRAS c
JOIN TABLA_PROVEEDOR tp
ON c.proveedor=tp.número_asignado_proveedor;

SELECT tp.proveedor AS nombre_proveedor, SUM(c.coste_inicial) AS total_proveedor
FROM COMPRAS c
JOIN TABLA_PROVEEDOR tp
ON c.proveedor=tp.número_asignado_proveedor
WHERE coste_inicial IS NOT NULL
GROUP BY tp.proveedor
ORDER BY total_proveedor DESC
LIMIT 10;

-- ¿Cuáles son los 3 productos con mayor beneficio a lo largo del mes (aquellos que al 
-- restarle al coste de venta el precio de compra se quedan con un mejor resultado) y cuál ha sido su balance? 
-- Filtramos por el mes de Septiembre y por aquellos casos en los que el precio y voste no son nulos.

SELECT tti.tipo AS tipo_producto, SUM(v.precio_venta-c.coste_inicial) AS balance_total
FROM PRODUCTOS p
JOIN TABLA_TIPO tti ON p.tipo=tti.número_asignado_tipo
JOIN COMPRAS c ON p.t_id=c.t_id
JOIN VENTAS v on p.t_id=v.t_id
WHERE MONTH(c.fecha_hora_recogida)=9
AND MONTH(v.fecha_hora_venta)=9
AND c.coste_inicial IS NOT NULL
AND c.coste_inicial > 0
AND precio_venta IS NOT NULL
AND precio_venta > 0
GROUP BY tti.tipo
ORDER BY balance_total DESC
LIMIT 3;

-- ¿Cuáles son los 3 productos con peor beneficio a lo largo de todo el mes y cuál ha sido?

SELECT tti.tipo AS tipo_producto, SUM(v.precio_venta-c.coste_inicial) AS balance_total
FROM PRODUCTOS p
JOIN TABLA_TIPO tti ON p.tipo=tti.número_asignado_tipo
JOIN COMPRAS c ON p.t_id=c.t_id
JOIN VENTAS v on p.t_id=v.t_id
WHERE MONTH(c.fecha_hora_recogida)=9
AND MONTH(v.fecha_hora_venta)=9
AND c.coste_inicial IS NOT NULL
AND c.coste_inicial > 0
AND precio_venta IS NOT NULL
AND precio_venta > 0
GROUP BY tti.tipo
ORDER BY balance_total ASC
LIMIT 3;

-- ¿Cuál es el precio de venta medio de cada fruta?

SELECT tti.tipo AS tipo_producto, AVG(v.precio_venta) AS precio_medio_venta
FROM PRODUCTOS p
JOIN TABLA_TIPO tti ON P.tipo=tti.número_asignado_tipo
JOIN VENTAS v ON p.t_id=v.t_id
WHERE MONTH(V.fecha_hora_venta)=9
AND precio_venta IS NOT NULL
AND precio_venta  > 0
GROUP BY tti.tipo
ORDER BY precio_medio_venta ASC;

-- Suponiendo que si no se dispone de información de venta se trata de una fruta que no 
-- ha podido venderse por haber sido dañada durante la distribución, ¿cuánta fruta de cada tipo ha sido dañada?

-- En ester caso es un COUNT?o lo valoramos por gramos?

SELECT tti.tipo AS tipo_producto, SUM(p.peso) AS cantidad_dañada
FROM productos p
JOIN tabla_tipo tti ON P.tipo=tti.número_asignado_tipo
JOIN VENTAS v ON p.t_id=v.t_id
WHERE MONTH(V.fecha_hora_venta)=9
AND v.precio_venta IS NULL
GROUP BY tti.tipo
ORDER BY cantidad_dañada DESC;

-- ¿Cuál ha sido la pérdida total de la fruta dañada? 
SELECT SUM(p.peso) AS perdida_total
FROM PRODUCTOS p
JOIN VENTAS v ON P.t_id=v.t_id
WHERE v.precio_venta IS NULL;

--  ¿Cuál es la cuantía total de cada tipo de fruta que han comprado los 5 clientes que más 
-- dinero han gastado?


