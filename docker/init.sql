-- Create database 'imp'
CREATE DATABASE IF NOT EXISTS imp;

-- Create individual databases for each user
CREATE DATABASE IF NOT EXISTS bruna;
CREATE DATABASE IF NOT EXISTS lorenna;
CREATE DATABASE IF NOT EXISTS rejane;
CREATE DATABASE IF NOT EXISTS santino;
CREATE DATABASE IF NOT EXISTS modanez;

-- Create users with read-only access to 'imp' database and full access ONLY to their own databases
CREATE USER IF NOT EXISTS 'bruna'@'%' IDENTIFIED BY 'b123456';
GRANT SELECT ON imp.* TO 'bruna'@'%';
GRANT ALL PRIVILEGES ON bruna.* TO 'bruna'@'%';
REVOKE ALL PRIVILEGES ON *.* FROM 'bruna'@'%';
GRANT SELECT ON imp.* TO 'bruna'@'%';
GRANT ALL PRIVILEGES ON bruna.* TO 'bruna'@'%';

CREATE USER IF NOT EXISTS 'lorenna'@'%' IDENTIFIED BY 'l123456';
GRANT SELECT ON imp.* TO 'lorenna'@'%';
GRANT ALL PRIVILEGES ON lorenna.* TO 'lorenna'@'%';
REVOKE ALL PRIVILEGES ON *.* FROM 'lorenna'@'%';
GRANT SELECT ON imp.* TO 'lorenna'@'%';
GRANT ALL PRIVILEGES ON lorenna.* TO 'lorenna'@'%';

CREATE USER IF NOT EXISTS 'rejane'@'%' IDENTIFIED BY 'r123456';
GRANT SELECT ON imp.* TO 'rejane'@'%';
GRANT ALL PRIVILEGES ON rejane.* TO 'rejane'@'%';
REVOKE ALL PRIVILEGES ON *.* FROM 'rejane'@'%';
GRANT SELECT ON imp.* TO 'rejane'@'%';
GRANT ALL PRIVILEGES ON rejane.* TO 'rejane'@'%';

CREATE USER IF NOT EXISTS 'santino'@'%' IDENTIFIED BY 's123456';
GRANT SELECT ON imp.* TO 'santino'@'%';
GRANT ALL PRIVILEGES ON santino.* TO 'santino'@'%';
REVOKE ALL PRIVILEGES ON *.* FROM 'santino'@'%';
GRANT SELECT ON imp.* TO 'santino'@'%';
GRANT ALL PRIVILEGES ON santino.* TO 'santino'@'%';

CREATE USER IF NOT EXISTS 'modanez'@'%' IDENTIFIED BY '123456';
GRANT SELECT ON imp.* TO 'modanez'@'%';
GRANT ALL PRIVILEGES ON modanez.* TO 'modanez'@'%';
REVOKE ALL PRIVILEGES ON *.* FROM 'modanez'@'%';
GRANT SELECT ON imp.* TO 'modanez'@'%';
GRANT ALL PRIVILEGES ON modanez.* TO 'modanez'@'%';

FLUSH PRIVILEGES;
