CREATE PROCEDURE uspProductList AS 
BEGIN
SELECT product_name, list_price
FROM production.products ORDER BY product_name
END;

-- To excute it EXECUTE name or EXEC name
 EXEC uspProductList; 
 -- To modify the procedure right click on the procedure then chose modify Or use ALTER 

 EXEC uspProductList;
 -- Procedure with parameters
ALTER PROCEDURE uspProductList(@minprice AS DECIMAL) AS
BEGIN 
SELECT product_name, list_price
FROM production.products WHERE list_price> @minprice 
ORDER BY product_name;
END;

EXEC uspProductList 600 ;
ALTER PROCEDURE uspProductList(@minprice AS DECIMAL, @maxprice AS DECIMAL) AS
BEGIN 
SELECT product_name, list_price
FROM production.products WHERE list_price BETWEEN  @minprice  AND @maxprice
ORDER BY product_name;
END;

EXEC uspProductList 600,1000 ;


-- passing optional values to the procedures means if the user didnt enter values the procedure uses the default values 
ALTER PROCEDURE uspProductList(@minprice AS DECIMAL = 1000, @maxprice AS DECIMAL = 3000) AS
BEGIN 
SELECT product_name, list_price
FROM production.products WHERE list_price BETWEEN  @minprice  AND @maxprice
ORDER BY product_name;
END;

EXEC uspProductList ;


-- Return parameter or output parameter
ALTER PROCEDURE  uspFindProductbyModel(@modelyear SMALLINT , @productcount INT OUTPUT) AS
BEGIN 
SELECT product_name, list_price
FROM production.products WHERE model_year = @modelyear;

SELECT @productcount= @@ROWCOUNT;--  return number of rows
END;
GO  
DECLARE @count as int;
EXEC uspFindProductbyModel 
@modelyear = 1998,
@productcount = @count OUTPUT; 
SELECT @count;



-- Built in functions (string)
SELECT CHARINDEX('sql','sql server management');
SELECT CHARINDEX('sql','sql server management',6);-- specify the start point of search
SELECT REPLACE('water is better than cola','cola','pepsi');
SELECT SUBSTRING('sql server substring',5,6); -- start from 5 cut 6 its gonna return the word server
SELECT SUBSTRING(email ,charindex('@', email)+1,len(email)-charindex('@', email)) FROM sales.customers ORDER BY email;

-- Date functions
SELECT CURRENT_TIMESTAMP; -- gives you current date with hours,minutes and seconds
SELECT GETDATE(); -- guves you the current date 
SELECT DATEADD(day,5,GETDATE()); -- add to the current day 5 days here we specified that we are going to add to the day using the word day
SELECT EOMONTH(getdate()); -- the func gives you the last day of the month it has two parameters the first start date the date you want to evaluate.
-- month_to_add (optional) → number of months to add before calculating the end of month.
-- DATEDIFF ( datepart , startdate , enddate )
SELECT DATEDIFF(day, '2025-01-01', '2025-09-22');
SELECT DATEDIFF(month, '2025-01-01', '2025-09-22');
SELECT DATEDIFF(year, '2010-05-10', '2025-09-22');


-- USER DEFIEND FUNCTIONS
-- Functions can be called in the select statment unlike procedures


--TYPES OF FUNCTIONS
-- 1. Scalar functions: takes one or more parameters and returns only pne value
CREATE FUNCTION add_numbers(@n1 INT , @n2 INT) RETURNS INT 
AS 
BEGIN 
RETURN @n1+@n2;
END;

SELECT add_numbers(1,59); -- its not a built in function we have to call it by the full name

SELECT dbo.add_numbers(1,59); 

CREATE FUNCTION vat(@lprice DECIMAL) RETURNS DECIMAL 
AS 
BEGIN 
RETURN @lprice*0.15;
END;

SELECT dbo.vat(100);

SELECT product_id, product_name, list_price, dbo.vat(list_price) as valueAddedTax, list_price+dbo.vat(list_price) as totalPrice
FROM production.products;

