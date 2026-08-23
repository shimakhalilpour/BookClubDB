CREATE DATABASE BookClub
USE BookClub

CREATE TABLE Roles 
(
    RoleID INT IDENTITY(1,1) PRIMARY KEY, 
    RoleTitle NVARCHAR(20) NOT NULL
    CHECK(RoleTitle IN ('NormalUser','Publisher','Admin'))
);

INSERT INTO Roles (RoleTitle)
VALUES
('NormalUser'),
('Publisher'),
('Admin');

CREATE TABLE Users
(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(20) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(120) NOT NULL,
    IsBlocked BIT NOT NULL DEFAULT 0,
    IsDeleted BIT NOT NULL DEFAULT 0,
    RegisterDate DATETIME2(0) NOT NULL
        DEFAULT GETDATE(),
    RoleID INT NOT NULL
    CHECK (RoleID BETWEEN 1 AND 3),

    CONSTRAINT FK_Users_Roles
    FOREIGN KEY(RoleID)
    REFERENCES Roles(RoleID)
);
ALTER TABLE Users
ADD IsActive BIT NOT NULL DEFAULT 1

CREATE TABLE NormalUsers
(
    UserID INT PRIMARY KEY,
    SecurityAnswerHash NVARCHAR(100) NOT NULL,

    CONSTRAINT FK_NormalUsers_Users
    FOREIGN KEY(UserID)
    REFERENCES Users(UserID)
);

CREATE TABLE Publishers
(
    UserID INT PRIMARY KEY,
    FirstName NVARCHAR(30) NOT NULL,
    LastName NVARCHAR(30) NOT NULL,
    Email NVARCHAR(120) NOT NULL UNIQUE,
    ShortDescription NVARCHAR(500) NULL,
    PublicationName NVARCHAR(50) NOT NULL,
    PublisherLicenseNumber NVARCHAR(13) NOT NULL UNIQUE,
    SecurityAnswerHash NVARCHAR(100) NOT NULL,

    CONSTRAINT FK_Publishers_Users
    FOREIGN KEY(UserID)
    REFERENCES Users(UserID)  
);

ALTER TABLE Publishers
WITH NOCHECK
ADD CONSTRAINT CK_Publishers_PublisherLicenseNumber
CHECK (
    LEN(PublisherLicenseNumber) BETWEEN 10 AND 13
    AND PublisherLicenseNumber NOT LIKE '%[^0-9]%'
);

CREATE TABLE ApplicationAdmins
(
    UserID INT PRIMARY KEY,
    FirstName NVARCHAR(30) NOT NULL,
    LastName NVARCHAR(30) NOT NULL, 

    CONSTRAINT FK_ApplicationAdmins_Users
    FOREIGN KEY(UserID)
    REFERENCES Users(UserID)
);

-- ثبت در جدول Users
INSERT INTO Users
(
    Username,
    PasswordHash,
    RoleID
)
VALUES
(
    'Admin',
    'Admin1234',
    3
);

-- ثبت در جدول ApplicationAdmins
INSERT INTO ApplicationAdmins
(
    UserID,
    FirstName,
    LastName
)
VALUES
(
    SCOPE_IDENTITY(),
    N'مهشید',
    N'قطب زاده'
);

CREATE TABLE Genres
(
    GenreID INT IDENTITY(1,1) PRIMARY KEY,
    GenreTitle NVARCHAR(30) NOT NULL UNIQUE
);
INSERT INTO Genres(GenreTitle)
VALUES
(N'فانتزی'),
(N'علمی تخیلی'),
(N'جنایی و معمایی'),
(N'وحشت'),
(N'عاشقانه'),
(N'تاریخی'),
(N'رئالیسم جادویی'),
(N'درام'),
(N'زندگینامه'),
(N'خودیاری و روانشناسی'),
(N'فلسفه'),
(N'علمی'),
(N'سفرنامه'),
(N'مدیریت و کسب و کار'),
(N'کمیک و مانگا');

