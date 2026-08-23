USE BookClub
GO

-- 1_Normal user registration:

SELECT UserID
FROM Users
WHERE Username = @Username;

INSERT INTO Users
(
	Username,
	PasswordHash,
	RoleID
)
VALUES
(
	@Username,
	@PasswordHash,
	@RoleID
);

SELECT SCOPE_IDENTITY();

INSERT INTO NormalUsers
(
	UserID,
	SecurityAnswerHash
)
VALUES
(
	@UserID,
	@SecurityAnswerHash
);

-- 2_Publisher registration:

SELECT UserID
FROM Users
WHERE Username = @Username;

INSERT INTO Users
(
	Username,
	PasswordHash,
	RoleID
)
VALUES
(
	@Username,
	@PasswordHash,
	@RoleID
);

SELECT SCOPE_IDENTITY();

INSERT INTO Publishers
(
	UserID,
	FirstName,
	LastName,
	Email,
	ShortDescription,
	PublicationName,
	PublisherLicenseNumber,
	SecurityAnswerHash
)
VALUES
(
	@UserID,
	@FirstName,
	@LastName,
	@Email,
	@ShortDescription,
	@PublicationName,
	@PublisherLicenseNumber,
	@SecurityAnswerHash
);

SELECT UserID
FROM Publishers
WHERE Email = @Email;

SELECT UserID,
	   Username,
	   RoleID,
	   IsBlocked,
	   IsDeleted,
       IsActive
FROM Users
WHERE Username = @Username
AND PasswordHash = @PasswordHash
AND IsBlocked = 0
AND IsDeleted = 0
AND IsActive = 1;

-- 3_ Password Recavery:

SELECT UserID,
	   RoleID
FROM Users
WHERE Username = @Username;

SELECT NormalUsers.UserID
FROM NormalUsers
INNER JOIN Users ON NormalUsers.UserID = Users.UserID
WHERE Users.Username = @Username
AND NormalUsers.SecurityAnswerHash = @SecurityAnswerHash;

SELECT Publishers.UserID
FROM Publishers
INNER JOIN Users ON Publishers.UserID = Users.UserID
WHERE UserID = @UserID
AND SecurityAnswerHash = @SecurityAnswerHash;

UPDATE Users
SET PasswordHash = @NewPasswordHash
WHERE Username = @Username;

-- 4_select and display users favorite gener:

SELECT GenreID,
       GenreTitle
FROM Genres
ORDER BY GenreTitle;

INSERT INTO FavouriteGenre(UserID, GenreID)
VALUES (@UserID, @GenreID);

SELECT Genres.GenreID,
       Genres.GenreTitle
FROM FavouriteGenre
JOIN Genres ON Genres.GenreID = FavouriteGenre.GenreID
WHERE FavouriteGenre.UserID = @UserID;

DELETE FROM FavouriteGenre
WHERE UserID = @UserID
AND GenreID = @GenreID;

SELECT COUNT(*) AS GenreCount
FROM FavouriteGenre
WHERE UserID = @UserID;

-- 5_Home Page:

-- A) کتاب های پیشنهادی بر اساس ژانر های انتخابی
SELECT DISTINCT 
	   B.BookID,
	   B.BookName,
	   B.BookPrice,
	   B.DiscountPercent,
	   B.DiscountAmount,
	   B.CoverImagePath,
	   A.AuthorName,
	   P.PublicationName,
	   AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
INNER JOIN FavouriteGenre ON B.GenreID = FavouriteGenre.GenreID
LEFT JOIN Ratings R ON B.BookID = R.BookID
WHERE FavouriteGenre.UserID = @UserID
AND B.IsDeleted = 0
AND B.IsActive = 1
GROUP BY 
	   B.BookID,
	   B.BookName,
	   B.BookPrice,
	   B.DiscountPercent,
	   B.DiscountAmount,
	   A.AuthorName,
	   P.PublicationName

-- B) جدیدترین کتاب ها  