-- Modify a scalar function
ALTER FUNCTION vat(@lprice DECIMAL) RETURNS DECIMAL 
AS 
BEGIN 
RETURN @lprice*0.15;
END;
--  when we are creating a func and we dont know if it exists we can use

-- Modify a scalar function
CREATE OR ALTER FUNCTION vat(@lprice DECIMAL) RETURNS DECIMAL 
AS 
BEGIN 
RETURN @lprice*0.15;
END;


-- assining a value to a var 
declare @modelyear as smallint;
set @modelyear =  2018;
-- storing query result in a var
declare @product_count int;
 set @product_count = ( SELECT COUNT(*) FROM production.products);



-- 2. Table valued functions: returns a table of values
-- How to declare table variables

DECLARE @product_table TABLE (
    product_name VARCHAR(MAX) NOT NULL,
    brand_id INT NOT NULL,
    list_price DEC(11,2) NOT NULL
);

INSERT INTO @product_table
SELECT
    product_name,
    brand_id,
    list_price
FROM
    production.products
WHERE
    category_id = 1; -- NOTE : you have to excute the declared var and the insert query at the same time so you dont get an error

SELECT
    *
FROM
    @product_table; -- also to print this you have to excute it with declaration and insert queries


-- Using table variables in user-defined functions
CREATE FUNCTION fncustomerorders(@cid int)
RETURNS @tblcustomersorders TABLE (orderno int , order_date DATE)
as 
BEGIN 
INSERT INTO @tblcustomersorders
SELECT order_id, order_date
from sales.orders where customer_id = @cid;
return;

END;
SELECT * FROM fncustomerorders(4);

SELECT * FROM fncustomerorders(4) fn join sales.order_items oi on fn.orderno = oi.order_id;

-- Creating a table-valued function

CREATE FUNCTION udfProductInYear (
    @model_year INT
)
RETURNS TABLE
AS
RETURN
    SELECT 
        product_name,
        model_year,
        list_price
    FROM
        production.products
    WHERE
        model_year = @model_year;

-- Executing a table-valued function
SELECT 
    * 
FROM 
    udfProductInYear(2017);








-- TSQL control of flow
-- 1. begin .... end : is used to define a statement block( a set of sql statements that excute together)
BEGIN
SELECT product_id,product_name FROM production.products WHERE list_price>100000;
IF @@ROWCOUNT = 0
print 'NO PRODUCT WITH THAT PRICE' ;

END;

-- 2. nested begin end 

BEGIN
    DECLARE @name VARCHAR(MAX);

    SELECT TOP 1
        @name = product_name
    FROM
        production.products
    ORDER BY
        list_price DESC;
    
    IF @@ROWCOUNT <> 0
    BEGIN
        PRINT 'The most expensive product is ' + @name
    END
    ELSE
    BEGIN
        PRINT 'No product found';
    END;
END




 -- 3. IF 
 BEGIN
    DECLARE @sales INT;

    SELECT 
        @sales = SUM(list_price * quantity)
    FROM
        sales.order_items i
        INNER JOIN sales.orders o ON o.order_id = i.order_id
    WHERE
        YEAR(order_date) = 2018;

    SELECT @sales;

    IF @sales > 1000000
    BEGIN
        PRINT 'Great! The sales amount in 2018 is greater than 1,000,000';
    END
END
 -- 4. IF ELSE 
 BEGIN
    DECLARE @sales INT;

    SELECT 
        @sales = SUM(list_price * quantity)
    FROM
        sales.order_items i
        INNER JOIN sales.orders o ON o.order_id = i.order_id
    WHERE
        YEAR(order_date) = 2017;

    SELECT @sales;

    IF @sales > 10000000
    BEGIN
        PRINT 'Great! The sales amount in 2018 is greater than 10,000,000';
    END
    ELSE
    BEGIN
        PRINT 'Sales amount in 2017 did not reach 10,000,000';
    END
