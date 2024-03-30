DimBranch
CREATE TABLE [dbo].[DimBranch](
	[branch_id] [int] NOT NULL,
	[branch_name] [varchar](50) NULL,
	[branch_location] [varchar](50) NULL,
 CONSTRAINT [PK_branch] PRIMARY KEY CLUSTERED 
(
	[branch_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

DimCustomer
CREATE TABLE [dbo].[DimCustomer](
	[CustomerID] [int] NOT NULL,
	[CustomerName] [varchar](50) NULL,
	[Address] [varchar](max) NULL,
	[CityName] [varchar](50) NULL,
	[StateName] [varchar](50) NULL,
	[Age] [varchar](3) NULL,
	[Gender] [varchar](10) NULL,
	[Email] [varchar](50) NULL,
 CONSTRAINT [PK_CustomerID] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


DimAccount
CREATE TABLE [dbo].[DimAccount](
	[account_id] [int] NOT NULL,
	[customer_id] [int] NULL,
	[account_type] [varchar](10) NULL,
	[balance] [int] NULL,
	[date_opened] [datetime2](0) NULL,
	[status] [varchar](10) NULL,
 CONSTRAINT [PK_account] PRIMARY KEY CLUSTERED 
(
	[account_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DimAccount]  WITH CHECK ADD  CONSTRAINT [FK_customer_id] FOREIGN KEY([customer_id])
REFERENCES [dbo].[DimCustomer] ([CustomerID])
GO

ALTER TABLE [dbo].[DimAccount] CHECK CONSTRAINT [FK_customer_id]



FactTransaction
CREATE TABLE [dbo].[FactTransaction](
	[transaction_id] [int] NOT NULL,
	[account_id] [int] NULL,
	[transaction_date] [datetime2](0) NULL,
	[amount] [int] NULL,
	[transaction_type] [varchar](50) NULL,
	[branch_id] [int] NULL,
 CONSTRAINT [PK_transaction] PRIMARY KEY CLUSTERED 
(
	[transaction_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[FactTransaction]  WITH CHECK ADD  CONSTRAINT [FK_account] FOREIGN KEY([account_id])
REFERENCES [dbo].[DimAccount] ([account_id])
GO

ALTER TABLE [dbo].[FactTransaction] CHECK CONSTRAINT [FK_account]
GO

ALTER TABLE [dbo].[FactTransaction]  WITH CHECK ADD  CONSTRAINT [FK_branch] FOREIGN KEY([branch_id])
REFERENCES [dbo].[DimBranch] ([branch_id])
GO

ALTER TABLE [dbo].[FactTransaction] CHECK CONSTRAINT [FK_branch]
GO

CREATE STORE PROCEDURE

DailyTransaction
CREATE OR ALTER PROCEDURE DailyTransaction 
    @start_date DATE,
    @end_date DATE
AS
BEGIN
    SELECT CAST(transaction_date AS DATE) AS 'Date',
	COUNT(transaction_id) AS 'TotalTransactions',
	SUM(amount) AS 'TotalAmount'
    FROM [DWH].[dbo].[FactTransaction]
    WHERE transaction_date BETWEEN @start_date AND @end_date
    GROUP BY CAST(transaction_date AS DATE)
END;

EXEC DailyTransaction @start_date = '2024-01-18', @end_date = '2024-01-21'







BalancePerCustomer 
CREATE OR ALTER PROCEDURE [dbo].[BalancePerCustomer] 
    @name varchar(255) = '%'  
AS
BEGIN
    WITH tablea AS (
        SELECT 
            c.transaction_id, 
            a.CustomerName, 
            c.transaction_date,
            b.account_type, 
            b.balance,
            SUM(c.amount) OVER (PARTITION BY a.customername, b.account_type) AS 'Amount',
            c.transaction_type
        FROM 
            [DimCustomer] a
        LEFT JOIN 
            DimAccount b ON a.customerid = b.customer_id
        LEFT JOIN 
            FactTransaction c ON b.account_id = c.account_id
        WHERE 
            b.status = 'active'
    )

    SELECT 
        DISTINCT CustomerName, 
        account_type as 'AccountType', 
        balance as 'Balance',
        CASE 
            WHEN transaction_type = 'Deposit' THEN balance + amount
            ELSE balance - amount
        END AS 'CurrentBalance'
    FROM 
        tablea
	WHERE 
		CustomerName LIKE '%' + @name + '%'
    ORDER BY 
        CustomerName, account_type;

END;
GO
EXEC [BalancePerCustomer] @name = 'Shelly' 
