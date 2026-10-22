#!/bin/bash

set -e

if command -v chcp >/dev/null 2>&1; then
    chcp 65001 > /dev/null
fi

sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Первые 100 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT
    u1.name AS user1,
    u2.name AS user2,
    m.title
FROM ratings r1
JOIN ratings r2
    ON r1.movie_id = r2.movie_id
   AND r1.user_id < r2.user_id
JOIN users u1 ON r1.user_id = u1.id
JOIN users u2 ON r2.user_id = u2.id
JOIN movies m ON r1.movie_id = m.id
ORDER BY u1.name, u2.name, m.title
LIMIT 100;"

echo " "

echo "2. Найти 10 самых свежих оценок от разных пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH latest AS (
    SELECT
        users.name,
        movies.title,
        ratings.rating,
        ratings.timestamp,
        date(ratings.timestamp, 'unixepoch') AS rating_date,
        ROW_NUMBER() OVER (
            PARTITION BY ratings.user_id
            ORDER BY ratings.timestamp DESC, ratings.id DESC
        ) AS rn
    FROM ratings
    JOIN users ON ratings.user_id = users.id
    JOIN movies ON ratings.movie_id = movies.id
)
SELECT name, title, rating, rating_date
FROM latest
WHERE rn = 1
ORDER BY timestamp DESC, name
LIMIT 10;"

echo " "

echo "3. Вывести фильмы с максимальным и минимальным средним рейтингом."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS (
    SELECT
        movies.id,
        movies.title,
        movies.year,
        AVG(ratings.rating) AS avg_rating
    FROM movies
    JOIN ratings ON movies.id = ratings.movie_id
    GROUP BY movies.id, movies.title, movies.year
),
extremes AS (
    SELECT
        MAX(avg_rating) AS max_rating,
        MIN(avg_rating) AS min_rating
    FROM avg_ratings
)
SELECT
    a.title,
    a.year,
    ROUND(a.avg_rating, 2) AS avg_rating,
    CASE
        WHEN e.max_rating = e.min_rating THEN 'Да'
        WHEN a.avg_rating = e.max_rating THEN 'Да'
        ELSE 'Нет'
    END AS 'Рекомендуем'
FROM avg_ratings a
CROSS JOIN extremes e
WHERE a.avg_rating = e.max_rating
   OR a.avg_rating = e.min_rating
ORDER BY a.year, a.title;"

echo " "

echo "4. Вычислить количество оценок и среднюю оценку от женщин с 2010 по 2012 год."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT
    COUNT(*) AS rating_count,
    ROUND(AVG(ratings.rating), 2) AS average_rating
FROM ratings
JOIN users ON ratings.user_id = users.id
WHERE users.gender = 'female'
  AND ratings.timestamp >= strftime('%s', '2010-01-01')
  AND ratings.timestamp < strftime('%s', '2013-01-01');"

echo " "

echo "5. Составить список фильмов со средней оценкой и местом в рейтинге. Первые 20 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS (
    SELECT
        movies.id,
        movies.title,
        movies.year,
        AVG(ratings.rating) AS avg_rating
    FROM movies
    JOIN ratings ON movies.id = ratings.movie_id
    GROUP BY movies.id, movies.title, movies.year
),
ranked AS (
    SELECT
        title,
        year,
        ROUND(avg_rating, 2) AS avg_rating,
        RANK() OVER (ORDER BY avg_rating DESC) AS rating_rank
    FROM avg_ratings
)
SELECT title, year, avg_rating, rating_rank
FROM ranked
ORDER BY year, title
LIMIT 20;"

echo " "

echo "6. Вывести 10 последних зарегистрированных пользователей: Фамилия Имя|Дата регистрации."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -list -separator "|" -echo "SELECT
    substr(name, instr(name, ' ') + 1) || ' ' ||
    substr(name, 1, instr(name, ' ') - 1) AS 'Фамилия Имя',
    register_date
FROM users
ORDER BY register_date DESC, name
LIMIT 10;"

echo " "

echo "7. Составить таблицу умножения от 1 до 10 с помощью рекурсивного CTE."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -list -echo "WITH RECURSIVE multiplication(a, b) AS (
    SELECT 1, 1
    UNION ALL
    SELECT
        CASE WHEN b = 10 THEN a + 1 ELSE a END,
        CASE WHEN b = 10 THEN 1 ELSE b + 1 END
    FROM multiplication
    WHERE a < 10 OR b < 10
)
SELECT a || 'x' || b || '=' || (a * b)
FROM multiplication;"

echo " "

echo "8. Вывести все жанры фильмов, каждый жанр в отдельной строке, с помощью рекурсивного CTE."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -list -echo "WITH RECURSIVE split(movie_id, rest, genre) AS (
    SELECT id, genres || '|', ''
    FROM movies
    WHERE genres IS NOT NULL
      AND genres <> ''
      AND genres <> '(no genres listed)'
    UNION ALL
    SELECT
        movie_id,
        substr(rest, instr(rest, '|') + 1),
        substr(rest, 1, instr(rest, '|') - 1)
    FROM split
    WHERE rest <> ''
)
SELECT DISTINCT genre
FROM split
WHERE genre <> ''
ORDER BY genre;"