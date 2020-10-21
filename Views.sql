
\upos
CREATE OR REPLACE VIEW v_Customers
AS
SELECT lastName, firstName, email, address, city, state, z.zip
FROM Customer c
INNER JOIN Zip z ON c.zip = z.zip
ORDER BY lastName, firstName, birthDate;


CREATE OR REPLACE VIEW v_CustomerProducts
AS
SELECT lastName, firstName, GROUP_CONCAT(DISTINCT app ORDER BY app) AS "apps"
FROM Customer c
LEFT OUTER JOIN `Order` o ON c.id = o.customerID
LEFT OUTER JOIN OrderLine ol ON o.id = ol.orderID
LEFT OUTER JOIN Product p ON ol.productID = p.id
GROUP BY c.id
ORDER BY 1, 2;

CREATE OR REPLACE VIEW v_ProductCustomers
AS
SELECT app, p.id AS "productID", GROUP_CONCAT(DISTINCT CONCAT(lastName, " ", firstName) ORDER BY lastName, firstName separator', ') AS "customers"
FROM Product p
LEFT OUTER JOIN OrderLine ol ON p.id = ol.productID
LEFT OUTER JOIN `Order` o ON ol.orderID = o.id
LEFT OUTER JOIN Customer c ON o.customerID = c.id 
GROUP BY 2
ORDER BY 2;

DROP TABLE IF EXISTS mv_ProductCustomers;
CREATE TABLE mv_ProductCustomers
(
app TEXT,
productID INT PRIMARY KEY,
customers TEXT
) ENGINE=InnoDB;

INSERT INTO mv_ProductCustomers 
SELECT app, p.id AS "productID", GROUP_CONCAT(DISTINCT CONCAT(lastName, " ", firstName) ORDER BY lastName, firstName separator', ') AS "customers"
FROM Product p
LEFT OUTER JOIN OrderLine ol ON p.id = ol.productID
LEFT OUTER JOIN `Order` o ON ol.orderID = o.id
LEFT OUTER JOIN Customer c ON o.customerID = c.id 
GROUP BY 2
ORDER BY 2;