END


 -- 5. Nested if else

 BEGIN
    DECLARE @x INT = 10,
            @y INT = 20;

    IF (@x > 0)
    BEGIN
        IF (@x < @y)
            PRINT 'x > 0 and x < y';
        ELSE
            PRINT 'x > 0 and x >= y';
    END			
END


-- SQL Server WHILE
DECLARE @counter INT = 1;

WHILE @counter <= 5
BEGIN
    PRINT @counter;
    SET @counter = @counter + 1;
END

-- SQL Server CONTINUE : The CONTINUE statement stops the current iteration of the loop and starts the new one.
-- WHILE Boolean_expression
--BEGIN
    -- code to be executed
   -- IF condition
      --  CONTINUE;
    -- code will be skipped if the condition is met
--END
DECLARE @counter INT = 0;

WHILE @counter < 5
BEGIN
    SET @counter = @counter + 1;
    IF @counter = 3
        CONTINUE;	
    PRINT @counter;
END



-- SQL Server BREAK : the BREAK statement exit the WHILE loop immediately once the condition in the IF statement is met.
DECLARE @counter INT = 0;

WHILE @counter <= 5
BEGIN
    SET @counter = @counter + 1;
    IF @counter = 4
        BREAK;
    PRINT @counter;
END

-- Execption handling
-- 1. TRY CATCH : allows you to gracefully handle exceptions in SQL Server.

-- ERROR_LINE() returns the line number on which the exception occurred.
-- ERROR_MESSAGE() returns the complete text of the generated error message.
-- ERROR_PROCEDURE() returns the name of the stored procedure or trigger where the error occurred.
-- ERROR_NUMBER() returns the number of the error that occurred.
-- ERROR_SEVERITY() returns the severity level of the error that occurred.
-- ERROR_STATE() returns the state number of the error that occurred.

CREATE PROC usp_divide(
    @a decimal,
    @b decimal,
    @c decimal output
) AS
BEGIN
    BEGIN TRY
        SET @c = @a / @b;
    END TRY
    BEGIN CATCH
        SELECT  
            ERROR_NUMBER() AS ErrorNumber  -- the result of this is 8134
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  
    END CATCH
END;
GO
-- now if we want to print a message instead of the result of these functions we should use their results
ALTER PROC usp_divide(
    @a decimal,
    @b decimal,
    @c decimal output
) AS
BEGIN
    BEGIN TRY
        SET @c = @a / @b;
    END TRY
    BEGIN CATCH
        if ERROR_NUMBER() = 8134
		print 'you cant divide by 0, enter non 0 values';
           
    END CATCH
END;
GO

DECLARE @r DECIMAL;
EXEC usp_divide 10,0, @r output;
PRINT @r;


-- TRIGGERS:

--CREATE TRIGGER [schema_name.]trigger_name
--ON table_name
--AFTER or BEFORE  {[INSERT],[UPDATE],[DELETE]}
--[NOT FOR REPLICATION]
--AS
--{sql_statements}


CREATE TABLE production.product_audits( -- create a table to save in it any changes done on the product table
    change_id INT IDENTITY PRIMARY KEY,
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year SMALLINT NOT NULL,
    list_price DEC(10,2) NOT NULL,
    updated_at DATETIME NOT NULL,
    operation CHAR(3) NOT NULL,
    CHECK(operation = 'INS' or operation='DEL')
);


CREATE TRIGGER production.trg_product_audit
ON production.products
AFTER INSERT, DELETE -- isert or delete 
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO production.product_audits(
        product_id, 
        product_name,
        brand_id,
        category_id,
        model_year,
        list_price, 
        updated_at, 
        operation
    )
    SELECT
        i.product_id,
        product_name,
        brand_id,
        category_id,
        model_year,
        i.list_price,
        GETDATE(),
        'INS'
    FROM
        inserted i
    UNION ALL
    SELECT
        d.product_id,
        product_name,
        brand_id,
        category_id,
        model_year,
        d.list_price,
        GETDATE(),
        'DEL'
    FROM
        deleted d;
END