CREATE TABLE Categories
(
    CategoryID INT IDENTITY(1,1) PRIMARY KEY, 
    CategoryTitle NVARCHAR(50) NOT NULL
);

CREATE TABLE Authors
(
    AuthorID INT IDENTITY(1,1) PRIMARY KEY,
    AuthorName NVARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE Books
(
    BookID INT IDENTITY(1,1) PRIMARY KEY,
    BookName NVARCHAR(60) NOT NULL,
    BookDescription NVARCHAR(MAX) NOT NULL,
    BookPrice DECIMAL(10,2) NOT NULL
    CHECK (BookPrice >= 0),
    DiscountPercent DECIMAL(5,2) DEFAULT 0
    CHECK (DiscountPercent BETWEEN 0 AND 100),
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0
    CHECK (DiscountAmount >= 0),
    CoverImagePath NVARCHAR(600),
    PDFfilePath NVARCHAR(600),
    RegisteredIn DATETIME2(0) NOT NULL DEFAULT GETDATE(),
    IsActive BIT NOT NULL DEFAULT 1,
    IsDeleted BIT NOT NULL DEFAULT 0,
    GenreID INT NOT NULL,
    CategoryID INT NOT NULL,
    AuthorID INT NOT NULL,
    PublisherUserID INT NOT NULL,

    CONSTRAINT FK_Books_Genres
    FOREIGN KEY (GenreID)
    REFERENCES Genres(GenreID),

    CONSTRAINT FK_Books_Authors
    FOREIGN KEY (AuthorID)
    REFERENCES Authors(AuthorID),

    CONSTRAINT FK_Books_Publishers
    FOREIGN KEY (PublisherUserID)
    REFERENCES Publishers(UserID),

    CONSTRAINT FK_Books_Categories
    FOREIGN KEY (CategoryID)
    REFERENCES Categories(CategoryID)
);

CREATE TABLE TimedDiscount
(
    DiscountID INT IDENTITY(1,1) PRIMARY KEY,
    BookID INT NOT NULL,
    DiscountPercent DECIMAL(5,2)
    CHECK (DiscountPercent BETWEEN 0 AND 100),
    StartDate DATETIME2(0) NOT NULL,
    EndDate DATETIME2(0) NOT NULL,

    CONSTRAINT CK_TimedDiscount_Dates
    CHECK (StartDate < EndDate),

    CONSTRAINT FK_TimedDiscount_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID)
);

CREATE TABLE FavouriteGenre
(
  FavouriteGenreID INT IDENTITY(1,1) PRIMARY KEY,
  UserID INT NOT NULL,
  GenreID INT NOT NULL,

  CONSTRAINT UQ_FavouriteGenre
  UNIQUE(UserID, GenreID),

  CONSTRAINT FK_FavouriteGenre_Users
  FOREIGN KEY (UserID)
  REFERENCES Users(UserID),

  CONSTRAINT FK_FavouriteGenre_Genres
  FOREIGN KEY (GenreID)
  REFERENCES Genres(GenreID)
);

CREATE TABLE ShoppingCarts
(
    CartID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL UNIQUE,

    CONSTRAINT FK_ShoppingCarts_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID)
);

CREATE TABLE CartItems
(
    CartItemID INT IDENTITY(1,1) PRIMARY KEY,
    CartID INT NOT NULL,
    BookID INT NOT NULL,

    CONSTRAINT UQ_CartItems
    UNIQUE(CartID, BookID),

    CONSTRAINT FK_CartItems_ShoppingCarts
    FOREIGN KEY (CartID)
    REFERENCES ShoppingCarts(CartID),

    CONSTRAINT FK_CartItems_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID)
);

