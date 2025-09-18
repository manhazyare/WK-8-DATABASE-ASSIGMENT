-- Library Management System Database Schema
-- This database manages books, members, authors, categories, and borrowing transactions

-- Create the database
CREATE DATABASE IF NOT EXISTS library_management_system;
USE library_management_system;

-- Table 1: Categories (for book categorization)
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: Authors
CREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_author (first_name, last_name, birth_date)
);

-- Table 3: Publishers
CREATE TABLE publishers (
    publisher_id INT PRIMARY KEY AUTO_INCREMENT,
    publisher_name VARCHAR(100) NOT NULL UNIQUE,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 4: Books
CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    isbn VARCHAR(20) UNIQUE,
    title VARCHAR(255) NOT NULL,
    publication_year YEAR,
    edition VARCHAR(50),
    pages INT CHECK (pages > 0),
    language VARCHAR(30) DEFAULT 'English',
    category_id INT NOT NULL,
    publisher_id INT,
    total_copies INT NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INT NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    location_shelf VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL,
    
    -- Check constraint to ensure available copies don't exceed total copies
    CONSTRAINT chk_available_copies CHECK (available_copies <= total_copies)
);

-- Table 5: Book_Authors (Many-to-Many relationship between books and authors)
CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    author_role ENUM('Primary Author', 'Co-Author', 'Editor', 'Translator') DEFAULT 'Primary Author',
    PRIMARY KEY (book_id, author_id),
    
    -- Foreign key constraints
    CONSTRAINT fk_book_authors_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_authors_author FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Table 6: Members
CREATE TABLE members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    membership_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address TEXT,
    date_of_birth DATE,
    membership_type ENUM('Student', 'Faculty', 'Staff', 'Public') NOT NULL DEFAULT 'Public',
    membership_date DATE NOT NULL DEFAULT (CURDATE()),
    expiry_date DATE NOT NULL,
    status ENUM('Active', 'Suspended', 'Expired', 'Cancelled') DEFAULT 'Active',
    max_books_allowed INT DEFAULT 5 CHECK (max_books_allowed > 0),
    fine_amount DECIMAL(10,2) DEFAULT 0.00 CHECK (fine_amount >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table 7: Staff (Library employees)
CREATE TABLE staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    position VARCHAR(100),
    department VARCHAR(100),
    hire_date DATE NOT NULL,
    salary DECIMAL(12,2) CHECK (salary >= 0),
    status ENUM('Active', 'On Leave', 'Terminated') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table 8: Transactions (Book borrowing and returning)
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    staff_id INT,
    transaction_type ENUM('Borrow', 'Return', 'Renew') NOT NULL,
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    due_date DATE,
    return_date DATE,
    fine_amount DECIMAL(8,2) DEFAULT 0.00 CHECK (fine_amount >= 0),
    status ENUM('Active', 'Completed', 'Overdue') DEFAULT 'Active',
    notes TEXT,
    
    -- Foreign key constraints
    CONSTRAINT fk_transaction_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_transaction_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transaction_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    
    -- Check constraint for return date logic
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= DATE(transaction_date))
);

-- Table 9: Reservations (Book reservation system)
CREATE TABLE reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE NOT NULL,
    status ENUM('Active', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Active',
    priority_level INT DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    
    -- Foreign key constraints
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    
    -- Unique constraint to prevent duplicate active reservations
    CONSTRAINT unique_active_reservation UNIQUE (member_id, book_id, status)
);

