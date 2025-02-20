# SET UP PROJECT

## Install
- Tools:
  - Dart 3.5.4
  - Flutter 3.27.3 
  - DevTools 2.37.3
  - JDK: jdk-17.0.12
  - JavaScript: v22.11.0
- Android Studio
- Visual Studio
- MySQL

## Environment

![Environment Image](https://github.com/user-attachments/assets/e17518ef-42a3-4c30-b7e3-880d93360206)

## Android Studio

- Android Emulator
- Android SDK Build-Tools 36-rc1
- Android SDK Commandline Tools
- Android SDK Platform Tools
- Android Emulator Hypervisor Driver (installed)

![Android Studio Image 1](https://github.com/user-attachments/assets/ee55247c-deb7-434e-9e8e-b1c9ea6c0188)
![Android Studio Image 2](https://github.com/user-attachments/assets/065ea24b-75f0-4e34-b2e7-6f83aa12e931)

## Visual Studio Extensions

- Dart
- Flutter
- Gradle for Java
- Flutter Widget Snippets

## Database

### MySQL Setup

```sql
CREATE DATABASE hiwmai;
USE hiwmai;
```

### Tables

#### Table: product

```sql
CREATE TABLE product (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255),
    email VARCHAR(255),
    category VARCHAR(255),
    productName VARCHAR(255),
    productDescription TEXT,
    price DECIMAL(10, 2),
    shipping DECIMAL(10, 2),
    carry DECIMAL(10, 2),
    imageUrl LONGBLOB,
    postedDate DATETIME
);
```

#### Table: users

```sql
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
```

#### Table: recipients

```sql
CREATE TABLE recipients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firebase_uid VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### Table: favorites

```sql
CREATE TABLE favorites (
    email VARCHAR(255),
    product_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (email, product_id)
);
```

#### Table: admins

```sql
CREATE TABLE admins (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### Table: payment

```sql
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
```

#### Table: orders

```sql
CREATE TABLE IF NOT EXISTS orders (
    ref VARCHAR(20) NOT NULL PRIMARY KEY,
    email VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    shopdate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    qrcode LONGBLOB,
    image LONGBLOB,
    paydate TIMESTAMP NULL DEFAULT NULL,
    status VARCHAR(20),
    num INT NOT NULL,
    note VARCHAR(255),
    CONSTRAINT fk_email FOREIGN KEY (email) REFERENCES users(email)
);

DELIMITER $$

CREATE TRIGGER trg_generate_order_ref BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    DECLARE new_ref VARCHAR(20);
    SET new_ref = CONCAT('ORD', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(IFNULL(
        (SELECT MAX(CAST(SUBSTRING(ref, 12) AS UNSIGNED)) FROM orders WHERE SUBSTRING(ref, 4, 8) = DATE_FORMAT(NOW(), '%Y%m%d')), 0) + 1, 4, '0'));
    SET NEW.ref = new_ref;
END $$

DELIMITER ;
```

#### Table: chats

```sql
CREATE TABLE chats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_email VARCHAR(255) NOT NULL,
    receiver_email VARCHAR(255) NOT NULL,
    message TEXT,
    image_url TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Table: reviews

```sql
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ref VARCHAR(20) NOT NULL, 
    email VARCHAR(255) NOT NULL, 
    rate TINYINT NOT NULL CHECK (rate BETWEEN 1 AND 5), 
    description VARCHAR(255), 
    FOREIGN KEY (email) REFERENCES users(email) ON DELETE CASCADE -- FK 
);
```


#### Table: purchase

```sql
CREATE TABLE purchase (
    ref VARCHAR(20) NOT NULL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    trackingnumber varchar(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirm_order tinyint(1)
);
```
#### Table: addresses

sql
CREATE TABLE addresses (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    firebase_uid   VARCHAR(255) NOT NULL,
    email          VARCHAR(255) NOT NULL,
    province       VARCHAR(100) NOT NULL,
    name           VARCHAR(255) NOT NULL,
    phone          VARCHAR(20) NOT NULL,
    address_detail TEXT NOT NULL,
    district       VARCHAR(100) DEFAULT NULL,
    subdistrict    VARCHAR(100) NOT NULL,
    city           VARCHAR(100) DEFAULT NULL,
    postal_code    VARCHAR(10) DEFAULT NULL,
    is_default     TINYINT(1) DEFAULT 0,
    address_type   ENUM('บ้าน','ที่ทำงาน','อื่นๆ') DEFAULT 'บ้าน',
    INDEX idx_firebase_uid (firebase_uid)
);

#### Table: bank_accounts

sql
CREATE TABLE bank_accounts (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    firebase_uid VARCHAR(255) NOT NULL,
    email        VARCHAR(255) NOT NULL,
    fullname     VARCHAR(50) NOT NULL,
    banknumber   VARCHAR(20) NOT NULL,
    bankname     VARCHAR(50) NOT NULL,
    is_default   TINYINT(1) DEFAULT 0,
    INDEX idx_firebase_uid (firebase_uid)
);


#### Table: notifications 

sql
CREATE TABLE notifications  (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    email      VARCHAR(255) NOT NULL,
    message    TEXT NOT NULL,
    is_read    TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