CREATE TABLE Statuses
(
    StatusID INT IDENTITY(1,1) PRIMARY KEY,
    StatusTitle NVARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO Statuses (StatusTitle)
VALUES
('Pending'),
('Paid'),
('Cancelled'),
('Completed');

CREATE TABLE Orders
(
    OrderID INT IDENTITY(1,1) PRIMARY KEY, 
    UserID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    TotalPrice DECIMAL(10,2) NOT NULL
    CHECK (TotalPrice >= 0),
    DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0,
    FinalPrice DECIMAL(10,2) NOT NULL 
    CHECK (FinalPrice >= 0),
    StatusID INT NOT NULL,

    CONSTRAINT FK_Orders_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID),

    CONSTRAINT FK_Orders_Statuses
    FOREIGN KEY (StatusID)
    REFERENCES Statuses(StatusID)
);

CREATE TABLE OrderItems
(
    OrderItemID INT IDENTITY(1,1) PRIMARY KEY,
    OrderID INT NOT NULL,
    BookID INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL
    CHECK (UnitPrice >= 0),
    DiscountPercent DECIMAL(5,2) NOT NULL DEFAULT 0,

    CONSTRAINT FK_OrderItems_Orders
    FOREIGN KEY (OrderID)
    REFERENCES Orders(OrderID),

    CONSTRAINT FK_OrderItems_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID)
);
ALTER TABLE OrderItems
ADD DiscountAmount DECIMAL(10,2) NOT NULL DEFAULT 0 
CHECK (DiscountAmount >= 0);

CREATE TABLE PaymentStatuses
(
    PaymentStatusID INT IDENTITY(1,1) PRIMARY KEY,
    PaymentStatusTitle NVARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO PaymentStatuses (PaymentStatusTitle)
VALUES
('Pending'),
('Successful'),
('Failed');

CREATE TABLE Payments
(
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,

    OrderID INT NOT NULL,

    Amount DECIMAL(10,2) NOT NULL
        CHECK (Amount >= 0),

    TransactionCode NVARCHAR(100) NULL,

    PaymentDate DATETIME2(0) NOT NULL
        DEFAULT GETDATE(),

    PaymentStatusID INT NOT NULL,

    CONSTRAINT FK_Payments_Orders
    FOREIGN KEY (OrderID)
    REFERENCES Orders(OrderID),

    CONSTRAINT FK_Payments_PaymentStatuses
    FOREIGN KEY (PaymentStatusID)
    REFERENCES PaymentStatuses(PaymentStatusID)
);

CREATE TABLE Reviews
(
    ReviewID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    BookID INT NOT NULL,
    CommentText NVARCHAR(1000) NOT NULL,
    ParentID INT NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    ReviewDate DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Reviews_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID),

    CONSTRAINT FK_Reviews_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID),

    CONSTRAINT FK_Reviews_Parent
    FOREIGN KEY (ParentID)
    REFERENCES Reviews(ReviewID)
);

CREATE TABLE Ratings
(
    RatingID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    BookID INT NOT NULL,
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),

    CONSTRAINT UQ_Ratings
    UNIQUE(UserID, BookID),

    CONSTRAINT FK_Ratings_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID),

    CONSTRAINT FK_Ratings_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID)
);

CREATE TABLE NotificationTypes
(
    NotificationTypeID INT IDENTITY(1,1) PRIMARY KEY,
    TypeTitle NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Notifications
(
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    NotificationTypeID INT NOT NULL,
    Title NVARCHAR(200) NOT NULL,
    Message NVARCHAR(500) NOT NULL,
    IsRead BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2(0) NOT NULL
        DEFAULT GETDATE(),

    CONSTRAINT FK_Notifications_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID),

    CONSTRAINT FK_Notifications_NotificationTypes
    FOREIGN KEY (NotificationTypeID)
    REFERENCES NotificationTypes(NotificationTypeID)
); 
ALTER TABLE Notifications
ADD SenderID INT NULL;

ALTER TABLE Notifications
ADD CONSTRAINT FK_Notifications_Sender
FOREIGN KEY (SenderID)
REFERENCES Users(UserID);

ALTER TABLE Notifications
ADD TargetID INT NULL;

ALTER TABLE Notifications
ADD CONSTRAINT FK_Notifications_Target
FOREIGN KEY (TargetID)
REFERENCES Books(BookID);

