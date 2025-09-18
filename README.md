Library Management System - MySQL Database Schema
A comprehensive relational database schema designed for managing library operations including books, members, transactions, and staff management.
🗄️ Database Overview
Database Name: library_management_system
Engine: InnoDB
Character Set: utf8mb4
Collation: utf8mb4_unicode_ci
📊 Schema Architecture
Entity Relationship Diagram Summary
Categories (1) ──────→ (M) Books (M) ←────── (M) Authors
                         │                      │
Publishers (1) ──────→ (M) │                      │
                         │                      │
                         ↓                      │
Members (1) ────→ (M) Transactions           Book_Authors
    │                    │                 (Junction Table)
    │                    │
    ↓                    ↓
Reservations        Fine_Payments
    │
    │
Staff (1) ──────→ (M) [Various Operations]
🏗️ Table Structure
1. categories
Organizes books into different categories for better classification.
Purpose: Book categorization and organization
sqlCREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
Key Features:

Unique category names prevent duplicates
Descriptive text for detailed category information
Automatic timestamp tracking

2. authors
Stores detailed information about book authors.
Purpose: Author information management
sqlCREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_author (first_name, last_name, birth_date)
);
Key Features:

Composite unique constraint prevents duplicate author entries
Optional biographical information
International author support with nationality field

3. publishers
Manages publishing house information.
Purpose: Publisher details and contact information
sqlCREATE TABLE publishers (
    publisher_id INT PRIMARY KEY AUTO_INCREMENT,
    publisher_name VARCHAR(100) NOT NULL UNIQUE,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
Key Features:

Unique publisher names and email addresses
Complete contact information storage
Website URL support for digital presence

4. books ⭐ (Core Entity)
Central table storing all book information and inventory details.
Purpose: Complete book inventory management
sqlCREATE TABLE books (
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
    
    CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL,
    CONSTRAINT chk_available_copies CHECK (available_copies <= total_copies)
);
Key Features:

ISBN uniqueness ensures no duplicate book records
Inventory tracking with total and available copies
Physical location tracking (shelf information)
Data integrity with check constraints
Automatic timestamp updates

5. book_authors (Junction Table)
Handles many-to-many relationships between books and authors.
Purpose: Multiple authors per book, multiple books per author
sqlCREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    author_role ENUM('Primary Author', 'Co-Author', 'Editor', 'Translator') DEFAULT 'Primary Author',
    PRIMARY KEY (book_id, author_id),
    
    CONSTRAINT fk_book_authors_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT fk_book_authors_author FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);
Key Features:

Composite primary key ensures unique book-author combinations
Role specification for different types of authorship
Cascade deletion maintains referential integrity

6. members ⭐ (Core Entity)
Stores library member information and membership details.
Purpose: Member registration and account management
sqlCREATE TABLE members (
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
Key Features:

Unique membership numbers for easy identification
Different membership types with varying privileges
Status tracking for account management
Fine tracking system
Customizable borrowing limits

7. staff
Library staff information for operational tracking.
Purpose: Staff management and operation logging
sqlCREATE TABLE staff (
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
Key Features:

Employee ID system for internal tracking
Position and department categorization
Employment status management
Salary information (optional, can be restricted)

8. transactions ⭐ (Core Entity)
Records all book borrowing, returning, and renewal activities.
Purpose: Complete transaction history and active loan tracking
sqlCREATE TABLE transactions (
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
    
    CONSTRAINT fk_transaction_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_transaction_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transaction_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= DATE(transaction_date))
);
Key Features:

Complete audit trail of all book movements
Status tracking for active vs. completed transactions
Fine calculation and tracking
Staff accountability through staff_id logging
Data validation with check constraints

9. reservations
Book reservation system for unavailable books.
Purpose: Allow members to reserve books that are currently borrowed
sqlCREATE TABLE reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    book_id INT NOT NULL,
    reservation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE NOT NULL,
    status ENUM('Active', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Active',
    priority_level INT DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    
    CONSTRAINT fk_reservation_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_reservation_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    CONSTRAINT unique_active_reservation UNIQUE (member_id, book_id, status)
);
Key Features:

Priority-based reservation system
Prevents duplicate active reservations
Automatic expiry management
Status tracking for reservation lifecycle

10. fine_payments
Tracks fine payments and maintains payment history.
Purpose: Financial transaction tracking for library fines
sqlCREATE TABLE fine_payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    transaction_id INT,
    payment_amount DECIMAL(10,2) NOT NULL CHECK (payment_amount > 0),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Online', 'Check') NOT NULL,
    staff_id INT,
    receipt_number VARCHAR(50) UNIQUE,
    
    CONSTRAINT fk_payment_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    CONSTRAINT fk_payment_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);
Key Features:

Multiple payment method support
Receipt number tracking for accounting
Links payments to specific transactions
Staff accountability for payment processing

🔗 Relationship Details
One-to-Many Relationships

Categories → Books: Each book belongs to one category
Publishers → Books: Each book has one publisher (optional)
Members → Transactions: Each transaction belongs to one member
Members → Reservations: Each reservation belongs to one member
Members → Fine_Payments: Each payment belongs to one member
Books → Transactions: Each transaction involves one book
Books → Reservations: Each reservation is for one book
Staff → Transactions: Each transaction may be processed by one staff member

