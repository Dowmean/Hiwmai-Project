SET UP PROJECT !
install 
-Tools • Dart 3.5.4 • DevTools 2.37.3
-jdk-17.0.12

Android studio
-Android Emulator 
-Android sdk Build-Tools 36-rc1 
-Android sdk Commandline-Tools
-Android sdk Platform -Tools
-Android Emulator hypervisor driver (install)


Visual Studio EXtensions
-Dart 
-Flutter 
-Gradle for Java
-Flutter Widget Snippets

Database 
-Mysql 

CREATE DATABASE hiwmai;
USE hiwmai;

*Table product
CREATE TABLE product (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255),
    email VARCHAR(255),
    category VARCHAR(255),
    productName VARCHAR(255),
    productDescription TEXT,
    price DECIMAL(10, 2),
    imageUrl LONGBLOB,
    postedDate DATETIME
);

*TABLE users
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firebase_uid VARCHAR(255),
    first_name VARCHAR(255),
    gender ENUM('ชาย', 'หญิง', 'อื่นๆ'),
    birth_date DATE,
    email VARCHAR(255),
    profile_picture LONGBLOB,
    role ENUM('User', 'Recipient', 'Admin'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

*TABLE recipients
CREATE TABLE recipients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firebase_uid VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    account_type ENUM('บุคคลทั่วไป', 'นิติบุคคลภายในประเทศ'),
    title ENUM('นางสาว', 'นาย', 'นาง'),
    gender ENUM('ชาย', 'หญิง', 'ไม่ระบุเพศ'),
    birth_date DATE,
    email VARCHAR(100),
    phone_number VARCHAR(20),
    address TEXT,
    profile_picture LONGBLOB,
    bank_name ENUM('กรุงไทย', 'กรุงเทพ', 'กสิกรไทย', 'ไทยพาณิชย์', 'ธนชาต', 'ออมสิน'),
    account_name VARCHAR(100),
    account_number VARCHAR(50),
    tax_id VARCHAR(50),
    id_card_image LONGBLOB,
    vat_registered TINYINT(1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

*TABLE favorites
CREATE TABLE favorites (
    email VARCHAR(255),
    product_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email, product_id)
);

*TABLE admins
CREATE TABLE admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

*TABLE payment
CREATE TABLE payment (
    id INT AUTO_INCREMENT PRIMARY KEY, 
    email VARCHAR(255), 
    income DECIMAL(10, 2), 
    datepay TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    reference_number VARCHAR(20),
    FOREIGN KEY (email) REFERENCES users(email)
);

DELIMITER $$

CREATE TRIGGER generate_reference_number
BEFORE INSERT ON payment
FOR EACH ROW
BEGIN
    DECLARE ref_num VARCHAR(20);
    DECLARE date_str VARCHAR(8);
    DECLARE count INT;

    SET date_str = DATE_FORMAT(CURRENT_DATE, '%Y%m%d');

    SELECT COUNT(*) + 1
    INTO count
    FROM payment
    WHERE reference_number LIKE CONCAT('P', date_str, '%');

    SET ref_num = CONCAT('P', date_str, LPAD(count, 4, '0'));

    SET NEW.reference_number = ref_num;
END $$

DELIMITER ;
