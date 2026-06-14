-- Football Ticket Booking System

-- Drop tables

DROP TABLE IF EXISTS Bookings;
DROP TABLE IF EXISTS Matches;
DROP TABLE IF EXISTS Users;

-- Users Table

CREATE TABLE Users (
    user_id      INT           NOT NULL,
    full_name    VARCHAR(100)  NOT NULL,
    email        VARCHAR(150)  NOT NULL,
    role         VARCHAR(50)   NOT NULL,
    phone_number VARCHAR(20),

    -- Primary Key
    CONSTRAINT pk_users
        PRIMARY KEY (user_id),

    -- Each email must be unique across all users
    CONSTRAINT uq_users_email
        UNIQUE (email),

    -- Role must be one of the allowed values
    CONSTRAINT chk_users_role
        CHECK (role IN ('Football Fan', 'Ticket Manager', 'Admin'))
);



-- Matches Table Create

CREATE TABLE Matches (
    match_id             INT            NOT NULL,
    fixture              VARCHAR(200)   NOT NULL,
    tournament_category  VARCHAR(100)   NOT NULL,
    base_ticket_price    DECIMAL(10,2)  NOT NULL,
    match_status         VARCHAR(50)    NOT NULL,

    -- Primary Key
    CONSTRAINT pk_matches
        PRIMARY KEY (match_id),

    -- Ticket price cannot be negative
    CONSTRAINT chk_matches_price
        CHECK (base_ticket_price >= 0),

    -- Status must be one of the allowed values
    CONSTRAINT chk_matches_status
        CHECK (match_status IN ('Available', 'Selling Fast', 'Sold Out'))
);


-- Bookings Table Create

CREATE TABLE Bookings (
    booking_id     INT            NOT NULL,
    user_id        INT,
    match_id       INT,
    seat_number    VARCHAR(20),
    payment_status VARCHAR(50),
    total_cost     DECIMAL(10,2)  NOT NULL,

    -- Primary Key
    CONSTRAINT pk_bookings
        PRIMARY KEY (booking_id),

    -- Foreign Key → Users table
    CONSTRAINT fk_bookings_user
        FOREIGN KEY (user_id) REFERENCES Users(user_id),

    -- Foreign Key → Matches table
    CONSTRAINT fk_bookings_match
        FOREIGN KEY (match_id) REFERENCES Matches(match_id),

    -- Total cost must be zero or positive
    CONSTRAINT chk_bookings_cost
        CHECK (total_cost >= 0),

    -- Payment status must be one of the allowed values (or NULL)
    CONSTRAINT chk_bookings_payment
        CHECK (payment_status IN ('Confirmed', 'Pending', 'Cancelled')
               OR payment_status IS NULL)
);



-- Insert Users

INSERT INTO Users (user_id, full_name, email, role, phone_number) VALUES
(1, 'Tanvir Rahman', 'tanvir@mail.com', 'Football Fan',    '+8801711111111'),
(2, 'Asif Haque',   'asif@mail.com',   'Football Fan',    '+8801722222222'),
(3, 'Sajjad Rahman','sajjad@mail.com', 'Ticket Manager',  '+8801733333333'),
(4, 'Jannat Ara',   'jannat@mail.com', 'Football Fan',    NULL);



-- Insert Matches

INSERT INTO Matches (match_id, fixture, tournament_category, base_ticket_price, match_status) VALUES
(101, 'Real Madrid vs Barcelona', 'Champions League', 150.00, 'Available'),
(102, 'Man City vs Liverpool',    'Premier League',   120.00, 'Selling Fast'),
(103, 'Bayern Munich vs PSG',     'Champions League', 130.00, 'Available'),
(104, 'AC Milan vs Inter Milan',  'Serie A',           90.00, 'Sold Out'),
(105, 'Juventus vs Roma',         'Serie A',           80.00, 'Available');


-- Insert Bookings

INSERT INTO Bookings (booking_id, user_id, match_id, seat_number, payment_status, total_cost) VALUES
(501, 1, 101, 'A-12', 'Confirmed', 150.00),
(502, 1, 102, 'B-04', 'Confirmed', 120.00),
(503, 2, 101, 'A-13', 'Confirmed', 150.00),
(504, 2, 101,  NULL,   NULL,       150.00),
(505, 3, 102, 'C-20', 'Pending',  120.00);



-- Query 1:
-- Retrieve all upcoming matches belonging to 'Champions League'
--
-- Expected Output:
-- match_id | fixture                  | base_ticket_price | match_status
-- ---------+--------------------------+-------------------+-------------
-- 101      | Real Madrid vs Barcelona | 150.00            | Available
-- 103      | Bayern Munich vs PSG     | 130.00            | Available
-- ------------------------------------------------------------
SELECT match_id,
       fixture,
       base_ticket_price,
       match_status
