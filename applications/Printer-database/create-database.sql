create database xmlss_printer
GO

CREATE USER 'xmlss_printer'@'localhost' IDENTIFIED BY 'xmlss_printer'
GO

GRANT ALL ON xmlss_printer.* TO 'xmlss_printer'@'localhost'
GO
