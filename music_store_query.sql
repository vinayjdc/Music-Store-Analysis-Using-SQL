select * from album;
select * from artist;
select * from customer;
select * from employee;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;

/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

select * from employee
order by levels desc
limit 1;

/* Q2: Which countries have the most Invoices? */

select billing_country,count(*) as no_of_invoice from invoice
group by billing_country
order by no_of_invoice desc;


/* Q3: What are top 3 values of total invoice? */

select total from invoice
order by total desc
limit 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city,sum(total) as no_of_invoice from invoice
group by billing_city
order by no_of_invoice desc
limit 1;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/


SELECT 
    c.customer_id, 
    c.first_name || ' ' || c.last_name AS customer_name, 
    SUM(i.total) AS total_spent
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name
ORDER BY 
    total_spent DESC
LIMIT 1;



/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

SELECT 
    c.email, 
    c.first_name, 
    c.last_name, 
    g.name AS genre
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
JOIN 
    invoice_line il ON i.invoice_id = il.invoice_id
JOIN 
    track t ON il.track_id = t.track_id
JOIN 
    genre g ON t.genre_id = g.genre_id
WHERE 
    g.name = 'Rock'
GROUP BY 
    c.email, c.first_name, c.last_name, g.name
ORDER BY 
    c.email ASC;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT 
    ar.name AS artist_name, 
    COUNT(t.track_id) AS total_track_count
FROM 
    artist ar
JOIN 
    album al ON ar.artist_id = al.artist_id
JOIN 
    track t ON al.album_id = t.album_id
JOIN 
    genre g ON t.genre_id = g.genre_id
WHERE 
    g.name = 'Rock'
GROUP BY 
    ar.name
ORDER BY 
    total_track_count DESC
LIMIT 10;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT 
    t.name AS track_name, 
    t.milliseconds
FROM 
    track t
WHERE 
    t.milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY 
    t.milliseconds DESC;
	

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */


SELECT 
    c.first_name || ' ' || c.last_name AS customer_name,
    ar.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS total_spent
FROM 
    customer c
JOIN 
    invoice i ON c.customer_id = i.customer_id
JOIN 
    invoice_line il ON i.invoice_id = il.invoice_id
JOIN 
    track t ON il.track_id = t.track_id
JOIN 
    album al ON t.album_id = al.album_id
JOIN 
    artist ar ON al.artist_id = ar.artist_id
GROUP BY 
    c.customer_id, ar.artist_id
ORDER BY 
    total_spent DESC;


WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */


WITH genre_sales_by_country AS (
    SELECT
        c.country,
        g.name AS genre_name,
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM
        invoice_line il
    JOIN
        track t ON t.track_id = il.track_id
    JOIN
        genre g ON g.genre_id = t.genre_id
    JOIN
        invoice i ON i.invoice_id = il.invoice_id
    JOIN
        customer c ON c.customer_id = i.customer_id
    GROUP BY
        c.country, g.name
),
ranked_genres AS (
    SELECT
        country,
        genre_name,
        total_sales,
        RANK() OVER (PARTITION BY country ORDER BY total_sales DESC) AS genre_rank
    FROM
        genre_sales_by_country
)
SELECT
    country,
    genre_name,
    ROUND(total_sales::numeric, 0) AS total_sales
FROM
    ranked_genres
WHERE
    genre_rank = 1
ORDER BY
    country, genre_name;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */


WITH customer_spending AS (
    SELECT
        c.country,
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(il.unit_price * il.quantity) AS total_spent
    FROM
        customer c
    JOIN
        invoice i ON c.customer_id = i.customer_id
    JOIN
        invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY
        c.country, c.customer_id, c.first_name, c.last_name
),
country_max_spending AS (
    SELECT
        country,
        MAX(total_spent) AS max_spent
    FROM
        customer_spending
    GROUP BY
        country
)
SELECT
    cs.country,
    cs.first_name,
    cs.last_name,
    cs.total_spent
FROM
    customer_spending cs
JOIN
    country_max_spending cms ON cs.country = cms.country AND cs.total_spent = cms.max_spent
ORDER BY
    cs.country, cs.total_spent DESC;