SELECT TOP 10
	   B.BookID,
	   B.BookName,
	   B.BookPrice,
	   B.DiscountPercent,
	   B.DiscountAmount,
	   A.AuthorName,
	   P.PublicationName,
	   B.RegisteredIn,
	   AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
LEFT JOIN Ratings R ON B.BookID = R.BookID
WHERE B.IsDeleted = 0
AND B.IsActive = 1
GROUP BY 
	   B.BookID,
	   B.BookName,
	   B.BookPrice,
	   B.DiscountPercent,
	   B.DiscountAmount,
	   A.AuthorName,
	   P.PublicationName,
	   B.RegisteredIn
ORDER BY B.RegisteredIn DESC;

-- C) کتاب های رایگان

SELECT 
	 B.BookID,
	 B.BookName,
	 B.CoverImagePath,
	 A.AuthorName,
	 p.publicationName,
	 AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
LEFT JOIN Ratings R ON B.BookID = R.BookID
WHERE BookPrice = 0
AND IsDeleted = 0
AND IsActive = 1
GROUP BY
		B.BookID,
	    B.BookName,
	    B.CoverImagePath,
	    A.AuthorName,
	    p.publicationName
ORDER BY AverageRating DESC;

-- D) پر فروش ترین کتاب ها

SELECT TOP 10
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
	   B.BookPrice,
	   B.DiscountAmount,
	   B.DiscountPercent,
	   A.AuthorName,
	   p.publicationName,
       COUNT(DISTINCT OI.OrderItemID) AS TotalSales,
       AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
INNER JOIN OrderItems OI ON B.BookID = OI.BookID
LEFT JOIN Ratings R ON B.BookID = R.BookID
WHERE B.IsDeleted = 0
AND B.IsActive = 1
GROUP BY
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
	   B.BookPrice,
	   A.AuthorName,
	   p.publicationName
ORDER BY TotalSales DESC;

-- E) محبوب ترین کتاب ها

SELECT TOP 10
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
	   B.BookPrice,
	   B.DiscountAmount,
	   B.DiscountPercent,
	   A.AuthorName,
	   p.publicationName,
       AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
INNER JOIN Ratings R ON B.BookID = R.BookID
GROUP BY
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
	   B.BookPrice,
	   B.DiscountAmount,
	   B.DiscountPercent,
	   A.AuthorName,
	   p.publicationName
ORDER BY AverageRating DESC;
-- F) کتاب های تخفیف دار

SELECT
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
       B.BookPrice,
       B.DiscountPercent,
	   B.DiscountAmount,
	   A.AuthorName,
	   p.publicationName,
	   AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
INNER JOIN Ratings R ON B.BookID = R.BookID
WHERE DiscountPercent > 0
AND IsDeleted = 0
AND IsActive = 1
GROUP BY
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
	   B.BookPrice,
	   B.DiscountAmount,
	   B.DiscountPercent,
	   A.AuthorName,
	   p.publicationName
ORDER BY B.DiscountPercent DESC, B.DiscountAmount DESC;

-- G) تخفیف های زماندار

SELECT
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
       B.BookPrice,
       TD.DiscountPercent,
	   A.AuthorName,
       P.PublicationName,
       AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM TimedDiscount TD
INNER JOIN Books B ON TD.BookID = B.BookID
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
LEFT JOIN Ratings R ON B.BookID = R.BookID
WHERE GETDATE() BETWEEN TD.StartDate AND TD.EndDate
AND B.IsDeleted = 0
AND B.IsActive = 1
GROUP BY
       B.BookID,
       B.BookName,
	   B.CoverImagePath,
       B.BookPrice,
       TD.DiscountPercent,
	   A.AuthorName,
       P.PublicationName
ORDER BY TD.DiscountPercent DESC;

-- 6_ Search and Rating:

-- A) جست و جو بر اساس اسم کتاب

SELECT 
	  B.BookID,
	  B.BookName,
	  P.PublicationName
FROM Books B
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
WHERE B.IsDeleted = 0
  AND B.IsActive = 1
  AND B.BookName LIKE '%' + @BookName + '%';

