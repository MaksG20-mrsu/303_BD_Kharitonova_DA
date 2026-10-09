#!/bin/bash

sqlite3 movies_rating.db < db_init.sql

echo "1. Составить список фильмов, имеющих хотя бы одну оценку. Список фильмов отсортировать по году выпуска и по названиям. В списке оставить первые 10 фильмов."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT movies.title, movies.year
FROM movies
JOIN ratings ON movies.id = ratings.movie_id
ORDER BY movies.year, movies.title
LIMIT 10;"

echo " "

echo "2. Вывести список всех пользователей, фамилии которых начинаются на букву A. Полученный список отсортировать по дате регистрации. В списке оставить первых 5 пользователей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT id, name, email, gender, register_date, occupation
FROM users
WHERE substr(name, instr(name, ' ') + 1) LIKE 'A%'
ORDER BY register_date
LIMIT 5;"

echo " "

echo "3. Информация о рейтингах в читаемом формате. Первые 50 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT users.name,
movies.title,
movies.year,
ratings.rating,
date(ratings.timestamp, 'unixepoch') AS rating_date
FROM ratings
JOIN users ON ratings.user_id = users.id
JOIN movies ON ratings.movie_id = movies.id
ORDER BY users.name, movies.title, ratings.rating
LIMIT 50;"

echo " "

echo "4. Фильмы с тегами. Первые 40 записей."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT movies.title,
movies.year,
tags.tag
FROM movies
JOIN tags ON movies.id = tags.movie_id
ORDER BY movies.year, movies.title, tags.tag
LIMIT 40;"

echo " "

echo "5. Самые свежие фильмы."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT title, year
FROM movies
WHERE year = (SELECT MAX(year) FROM movies)
ORDER BY title;"

echo " "

echo "6. Комедии после 2000 года, понравившиеся мужчинам. Оценка не ниже 4.5."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "SELECT movies.title,
movies.year,
COUNT(ratings.id) AS rating_count
FROM movies
JOIN ratings ON movies.id = ratings.movie_id
JOIN users ON ratings.user_id = users.id
WHERE movies.year > 2000
AND movies.genres LIKE '%Comedy%'
AND users.gender = 'male'
AND ratings.rating >= 4.5
GROUP BY movies.id, movies.title, movies.year
ORDER BY movies.year, movies.title;"

echo " "

echo "7. Количество пользователей для каждого рода занятий."
echo "Самая распространенная и самая редкая профессия."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "WITH occupation_counts AS (
    SELECT occupation, COUNT(*) AS user_count
    FROM users
    GROUP BY occupation
)
SELECT occupation,
       user_count,
       CASE
           WHEN user_count = (SELECT MAX(user_count) FROM occupation_counts)
               THEN 'Самая распространенная'
           WHEN user_count = (SELECT MIN(user_count) FROM occupation_counts)
               THEN 'Самая редкая'
           ELSE ''
       END AS description
FROM occupation_counts
ORDER BY user_count DESC, occupation;"