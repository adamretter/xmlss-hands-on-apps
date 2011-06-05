CREATE DATABASE xmlss_printer;

CREATE USER 'xmlss_printer'@'localhost' IDENTIFIED BY 'xmlss_printer';

GRANT ALL ON xmlss_printer.* TO 'xmlss_printer'@'localhost';