Many-to-Many Relationships

Books ↔ Authors: Implemented through book_authors junction table

Books can have multiple authors
Authors can write multiple books
Authors can have different roles (Primary Author, Co-Author, Editor, Translator)



Foreign Key Constraints
Cascade Actions

ON DELETE CASCADE: Used for dependent records that should be deleted when parent is deleted

book_authors → books and authors
transactions → members
reservations → members and books
fine_payments → members


ON DELETE RESTRICT: Prevents deletion of referenced records

books → categories (cannot delete category with books)
transactions → books (cannot delete book with active transactions)


ON DELETE SET NULL: Sets foreign key to NULL when referenced record is deleted

books → publishers (book remains if publisher deleted)
transactions → staff (transaction remains if staff deleted)



📈 Indexes and Performance
Primary Indexes

All tables have PRIMARY KEY on their ID columns
Auto-increment ensures unique sequential IDs

Secondary Indexes
sql-- Performance optimization indexes
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
Index Strategy

Search Optimization: Indexes on frequently searched columns (title, ISBN, email)
Join Optimization: Foreign key columns automatically indexed
Filter Optimization: Status and type columns indexed for filtering operations

📊 Views for Common Queries
1. Available Books View
sqlCREATE VIEW available_books AS
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
2. Active Borrowings View
sqlCREATE VIEW active_borrowings AS
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
3. Member Summary View
sqlCREATE VIEW member_summary AS
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
✅ Data Integrity Features
Check Constraints

Positive Values: Pages, copies, fine amounts must be positive
Logical Constraints: Available copies cannot exceed total copies
Date Logic: Return date cannot be before transaction date
Range Validation: Priority levels between 1-5

Unique Constraints

ISBN: Prevents duplicate book entries
Email: Ensures unique member and staff emails
Membership Numbers: Unique member identification
Employee IDs: Unique staff identification
Receipt Numbers: Prevents duplicate payment receipts

NOT NULL Constraints

Essential Fields: Names, membership types, transaction types
Business Logic: Category required for books, member required for transactions

🔧 Setup Instructions
1. Database Creation
sql-- Create the database
CREATE DATABASE IF NOT EXISTS library_management_system
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Use the database
USE library_management_system;
2. User Setup (Optional)
sql-- Create dedicated database user
CREATE USER 'library_user'@'localhost' IDENTIFIED BY 'secure_password';

-- Grant appropriate privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON library_management_system.* TO 'library_user'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;
3. Import Schema
bash# Import the complete schema with sample data
mysql -u root -p library_management_system < database/schema.sql

# Or run the SQL file in your MySQL client
4. Verify Installation
sql-- Check all tables are created
SHOW TABLES;

-- Verify sample data
SELECT COUNT(*) as book_count FROM books;
SELECT COUNT(*) as member_count FROM members;
SELECT COUNT(*) as transaction_count FROM transactions;
📋 Sample Data
The schema includes comprehensive sample data:

10 Categories: Fiction, Non-Fiction, Science & Technology, etc.
5 Publishers: Major publishing houses
10 Authors: Famous authors across genres
5 Staff Members: Different roles and departments
5 Members: Various membership types
10 Books: Diverse collection with proper relationships
Complete Relationships: All junction tables populated

🚀 Advanced Features
Triggers (Optional Implementation)
sql-- Auto-update book availability on transaction
DELIMITER //
CREATE TRIGGER update_book_availability_on_borrow
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'Borrow' THEN
        UPDATE books 
        SET available_copies = available_copies - 1 
        WHERE book_id = NEW.book_id;
    END IF;
END//
DELIMITER ;
Stored Procedures (Optional Implementation)
sql-- Calculate member fine procedure
DELIMITER //
CREATE PROCEDURE CalculateMemberFine(IN member_id INT, OUT total_fine DECIMAL(10,2))
BEGIN
    SELECT SUM(fine_amount) INTO total_fine
    FROM transactions 
    WHERE member_id = member_id AND fine_amount > 0;
END//
DELIMITER ;
🔍 Query Examples
Common Operations
sql-- Find all available books by category
SELECT * FROM available_books WHERE category_name = 'Fiction';

-- Check overdue books
SELECT * FROM active_borrowings WHERE days_overdue > 0;

-- Get member borrowing history
SELECT b.title, t.transaction_date, t.due_date, t.return_date
FROM transactions t
JOIN books b ON t.book_id = b.book_id
WHERE t.member_id = 1
ORDER BY t.transaction_date DESC;

-- Find books by author
SELECT b.title, b.isbn, c.category_name
FROM books b
JOIN book_authors ba ON b.book_id = ba.book_id
JOIN authors a ON ba.author_id = a.author_id
JOIN categories c ON b.category_id = c.category_id
WHERE CONCAT(a.first_name, ' ', a.last_name) = 'George Orwell';
🛡️ Security Considerations
Access Control

Use dedicated database user with minimal required privileges
Implement application-level authentication
Log all administrative operations

Data Protection

Regular backups with encryption
Sensitive data handling (PII)
Audit trail maintenance

Performance Monitoring

Monitor slow queries
Regular index optimization
Database maintenance schedules# WK-8-DATABASE-ASSIGMENT
