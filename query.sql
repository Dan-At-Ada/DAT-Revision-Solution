

-- DreamHome Agency Data Requests

-- 1. Property Management Department

-- Request 1.1: List of all property postcodes
SELECT DISTINCT postcode AS PropertyPostcode
FROM propertyforrent
ORDER BY postcode;

-- Request 1.2: Properties and their viewing history
SELECT 
    p.propertyno,
    p.street,
    p.city,
    p.postcode,
    COALESCE(MAX(v.viewdate), 'Not Viewed') AS last_viewing_date
FROM 
    propertyforrent p
LEFT JOIN 
    viewing v ON p.propertyno = v.propertyno
GROUP BY 
    p.propertyno, p.street, p.city, p.postcode
ORDER BY 
    p.propertyno;

-- Request 1.3: Properties with postcode starting 'BS1'
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM propertyforrent WHERE postcode LIKE 'BS1%')
        THEN 'Yes'
        ELSE 'No'
    END AS has_bs1_properties;

-- 2. Client Relations Team

-- Request 2.1: Properties managed by client 'CL5612'
SELECT p.*
FROM propertyforrent p
JOIN privateowner o ON p.ownerno = o.ownerno
WHERE o.ownerno = 'CL5612';

-- Request 2.2: Recent client registrations at branch 'B052'
SELECT 
    r.reg_id,
    c.fname || ' ' || c.lname AS client_name,
    r.datejoined,
    s.fname || ' ' || s.lname AS staff_name
FROM 
    registration r
JOIN 
    client c ON r.clientno = c.clientno
JOIN 
    staff s ON r.staffno = s.staffno
WHERE 
    r.branchno = 'B052' 
    AND r.datejoined > '2013-09-28'
ORDER BY 
    r.datejoined;

-- Request 2.3: Most recent property viewing
SELECT 
    v.view_id,
    p.street || ', ' || p.city || ', ' || p.postcode AS property_address,
    c.fname || ' ' || c.lname AS client_name,
    v.viewdate,
    v.comment
FROM 
    viewing v
JOIN 
    propertyforrent p ON v.propertyno = p.propertyno
JOIN 
    client c ON v.clientno = c.clientno
WHERE 
    v.viewdate = (SELECT MAX(viewdate) FROM viewing);

-- 3. Marketing and Sales Team

-- Request 3.1: Property owners with first name starting with 'C'
SELECT ownerno, fname, lname, email
FROM privateowner
WHERE fname LIKE 'C%'
ORDER BY lname, fname;

-- Request 3.2: Categorize properties based on rent
SELECT 
    propertyno,
    rent,
    CASE 
        WHEN rent < 500 THEN 'Budget'
        WHEN rent BETWEEN 500 AND 1000 THEN 'Standard'
        ELSE 'Premium'
    END AS category
FROM 
    propertyforrent
ORDER BY 
    rent;

-- Request 3.3: Unified mailing list
SELECT fname, lname, 'Client' AS type
FROM client
UNION ALL
SELECT fname, lname, 'Owner' AS type
FROM privateowner
ORDER BY lname, fname;

-- 4. Finance and Investment Department

-- Request 4.1: Comprehensive list of rental properties with owner details
SELECT 
    p.propertyno,
    p.street,
    p.city,
    p.postcode,
    p.type,
    p.rooms,
    p.rent,
    o.fname || ' ' || o.lname AS owner_name,
    o.email AS owner_email
FROM 
    propertyforrent p
JOIN 
    privateowner o ON p.ownerno = o.ownerno
ORDER BY 
    p.propertyno;

-- Request 4.2: High-value properties report
WITH avg_rent AS (
    SELECT AVG(rent) AS average_rent FROM propertyforrent
)
SELECT 
    p.propertyno,
    p.street,
    p.city,
    p.rent
FROM 
    propertyforrent p, avg_rent
WHERE 
    p.rent > avg_rent.average_rent
ORDER BY 
    p.rent DESC;

-- Request 4.3: Increase rent for London properties by 10%
BEGIN TRANSACTION;

UPDATE propertyforrent
SET rent = rent * 1.1
WHERE city = 'London';

-- Display the number of updated properties and the average rent increase
SELECT 
    COUNT(*) AS properties_updated,
    AVG(rent * 0.1) AS average_rent_increase
FROM 
    propertyforrent
WHERE 
    city = 'London';

COMMIT;

-- 5. Operations and HR Team

-- Request 5.1: Properties managed by staff member 'SSU15'
SELECT 
    COUNT(*) AS properties_managed,
    s.fname || ' ' || s.lname AS staff_name
FROM 
    propertyforrent p
JOIN 
    staff s ON p.staffno = s.staffno
WHERE 
    s.staffno = 'SSU15'
GROUP BY 
    s.staffno, s.fname, s.lname;

-- Request 5.2: Number of properties in each city (more than 2 properties)
SELECT 
    city,
    COUNT(*) AS property_count
FROM 
    propertyforrent
GROUP BY 
    city
HAVING 
    COUNT(*) > 2
ORDER BY 
    property_count DESC;

-- Request 5.3: Staff managing properties with above-average rent
WITH avg_rent AS (
    SELECT AVG(rent) AS average_rent FROM propertyforrent
)
SELECT DISTINCT
    s.staffno,
    s.fname || ' ' || s.lname AS staff_name,
    COUNT(p.propertyno) AS high_value_properties_managed
FROM 
    staff s
JOIN 
    propertyforrent p ON s.staffno = p.staffno
CROSS JOIN 
    avg_rent
WHERE 
    p.rent > avg_rent.average_rent
GROUP BY 
    s.staffno, s.fname, s.lname
ORDER BY 
    high_value_properties_managed DESC;

-- 6. Executive and IT Department

-- Request 6.1: List of cities with branch office or property for rent
SELECT city FROM (
    SELECT city FROM branch
    UNION
    SELECT city FROM propertyforrent
) AS combined_cities
ORDER BY city;

-- Request 6.2: Create property_reviews table
CREATE TABLE property_reviews (
    review_id INTEGER PRIMARY KEY AUTOINCREMENT,
    propertyno CHAR(4),
    clientno CHAR(4),
    review_date DATE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    FOREIGN KEY (propertyno) REFERENCES propertyforrent(propertyno),
    FOREIGN KEY (clientno) REFERENCES client(clientno)
);

-- Request 6.3: Insert initial reviews
INSERT INTO property_reviews (propertyno, clientno, review_date, rating, comment)
VALUES
    ('PR1423', 'CL7623', '2023-05-15', 4, 'Spacious and well-maintained property. Great location.'),
    ('PR9478', 'CL5612', '2023-05-16', 5, 'Excellent modern amenities. Highly recommended!'),
    ('PR4567', 'CL7489', '2023-05-17', 3, 'Decent property, but needs some minor repairs.'),
    ('PR3689', 'CL6234', '2023-05-18', 4, 'Good value for money. Nice neighborhood.'),
    ('PR2145', 'CL7712', '2023-05-19', 2, 'Disappointing. Several issues with plumbing and heating.');

-- Request 6.4: Remove old property viewings
BEGIN TRANSACTION;

-- First, count the number of records to be deleted
SELECT COUNT(*) AS records_to_delete
FROM viewing
WHERE viewdate < '2013-06-01';

-- Then, delete the old records
DELETE FROM viewing
WHERE viewdate < '2013-06-01';

-- Finally, confirm the number of deleted records
SELECT 
    'Deleted Viewings' AS action,
    changes() AS count;

COMMIT;