INSERT INTO NotificationTypes (TypeTitle)
VALUES
('NewBookInFavouriteGenre'),
('DiscountOnSavedBook'),
('NewSaleForPublisher'),
('NewReviewForPublisher');

CREATE TABLE UserLibrary
(
    UserLibraryID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    BookID INT NOT NULL,
    PurchaseDate DATETIME2(0) NOT NULL DEFAULT GETDATE(),

    CONSTRAINT UQ_UserLibrary
    UNIQUE(UserID, BookID),

    CONSTRAINT FK_UserLibrary_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID),

    CONSTRAINT FK_UserLibrary_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID)
);

CREATE TABLE SavedBooks
(
    SavedBookID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    BookID INT NOT NULL,

    CONSTRAINT UQ_SavedBooks
    UNIQUE(UserID, BookID),

    CONSTRAINT FK_SavedBooks_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID),

    CONSTRAINT FK_SavedBooks_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID)
);

CREATE TABLE FavouriteBooks
(
    FavouriteBookID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    BookID INT NOT NULL,
    DisplayOrder INT NOT NULL DEFAULT 0,

    CONSTRAINT FK_FavouriteBooks_Users
        FOREIGN KEY (UserID)
        REFERENCES NormalUsers(UserID),

    CONSTRAINT FK_FavouriteBooks_Books
        FOREIGN KEY (BookID)
        REFERENCES Books(BookID),

    CONSTRAINT UQ_FavouriteBooks
        UNIQUE(UserID, BookID)
);

CREATE TABLE Shelves
(
    ShelfID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    ShelfName NVARCHAR(100) NOT NULL,

    CONSTRAINT UQ_Shelves
    UNIQUE(UserID, ShelfName),

    CONSTRAINT FK_Shelves_Users
    FOREIGN KEY (UserID)
    REFERENCES Users(UserID)
);

ALTER TABLE Shelves
ADD DisplayOrder INT NOT NULL
    CONSTRAINT DF_Shelves_DisplayOrder DEFAULT 0;

ALTER TABLE Shelves
ADD CONSTRAINT CK_Shelves_DisplayOrder
CHECK (DisplayOrder >= 0);

CREATE TABLE ShelfBooks
(
    ShelfID INT NOT NULL,
    BookID INT NOT NULL,

    PRIMARY KEY (ShelfID, BookID),

    CONSTRAINT FK_ShelfBooks_Shelves
    FOREIGN KEY (ShelfID) 
    REFERENCES Shelves(ShelfID),

    CONSTRAINT FK_ShelfBooks_Books
    FOREIGN KEY (BookID) 
    REFERENCES Books(BookID)
);

ALTER TABLE ShelfBooks
ADD DisplayOrder INT NOT NULL
    CONSTRAINT DF_ShelfBooks_DisplayOrder DEFAULT 0;

ALTER TABLE ShelfBooks
ADD CONSTRAINT CK_ShelfBooks_DisplayOrder
CHECK (DisplayOrder >= 0);

CREATE TABLE ReadingProgress
(
    ProgressID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    BookID INT NOT NULL,
    LastPage INT NOT NULL DEFAULT 1
    CHECK (LastPage >= 1),

    CONSTRAINT UQ_ReadingProgress
    UNIQUE(UserID, BookID),

    CONSTRAINT FK_ReadingProgress_Users
    FOREIGN KEY (UserID) 
    REFERENCES Users(UserID),

    CONSTRAINT FK_ReadingProgress_Books
    FOREIGN KEY (BookID)
    REFERENCES Books(BookID)
);

CREATE TABLE ServerLogs
(
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NULL,
    RequestType NVARCHAR(50) NOT NULL,
    RequestTime DATETIME2(0) NOT NULL
        DEFAULT GETDATE(),
    StatusCode INT NULL,
    Details NVARCHAR(1000) NULL,

    FOREIGN KEY (UserID)
    REFERENCES Users(UserID)
);