-- B) جست و جو بر اساس اسم نویسنده

SELECT B.BookID,
       B.BookName,
       A.AuthorName
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
WHERE B.IsDeleted = 0
  AND B.IsActive = 1
  AND A.AuthorName LIKE '%' + @AuthorName + '%';

-- C) جست و جو بر اساس اسم ناشر
SELECT B.BookID,
       B.BookName,
       P.PublicationName
FROM Books B
INNER JOIN Publishers P
    ON B.PublisherUserID = P.UserID
WHERE B.IsDeleted = 0
  AND B.IsActive = 1
  AND P.PublicationName LIKE '%' + @PublisherName + '%';

-- 7) Reviews & Ratings:

-- A) ثبت و ویرایش و حذف و مشاهده ی نظرات یک کتاب

INSERT INTO Reviews
(
    UserID,
    BookID,
    CommentText
)
VALUES
(
    @UserID,
    @BookID,
    @CommentText
);
--------------------------------------------
UPDATE Reviews
SET CommentText = @CommentText
WHERE ReviewID = @ReviewID
  AND UserID = @UserID
  AND IsDeleted = 0;
---------------------------------------------
UPDATE Reviews
SET IsDeleted = 1
WHERE ReviewID = @ReviewID
  AND UserID = @UserID;
---------------------------------------------
SELECT U.Username,
       R.CommentText,
       R.ReviewDate
FROM Reviews R
INNER JOIN Users U ON R.UserID = U.UserID
WHERE R.BookID = @BookID
  AND R.IsDeleted = 0
ORDER BY R.ReviewDate DESC;

-- B) ثبت امتیاز ستاره‌ای _ نمایش میانگین امتیاز هر کتاب _ نمایش میانگین امتیاز و تعداد رأی‌ها

INSERT INTO Ratings
(
    UserID,
    BookID,
    Rating
)
VALUES
(
    @UserID,
    @BookID,
    @Rating
);
---------------------------------------------
SELECT AVG(CAST(Rating AS FLOAT)) AS AverageRating
FROM Ratings
WHERE BookID = @BookID;
---------------------------------------------
SELECT COUNT(*) AS RatingCount,
       AVG(CAST(Rating AS FLOAT)) AS AverageRating
FROM Ratings
WHERE BookID = @BookID;

-- 7) SavedBooks & Favorites:
-- افزودن به ذخیره ها
INSERT INTO SavedBooks
(
    UserID,
    BookID,
    IsFavorite
)
VALUES
(
    @UserID,
    @BookID,
    0
);

-- حذف از ذخیره شده ها 
DELETE FROM SavedBooks
WHERE UserID = @UserID
AND BookID = @BookID;

-- مشاهده ی کتاب های ذخیره شده
SELECT
    B.BookID,
    B.BookName,
    B.CoverImagePath,
    B.BookPrice,
    A.AuthorName,
    P.PublicationName
FROM SavedBooks SB
INNER JOIN Books B
    ON SB.BookID = B.BookID
INNER JOIN Authors A
    ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P
    ON B.PublisherUserID = P.UserID
WHERE SB.UserID = @UserID;

-- افزودن به علاقه مندی ها
UPDATE SavedBooks
SET IsFavorite = 1
WHERE UserID = @UserID
AND BookID = @BookID;

-- حذف از علاقه مندی ها 
UPDATE SavedBooks
SET IsFavorite = 0
WHERE UserID = @UserID
AND BookID = @BookID;

-- مشاهده ی لیست علاقه مندی ها 
SELECT
    B.BookID,
    B.BookName,
    B.CoverImagePath,
    B.BookPrice,
    A.AuthorName,
    P.PublicationName
FROM SavedBooks SB
INNER JOIN Books B
    ON SB.BookID = B.BookID
INNER JOIN Authors A
    ON B.AuthorID = A.AuthorID
INNER JOIN Publishers P
    ON B.PublisherUserID = P.UserID
WHERE SB.UserID = @UserID
AND SB.IsFavorite = 1;

