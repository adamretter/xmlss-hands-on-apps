create database xmlss_printer;

CREATE USER 'xmlss_printer'@'localhost' IDENTIFIED BY 'xmlss_printer';

GRANT ALL PRIVILEGES ON xmlss_printer.* TO 'xmlss_printer'@'localhost'