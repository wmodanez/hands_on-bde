-- Create modanez user with full privileges
CREATE USER IF NOT EXISTS 'modanez'@'%' IDENTIFIED BY '123456';
GRANT ALL PRIVILEGES ON *.* TO 'modanez'@'%' WITH GRANT OPTION;

-- Create database 'imp'
CREATE DATABASE IF NOT EXISTS imp;

-- Create users with read-only access to 'imp' database and full access to their own databases
CREATE USER IF NOT EXISTS 'bruna'@'%' IDENTIFIED BY 'b123456';
GRANT SELECT ON imp.* TO 'bruna'@'%';
GRANT ALL PRIVILEGES ON bruna.* TO 'bruna'@'%' WITH GRANT OPTION;

CREATE USER IF NOT EXISTS 'lorenna'@'%' IDENTIFIED BY 'l123456';
GRANT SELECT ON imp.* TO 'lorenna'@'%';
GRANT ALL PRIVILEGES ON lorenna.* TO 'lorenna'@'%' WITH GRANT OPTION;

CREATE USER IF NOT EXISTS 'rejane'@'%' IDENTIFIED BY 'r123456';
GRANT SELECT ON imp.* TO 'rejane'@'%';
GRANT ALL PRIVILEGES ON rejane.* TO 'rejane'@'%' WITH GRANT OPTION;

CREATE USER IF NOT EXISTS 'santino'@'%' IDENTIFIED BY 's123456';
GRANT SELECT ON imp.* TO 'santino'@'%';
GRANT ALL PRIVILEGES ON santino.* TO 'santino'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