-- 8) ShoppingCarts, Orders and Payments:
-- افزودن کتاب به سبد خرید
INSERT INTO CartItems
(
    CartID,
    BookID
)
SELECT CartID,
       @BookID
FROM ShoppingCarts
WHERE UserID = @UserID;

-- حذف کتاب از سبد خرید
DELETE FROM CartItems
WHERE CartID = @CartID
  AND BookID = @BookID;

-- مشاهده ی فهرست کتاب های انتخاب شده
SELECT B.BookID,
       B.BookName,
       B.CoverImagePath,
       B.DiscountPercent,
       B.DiscountAmount,
       A.AuthorName
FROM CartItems CI
INNER JOIN Books B ON CI.BookID = B.BookID
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
WHERE CI.CartID = @CartID;

-- نمایش قیمت هر کتاب
SELECT B.BookID,
       B.BookName,
       B.BookPrice
FROM CartItems CI
INNER JOIN Books B ON CI.BookID = B.BookID
WHERE CI.CartID = @CartID;

-- محاسبه مجموع خرید
SELECT SUM(B.BookPrice) AS TotalPrice
FROM CartItems CI
INNER JOIN Books B ON CI.BookID = B.BookID
WHERE CI.CartID = @CartID;

-- نمایش تعداد اقلام در سبد
SELECT COUNT(*) AS ItemCount
FROM CartItems
WHERE CartID = @CartID;

-- اعمال تخفیف‌های فعال روی خرید
SELECT B.BookID,
       B.BookName,
       B.BookPrice,
       TD.DiscountPercent,
       B.DiscountPercent,
       B.DiscountAmount
FROM CartItems CI
INNER JOIN Books B ON CI.BookID = B.BookID
LEFT JOIN TimedDiscount TD ON B.BookID = TD.BookID
   AND GETDATE() BETWEEN TD.StartDate AND TD.EndDate
WHERE CI.CartID = @CartID;

-- مبلغ نهایی قابل پرداخت
SELECT
    SUM(B.BookPrice) AS TotalPrice,

    SUM(
        CASE
            WHEN TD.DiscountPercent IS NOT NULL
                THEN B.BookPrice * TD.DiscountPercent / 100

            WHEN B.DiscountPercent > 0
                THEN B.BookPrice * B.DiscountPercent / 100

            ELSE B.DiscountAmount
        END
    ) AS DiscountAmount,

    SUM(B.BookPrice)
    -
    SUM(
        CASE
            WHEN TD.DiscountPercent IS NOT NULL
                THEN B.BookPrice * TD.DiscountPercent / 100

            WHEN B.DiscountPercent > 0
                THEN B.BookPrice * B.DiscountPercent / 100

            ELSE B.DiscountAmount
        END
    ) AS FinalPrice

FROM CartItems CI
INNER JOIN Books B ON CI.BookID = B.BookID
LEFT JOIN TimedDiscount TD ON B.BookID = TD.BookID
   AND GETDATE() BETWEEN TD.StartDate AND TD.EndDate
WHERE CI.CartID = @CartID;

-- انتقال به کتابخانه ی شخصی و حذف از سبد خرید
INSERT INTO UserLibrary (UserID, BookID)
SELECT O.UserID,
       OI.BookID
FROM Orders O
INNER JOIN OrderItems OI ON O.OrderID = OI.OrderID
WHERE O.OrderID = @OrderID;

DELETE FROM CartItems
WHERE CartID = @CartID;
----------------------------------------------
-- 9_Payments and Orders:
-- ثبت سفارش
INSERT INTO OrderItems
(
    OrderID,
    BookID,
    UnitPrice,
    DiscountPercent,
    DiscountAmount
)
SELECT
    @OrderID,
    B.BookID,
    B.BookPrice,

    CASE
        WHEN TD.DiscountPercent IS NOT NULL
            THEN TD.DiscountPercent
        ELSE B.DiscountPercent
    END,

    B.DiscountAmount
