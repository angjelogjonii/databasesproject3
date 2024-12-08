-- Schema Definitions
CREATE TABLE people (
    username VARCHAR(255) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    role ENUM('staff', 'volunteer', 'client', 'donor') NOT NULL,
    email VARCHAR(255),
    name VARCHAR(255),
    phone_number VARCHAR(15)
);

CREATE TABLE items (
    itemID INT AUTO_INCREMENT PRIMARY KEY,
    description TEXT,
    category VARCHAR(255),
    subcategory VARCHAR(255),
    new_or_used ENUM('new', 'used'),
    donorID VARCHAR(255),
    FOREIGN KEY (donorID) REFERENCES people(username),
    orderID INT NULL
);

CREATE TABLE pieces (
    pieceID INT AUTO_INCREMENT PRIMARY KEY,
    itemID INT,
    pieceNum INT,
    room_number INT,
    shelf_number INT,
    FOREIGN KEY (itemID) REFERENCES items(itemID)
);

CREATE TABLE orders (
    orderID INT AUTO_INCREMENT PRIMARY KEY,
    client_username VARCHAR(255),
    staff_username VARCHAR(255),
    status ENUM('in progress', 'ready for delivery', 'delivered'),
    FOREIGN KEY (client_username) REFERENCES people(username),
    FOREIGN KEY (staff_username) REFERENCES people(username)
);

CREATE TABLE orders_items (
    orderID INT,
    itemID INT,
    PRIMARY KEY (orderID, itemID),
    FOREIGN KEY (orderID) REFERENCES orders(orderID),
    FOREIGN KEY (itemID) REFERENCES items(itemID)
);

-- Sample Data Insertion
INSERT INTO people (username, password, role, email, name, phone_number)
VALUES
('staff1', 'hashed_password_1', 'staff', 'staff1@example.com', 'Staff One', '1234567890'),
('donor1', 'hashed_password_2', 'donor', 'donor1@example.com', 'Donor One', '0987654321'),
('client1', 'hashed_password_3', 'client', 'client1@example.com', 'Client One', '1122334455');

INSERT INTO items (description, category, subcategory, new_or_used, donorID)
VALUES
('Yellow Sofa', 'Furniture', 'Sofa', 'used', 'donor1');

INSERT INTO pieces (itemID, pieceNum, room_number, shelf_number)
VALUES
(1, 1, 5, NULL),
(1, 2, 5, NULL);

INSERT INTO orders (client_username, staff_username, status)
VALUES
('client1', 'staff1', 'in progress');

INSERT INTO orders_items (orderID, itemID)
VALUES
(1, 1);

-- Examples:
-- 1. Find all pieces of an item
SELECT * FROM pieces WHERE itemID = 1;

-- 2. Find items in an order
SELECT i.itemID, i.description, i.category, i.subcategory, p.room_number, p.shelf_number
FROM items i
JOIN pieces p ON i.itemID = p.itemID
JOIN orders_items oi ON i.itemID = oi.itemID
WHERE oi.orderID = 1;

-- 3. Add a new donation (example for Yellow Sofa)
INSERT INTO items (description, category, subcategory, new_or_used, donorID) 
VALUES ('Yellow Sofa', 'Furniture', 'Sofa', 'used', 'donor1');

-- 4. Update order status
UPDATE orders SET status = 'ready for delivery' WHERE orderID = 1;