-- Table 10: Fine_Payments (Track fine payments)
CREATE TABLE fine_payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    transaction_id INT,
    payment_amount DECIMAL(10,2) NOT NULL CHECK (payment_amount > 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Online', 'Check') NOT NULL,
    staff_id INT,
    receipt_number VARCHAR(50) UNIQUE,
    
    -- Foreign key constraints
    CONSTRAINT fk_payment_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    CONSTRAINT fk_payment_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- Indexes for better performance
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_isbn ON books(isbn);
CREATE INDEX idx_books_category ON books(category_id);
CREATE INDEX idx_members_membership_number ON members(membership_number);
CREATE INDEX idx_members_email ON members(email);
CREATE INDEX idx_members_status ON members(status);
CREATE INDEX idx_transactions_member ON transactions(member_id);
CREATE INDEX idx_transactions_book ON transactions(book_id);
CREATE INDEX idx_transactions_date ON transactions(transaction_date);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_reservations_member ON reservations(member_id);
CREATE INDEX idx_reservations_book ON reservations(book_id);
CREATE INDEX idx_reservations_status ON reservations(status);

-- Sample Data Insertion

-- Insert Categories
INSERT INTO categories (category_name, description) VALUES
('Fiction', 'Literary works of imaginative narration'),
('Non-Fiction', 'Factual and informational books'),
('Science & Technology', 'Books related to scientific and technological topics'),
('History', 'Historical accounts and biographies'),
('Education', 'Educational and academic textbooks'),
('Children', 'Books designed for children and young readers'),
('Reference', 'Dictionaries, encyclopedias, and reference materials'),
('Biography', 'Life stories and autobiographies'),
('Self-Help', 'Personal development and improvement books'),
('Art & Design', 'Books on visual arts, design, and creativity');

-- Insert Publishers
INSERT INTO publishers (publisher_name, address, phone, email, website) VALUES
('Penguin Random House', '1745 Broadway, New York, NY 10019', '+1-212-782-9000', 'info@penguinrandomhouse.com', 'www.penguinrandomhouse.com'),
('HarperCollins Publishers', '195 Broadway, New York, NY 10007', '+1-212-207-7000', 'info@harpercollins.com', 'www.harpercollins.com'),
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY 10020', '+1-212-698-7000', 'info@simonandschuster.com', 'www.simonandschuster.com'),
('Macmillan Publishers', '120 Broadway, New York, NY 10271', '+1-646-307-5151', 'press.inquiries@macmillan.com', 'www.macmillan.com'),
('Oxford University Press', 'Great Clarendon Street, Oxford OX2 6DP, UK', '+44-1865-556767', 'enquiry@oup.com', 'www.oup.com');

-- Insert Authors
INSERT INTO authors (first_name, last_name, birth_date, nationality, biography) VALUES
('George', 'Orwell', '1903-06-25', 'British', 'English novelist and journalist, famous for 1984 and Animal Farm'),
('J.K.', 'Rowling', '1965-07-31', 'British', 'British author, best known for the Harry Potter series'),
('Stephen', 'King', '1947-09-21', 'American', 'American author of horror, supernatural fiction, suspense, and fantasy novels'),
('Agatha', 'Christie', '1890-09-15', 'British', 'British crime novelist, short story writer and playwright'),
('Isaac', 'Asimov', '1920-01-02', 'American', 'American writer and professor of biochemistry, known for science fiction works'),
('Harper', 'Lee', '1926-04-28', 'American', 'American novelist widely known for To Kill a Mockingbird'),
('Ernest', 'Hemingway', '1899-07-21', 'American', 'American novelist, short story writer, and journalist'),
('Jane', 'Austen', '1775-12-16', 'British', 'English novelist known for romantic fiction set among the landed gentry'),
('Mark', 'Twain', '1835-11-30', 'American', 'American writer, humorist, entrepreneur, publisher, and lecturer'),
('Charles', 'Dickens', '1812-02-07', 'British', 'English writer and social critic who created memorable fictional characters');

-- Insert Staff
INSERT INTO staff (employee_id, first_name, last_name, email, phone, position, department, hire_date, salary) VALUES
('LIB001', 'Alice', 'Johnson', 'alice.johnson@library.com', '+1-555-0101', 'Head Librarian', 'Administration', '2020-01-15', 65000.00),
('LIB002', 'Bob', 'Smith', 'bob.smith@library.com', '+1-555-0102', 'Assistant Librarian', 'Circulation', '2021-03-10', 45000.00),
('LIB003', 'Carol', 'Brown', 'carol.brown@library.com', '+1-555-0103', 'Reference Librarian', 'Reference', '2019-08-20', 50000.00),
('LIB004', 'David', 'Wilson', 'david.wilson@library.com', '+1-555-0104', 'Technical Services Librarian', 'Technical Services', '2022-06-01', 48000.00),
('LIB005', 'Emma', 'Davis', 'emma.davis@library.com', '+1-555-0105', 'Children''s Librarian', 'Children''s Section', '2021-11-15', 42000.00);

-- Insert Members
INSERT INTO members (membership_number, first_name, last_name, email, phone, address, date_of_birth, membership_type, expiry_date, max_books_allowed) VALUES
('MEM001', 'John', 'Doe', 'john.doe@email.com', '+1-555-1001', '123 Main St, City, State 12345', '1990-05-15', 'Public', '2024-12-31', 5),
('MEM002', 'Jane', 'Smith', 'jane.smith@email.com', '+1-555-1002', '456 Oak Ave, City, State 12345', '1985-08-22', 'Faculty', '2025-06-30', 10),
('MEM003', 'Michael', 'Johnson', 'michael.johnson@student.edu', '+1-555-1003', '789 Pine St, City, State 12345', '2000-03-10', 'Student', '2024-08-31', 8),
('MEM004', 'Sarah', 'Williams', 'sarah.williams@email.com', '+1-555-1004', '321 Elm St, City, State 12345', '1978-11-05', 'Staff', '2025-12-31', 7),
('MEM005', 'Robert', 'Brown', 'robert.brown@email.com', '+1-555-1005', '654 Maple Ave, City, State 12345', '1995-07-18', 'Public', '2024-10-31', 5);

-- Insert Books
INSERT INTO books (isbn, title, publication_year, edition, pages, category_id, publisher_id, total_copies, available_copies, location_shelf) VALUES
('978-0-452-28423-4', '1984', 1949, 'Reprint Edition', 328, 1, 1, 3, 2, 'A1-001'),
('978-0-7475-3269-9', 'Harry Potter and the Philosopher''s Stone', 1997, '1st Edition', 223, 6, 2, 5, 4, 'C2-015'),
('978-0-385-12167-8', 'The Shining', 1977, 'First Edition', 447, 1, 3, 2, 1, 'A3-078'),
('978-0-06-112008-4', 'And Then There Were None', 1939, 'Paperback Edition', 264, 1, 2, 4, 3, 'A2-045'),
('978-0-553-29337-0', 'Foundation', 1951, 'Bantam Edition', 244, 3, 4, 3, 3, 'B1-120'),
('978-0-06-112008-5', 'To Kill a Mockingbird', 1960, 'Anniversary Edition', 376, 1, 2, 4, 2, 'A1-089'),
('978-0-684-80122-3', 'The Old Man and the Sea', 1952, 'Scribner Edition', 127, 1, 3, 2, 2, 'A1-156'),
('978-0-14-143951-8', 'Pride and Prejudice', 1813, 'Penguin Classics', 432, 1, 1, 3, 1, 'A2-201'),
('978-0-486-40077-3', 'The Adventures of Tom Sawyer', 1876, 'Dover Edition', 274, 6, 5, 2, 2, 'C1-033'),
('978-0-14-143974-7', 'Great Expectations', 1861, 'Penguin Classics', 544, 1, 1, 3, 3, 'A2-178');

-- Insert Book-Author relationships
INSERT INTO book_authors (book_id, author_id, author_role) VALUES
(1, 1, 'Primary Author'),    -- 1984 by George Orwell
(2, 2, 'Primary Author'),    -- Harry Potter by J.K. Rowling
(3, 3, 'Primary Author'),    -- The Shining by Stephen King
(4, 4, 'Primary Author'),    -- And Then There Were None by Agatha Christie
(5, 5, 'Primary Author'),    -- Foundation by Isaac Asimov
(6, 6, 'Primary Author'),    -- To Kill a Mockingbird by Harper Lee
(7, 7, 'Primary Author'),    -- The Old Man and the Sea by Hemingway
(8, 8, 'Primary Author'),    -- Pride and Prejudice by Jane Austen
(9, 9, 'Primary Author'),    -- Tom Sawyer by Mark Twain
(10, 10, 'Primary Author');  -- Great Expectations by Charles Dickens

-- Views for common queries

-- View: Available Books
CREATE VIEW available_books AS
SELECT 
    b.book_id,
    b.isbn,
    b.title,
    CONCAT(a.first_name, ' ', a.last_name) as author_name,
    c.category_name,
    p.publisher_name,
    b.publication_year,
    b.available_copies,
    b.location_shelf
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id AND ba.author_role = 'Primary Author'
JOIN authors a ON ba.author_id = a.author_id
JOIN categories c ON b.category_id = c.category_id
LEFT JOIN publishers p ON b.publisher_id = p.publisher_id
WHERE b.available_copies > 0
ORDER BY b.title;

-- View: Active Borrowings
CREATE VIEW active_borrowings AS
SELECT 
    t.transaction_id,
    CONCAT(m.first_name, ' ', m.last_name) as member_name,
    m.membership_number,
    b.title as book_title,
    t.transaction_date,
    t.due_date,
    DATEDIFF(CURDATE(), t.due_date) as days_overdue,
    t.fine_amount
FROM transactions t
JOIN members m ON t.member_id = m.member_id
JOIN books b ON t.book_id = b.book_id
WHERE t.status = 'Active' AND t.transaction_type = 'Borrow'
ORDER BY t.due_date;

-- View: Member Summary
CREATE VIEW member_summary AS
SELECT 
    m.member_id,
    m.membership_number,
    CONCAT(m.first_name, ' ', m.last_name) as full_name,
    m.email,
    m.membership_type,
    m.status,
    COUNT(t.transaction_id) as books_borrowed,
    SUM(CASE WHEN t.status = 'Active' THEN 1 ELSE 0 END) as currently_borrowed,
    m.fine_amount as outstanding_fines
FROM members m
LEFT JOIN transactions t ON m.member_id = t.member_id AND t.transaction_type = 'Borrow'
GROUP BY m.member_id
ORDER BY m.last_name, m.first_name;