FROM CartItems CI
INNER JOIN Books B ON CI.BookID = B.BookID
LEFT JOIN TimedDiscount TD  ON B.BookID = TD.BookID
   AND GETDATE() BETWEEN TD.StartDate AND TD.EndDate
WHERE CI.CartID = @CartID;

-- ایجاد پرداخت
INSERT INTO Payments
(
    OrderID,
    Amount,
    PaymentStatusID
)
VALUES
(
    @OrderID,
    @Amount,
    1
);

-- پرداخت موفق
UPDATE Payments
SET TransactionCode = @TransactionCode,
    PaymentStatusID = 2
WHERE PaymentID = @PaymentID;

-- پرداخت ناموفق
UPDATE Payments
SET PaymentStatusID = 3
WHERE PaymentID = @PaymentID;

-- مشاهده اطلاعات پرداخت
SELECT
    P.PaymentID,
    O.OrderID,
    B.BookName AS BookTitle,
    P.Amount,
    PS.PaymentStatusTitle,
    P.PaymentDate
FROM Payments P
INNER JOIN Orders O
    ON P.OrderID = O.OrderID
INNER JOIN PaymentStatuses PS
    ON P.PaymentStatusID = PS.PaymentStatusID
INNER JOIN OrderItems OI
    ON O.OrderID = OI.OrderID
INNER JOIN Books B
    ON OI.BookID = B.BookID
WHERE O.UserID = @UserID;

-- مشاهده تاریخچه سفارشات کاربر
SELECT
    O.OrderID,
    O.OrderDate,
    O.TotalPrice,

    SUM(
        (OI.UnitPrice * OI.DiscountPercent / 100)
        + OI.DiscountAmount
    ) AS DiscountAmount,

    O.FinalPrice,
    S.StatusTitle
FROM Orders O
INNER JOIN Statuses S ON O.StatusID = S.StatusID
INNER JOIN OrderItems OI ON O.OrderID = OI.OrderID
WHERE O.UserID = @UserID
GROUP BY
    O.OrderID,
    O.OrderDate,
    O.TotalPrice,
    O.FinalPrice,
    S.StatusTitle
ORDER BY O.OrderDate DESC;
----------------------------------------------
-- 10_Publisher panle:

-- A) مدیریت حساب ناشر
-- مشاهده اطلاعات حساب
SELECT
    p.FirstName,
    p.LastName,
    p.Email,
    p.ShortDescription,
    p.PublicationName,
    p.PublisherLicenseNumber
FROM Publishers p
WHERE p.UserID = @PublisherID;
-- ویرایش اطلاعات حساب
UPDATE Publishers
SET
    FirstName = @FirstName,
    LastName = @LastName,
    Email = @Email,
    ShortDescription = @ShortDescription,
    PublicationName = @PublicationName
WHERE UserID = @PublisherID;
-- اضافه کردن کتاب
INSERT INTO Books
(
    BookName,
    BookDescription,
    BookPrice,
    DiscountPercent,
    DiscountAmount,
    CoverImagePath,
    PDFfilePath,
    GenreID,
    CategoryID,
    AuthorID,
    PublisherUserID
)
VALUES
(
    @BookName,
    @BookDescription,
    @BookPrice,
    @DiscountPercent,
    @DiscountAmount,
    @CoverImagePath,
    @PDFfilePath,
    @GenreID,
    @CategoryID,
    @AuthorID,
    @PublisherID
);
-- ویرایش اطلاعات کتاب
UPDATE Books
SET
    BookName = @BookName,
    BookDescription = @BookDescription,
    BookPrice = @BookPrice,
    DiscountPercent = @DiscountPercent,
    DiscountAmount = @DiscountAmount,
    CoverImagePath = @CoverImagePath,
    PDFfilePath = @PDFfilePath,
    GenreID = @GenreID,
    CategoryID = @CategoryID,
    AuthorID = @AuthorID
WHERE BookID = @BookID
AND PublisherUserID = @PublisherID;
-- مشاهده ی کتاب های ناشر
SELECT
    BookID,
    BookName,
    BookPrice,
    RegisteredIn,
    IsActive