FROM   Matches
WHERE  tournament_category = 'Champions League'
  AND  match_status = 'Available';


-- ------------------------------------------------------------
-- Query 2:
-- Search for all users whose full_name starts with 'Tanvir'
-- OR contains the phrase 'haque' (case-insensitive).
--
-- Expected Output:
-- user_id | full_name     | email
-- --------+---------------+----------------
-- 1       | Tanvir Rahman | tanvir@mail.com
-- 2       | Asif Haque    | asif@mail.com
-- ------------------------------------------------------------
SELECT user_id,
       full_name,
       email
FROM   Users
WHERE  full_name LIKE 'Tanvir%'
   OR  LOWER(full_name) LIKE '%haque%';


-- ------------------------------------------------------------
-- Query 3:
-- Retrieve all booking records where payment_status is NULL,
-- replacing the NULL with 'Action Required'.
--
-- Expected Output:
-- booking_id | user_id | match_id | seat_number | payment_status  | total_cost
-- -----------+---------+----------+-------------+-----------------+-----------
-- 504        | 2       | 101      | NULL        | Action Required | 150.00
-- ------------------------------------------------------------
SELECT booking_id,
       user_id,
       match_id,
       seat_number,
       COALESCE(payment_status, 'Action Required') AS payment_status,
       total_cost
FROM   Bookings
WHERE  payment_status IS NULL;


-- ------------------------------------------------------------
-- Query 4:
-- Retrieve booking details along with the User's full_name
-- and the scheduled Match fixture name (JOIN query).
--
-- Expected Output:
-- booking_id | full_name     | fixture                  | seat_number | payment_status | total_cost
-- -----------+---------------+--------------------------+-------------+----------------+-----------
-- 501        | Tanvir Rahman | Real Madrid vs Barcelona | A-12        | Confirmed      | 150.00
-- 502        | Tanvir Rahman | Man City vs Liverpool    | B-04        | Confirmed      | 120.00
-- 503        | Asif Haque    | Real Madrid vs Barcelona | A-13        | Confirmed      | 150.00
-- 504        | Asif Haque    | Real Madrid vs Barcelona | NULL        | NULL           | 150.00
-- 505        | Sajjad Rahman | Man City vs Liverpool    | C-20        | Pending        | 120.00
-- ------------------------------------------------------------
SELECT b.booking_id,
       u.full_name,
       m.fixture,
       b.seat_number,
       b.payment_status,
       b.total_cost
FROM   Bookings b
JOIN   Users    u ON b.user_id  = u.user_id
JOIN   Matches  m ON b.match_id = m.match_id
ORDER  BY b.booking_id;


-- ------------------------------------------------------------
-- Query 5:
-- Display a comprehensive list of all users and their
-- booking count & total spend (users with no bookings
-- must still appear with 0 count and NULL total).
--
-- Expected Output:
-- user_id | full_name     | total_bookings | total_spend
-- --------+---------------+----------------+------------
-- 1       | Tanvir Rahman | 2              | 270.00
-- 2       | Asif Haque    | 2              | 300.00
-- 3       | Sajjad Rahman | 1              | 120.00
-- 4       | Jannat Ara    | 0              | NULL
-- ------------------------------------------------------------
SELECT u.user_id,
       u.full_name,
       COUNT(b.booking_id)  AS total_bookings,
       SUM(b.total_cost)    AS total_spend
FROM   Users u
LEFT JOIN Bookings b ON u.user_id = b.user_id
GROUP  BY u.user_id, u.full_name
ORDER  BY u.user_id;


-- ------------------------------------------------------------
-- Query 6:
-- Find all ticket bookings where the total_cost is strictly
-- higher than the average cost of all ticket bookings.
--
-- Expected Output:
-- booking_id | match_id | total_cost
-- -----------+----------+-----------
-- 501        | 101      | 150.00
-- 503        | 101      | 150.00
-- 504        | 101      | 150.00
-- ------------------------------------------------------------
SELECT booking_id,
       match_id,
       total_cost
FROM   Bookings
WHERE  total_cost > (SELECT AVG(total_cost) FROM Bookings)
ORDER  BY booking_id;


-- ------------------------------------------------------------
-- Query 7:
-- Retrieve the top 2 most expensive matches ranked by
-- base_ticket_price, skipping the absolute highest premium.
--
-- Expected Output:
-- match_id | fixture                  | tournament_category | base_ticket_price
-- ---------+--------------------------+---------------------+------------------
-- 101      | Real Madrid vs Barcelona | Champions League    | 150.00
-- 103      | Bayern Munich vs PSG     | Champions League    | 130.00
-- ------------------------------------------------------------
SELECT match_id,
       fixture,
       tournament_category,
       base_ticket_price
FROM   Matches
ORDER  BY base_ticket_price DESC
LIMIT  2;