FROM Books
WHERE PublisherUserID = @PublisherID
AND IsDeleted = 0;
-- اعمال تخفیف مبلغی
UPDATE Books
SET
    DiscountAmount = @DiscountAmount,
    DiscountPercent = 0
WHERE BookID = @BookID
AND PublisherUserID = @PublisherID;
-- اعمال تخفیف درصدی
UPDATE Books
SET
    DiscountPercent = @DiscountPercent,
    DiscountAmount = 0
WHERE BookID = @BookID
AND PublisherUserID = @PublisherID;
-- اعمال تخفیف زماندار
INSERT INTO TimedDiscount
(
    BookID,
    DiscountPercent,
    StartDate,
    EndDate
)
VALUES
(
    @BookID,
    @DiscountPercent,
    @StartDate,
    @EndDate
);
-- مشاهده ی تخفیف های فعال
SELECT
    BookID,
    BookName,
    DiscountPercent,
	DiscountAmount,
    'Permanent' AS DiscountType
FROM Books
WHERE PublisherUserID = @PublisherID
AND (DiscountPercent > 0
OR DiscountAmount > 0)

UNION ALL

SELECT
    B.BookID,
    B.BookName,
    TD.DiscountPercent,
    0 AS DiscountAmount,
    'Timed' AS DiscountType
FROM TimedDiscount TD
INNER JOIN Books B ON TD.BookID = B.BookID
WHERE B.PublisherUserID = @PublisherID
AND GETDATE() BETWEEN TD.StartDate AND TD.EndDate;

-- غیر فعال کردن کتاب
UPDATE Books
SET IsActive = 0
WHERE BookID = @BookID
AND PublisherUserID = @PublisherID;
-- فعال سازی مجدد
UPDATE Books
SET IsActive = 1
WHERE BookID = @BookID
AND PublisherUserID = @PublisherID;
-- حذف دائمی
UPDATE Books
SET IsDeleted = 1
WHERE BookID = @BookID
AND PublisherUserID = @PublisherID;

-- بخش آمار پنل

-- میانگین امتیاز هر کتاب
SELECT
    B.BookID,
    B.BookName,
    AVG(CAST(R.Rating AS FLOAT)) AS AverageRating
FROM Books B
LEFT JOIN Ratings R ON B.BookID = R.BookID
WHERE B.PublisherUserID = @PublisherID
GROUP BY
    B.BookID,
    B.BookName;
-- فروش هر کتاب
SELECT
    B.BookID,
    B.BookName,
    COUNT(*) AS SalesCount
FROM Books B
INNER JOIN OrderItems OI ON B.BookID = OI.BookID
WHERE B.PublisherUserID = @PublisherID
GROUP BY
    B.BookID,
    B.BookName
ORDER BY SalesCount DESC;
-- مجموع درآمد ناشر
SELECT
    SUM(OI.UnitPrice) AS TotalRevenue
FROM Books B
INNER JOIN OrderItems OI ON B.BookID = OI.BookID
WHERE B.PublisherUserID = @PublisherID;
-- تعداد کل کتاب های منتشر شده
SELECT
    COUNT(*) AS TotalBooks
FROM Books
WHERE PublisherUserID = @PublisherID
AND IsDeleted = 0;

-- 11) Admin Panel:
-- مشاهده لیست تمام کاربران
SELECT
    U.UserID,
    U.Username,
    R.RoleTitle,
    U.RegisterDate,
    U.IsActive,
    U.IsBlocked,
    U.IsDeleted
FROM Users U
INNER JOIN Roles R ON U.RoleID = R.RoleID;
-- اطلاعات کامل ناشران
SELECT
    U.UserID,
    U.Username,
    U.RegisterDate,
    U.IsActive,
    U.IsBlocked,
    U.IsDeleted,
    P.FirstName,
    P.LastName,
    P.Email,
    P.PublicationName,
    P.PublisherLicenseNumber
FROM Users U
INNER JOIN Publishers P ON U.UserID = P.UserID;
-- جست و جوی کاربر
SELECT
    U.UserID,
    U.Username,
    R.RoleTitle
FROM Users U
INNER JOIN Roles R ON U.RoleID = R.RoleID
WHERE U.Username LIKE '%' + @USERNAME + '%';
-- فیلتر کاربران
SELECT
    U.UserID,
    U.Username,
    R.RoleTitle,
    U.IsActive,
    U.IsBlocked,
    U.IsDeleted
FROM Users U
INNER JOIN Roles R ON U.RoleID = R.RoleID
WHERE R.RoleTitle = @ROLETITLE;
-- مشاهده ی تاریخ ثبت نام
SELECT
    U.UserID,
    U.Username,
    U.RegisterDate,
    R.RoleTitle
FROM Users U
INNER JOIN Roles R ON U.RoleID = R.RoleID;
-- مشاهده وضعیت کاربر
SELECT
    UserID,
    Username,
    IsActive,
    IsDeleted,
    IsBlocked
FROM Users;
-- مسدود سازی کاربر
UPDATE Users
SET IsActive = 0 
WHERE UserID = @USERID;

UPDATE Users
SET IsBlocked = 1
WHERE UserID = @USERID;
-- رفع مسدود سازی 
UPDATE Users
SET IsBlocked = 1
WHERE UserID = @USERID;

UPDATE Users
SET IsActive = 1
WHERE UserID = @USERID;
-- مشاهده کاربران مسدود شده
SELECT
    UserID,
    Username
FROM Users
WHERE IsActive = 0;
-- مشاهده کاربران فعال
SELECT
    UserID,
    Username
FROM Users
WHERE IsActive = 1;

-- مشاهده تمامی کتاب ها
SELECT
    B.BookID,
    B.BookName,
    B.BookPrice,
    B.RegisteredIn,
    P.PublicationName
FROM Books B
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
WHERE B.IsDeleted = 0;
-- بررسی اطلاعات کتاب
SELECT
    B.BookID,
    B.BookName,
    B.BookDescription,
    B.BookPrice,
    B.DiscountPercent,
    A.AuthorName,
    G.GenreTitle,
    C.CategoryTitle,
    P.PublicationName
FROM Books B
INNER JOIN Authors A ON B.AuthorID = A.AuthorID
INNER JOIN Genres G ON B.GenreID = G.GenreID
INNER JOIN Categories C ON B.CategoryID = C.CategoryID
INNER JOIN Publishers P ON B.PublisherUserID = P.UserID
WHERE B.BookID = @BOOKID;
-- حذف کتاب نامعتبر
UPDATE Books
SET IsDeleted = 1
WHERE BookID = @BOOKID;
-- فعال سازی مجدد
UPDATE Books
SET IsDeleted = 0
WHERE BookID = @BOOKID;
-- ویرایش اطلاعات کتاب
UPDATE Books
SET
    BookName = @BOOKNAME,
    BookDescription = @BOOKDESCRIPTION,
    BookPrice = @BOOKPRICE,
    DiscountPercent = @DISCOUNTPERCENT,
    GenreID = @GENREID,
    CategoryID = @CATEGORYID,
    AuthorID = @AUTHORID
WHERE BookID = @BOOKID;
-- مشاهده ی تمامی نظرات
SELECT
    RV.ReviewID,
    U.Username,
    B.BookName,
    RV.CommentText,
    RV.ReviewDate
FROM Reviews RV
INNER JOIN Users U ON RV.UserID = U.UserID
INNER JOIN Books B ON RV.BookID = B.BookID
ORDER BY RV.ReviewDate DESC;
-- مشاهدات نظرات یک کتاب 
SELECT
    RV.ReviewID,
    U.Username,
    RV.CommentText,
    RV.ReviewDate
FROM Reviews RV
INNER JOIN Users U ON RV.UserID = U.UserID
WHERE RV.BookID = @BOOKID;
-- حذف نظر نامعتبر
UPDATE Reviews
SET IsDeleted = 1
WHERE ReviewID = @REVIEWID;