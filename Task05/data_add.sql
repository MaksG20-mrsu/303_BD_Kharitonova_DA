-- Task05: добавление пяти пользователей, трёх фильмов и трёх оценок.
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- Добавляем необходимые значения в справочники, если их ещё нет.
INSERT OR IGNORE INTO occupations (name) VALUES
    ('DevOps engineer'),
    ('Software developer'),
    ('QA engineer'),
    ('Data analyst'),
    ('System administrator');

-- Добавляем пять пользователей: четыре ближайших по списку и Дарью (№ 25).
-- Дата регистрации определяется по системному локальному времени.
INSERT INTO users (name, email, gender_id, register_date, occupation_id)
SELECT v.name,
       v.email,
       g.id,
       date('now', 'localtime'),
       o.id
FROM (
    SELECT 'Азиза Тоймырадова' AS name, 'toymyradova@example.com' AS email, 'female' AS gender, 'Data analyst' AS occupation
    UNION ALL SELECT 'Николай Харитонов', 'kharitonov@example.com', 'male', 'System administrator'
    UNION ALL SELECT 'Дарья Харитонова', 'kharitonova@example.com', 'female', 'DevOps engineer'
    UNION ALL SELECT 'Илья Черентаев', 'cherentaev@example.com', 'male', 'QA engineer'
    UNION ALL SELECT 'Тимур Чукмарев', 'chukmarev@example.com', 'male', 'Software developer'
) AS v
JOIN genders AS g ON g.name = v.gender
JOIN occupations AS o ON o.name = v.occupation
WHERE NOT EXISTS (
    SELECT 1 FROM users AS u WHERE lower(u.email) = lower(v.email)
);

-- Добавляем три фильма разных жанров.
INSERT INTO movies (title, year)
SELECT v.title, v.year
FROM (
    SELECT 'The Matrix Resurrections' AS title, 2021 AS year
    UNION ALL SELECT 'Dune: Part Two', 2024
    UNION ALL SELECT 'The Super Mario Bros. Movie', 2023
) AS v
WHERE NOT EXISTS (
    SELECT 1 FROM movies AS m WHERE m.title = v.title AND m.year = v.year
);

-- Добавляем жанры в справочник, если их ещё нет.
INSERT OR IGNORE INTO genres (name) VALUES
    ('Sci-Fi'),
    ('Adventure'),
    ('Animation');

-- Связываем каждый новый фильм с соответствующим жанром.
INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id
FROM (
    SELECT 'The Matrix Resurrections' AS title, 2021 AS year, 'Sci-Fi' AS genre
    UNION ALL SELECT 'Dune: Part Two', 2024, 'Adventure'
    UNION ALL SELECT 'The Super Mario Bros. Movie', 2023, 'Animation'
) AS v
JOIN movies AS m ON m.title = v.title AND m.year = v.year
JOIN genres AS g ON g.name = v.genre
WHERE NOT EXISTS (
    SELECT 1 FROM movie_genres AS mg
    WHERE mg.movie_id = m.id AND mg.genre_id = g.id
);

-- Добавляем три оценки от Дарьи за добавленные фильмы.
INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, v.rating, unixepoch('now')
FROM (
    SELECT 'The Matrix Resurrections' AS title, 2021 AS year, 4.5 AS rating
    UNION ALL SELECT 'Dune: Part Two', 2024, 5.0
    UNION ALL SELECT 'The Super Mario Bros. Movie', 2023, 4.0
) AS v
JOIN movies AS m ON m.title = v.title AND m.year = v.year
JOIN users AS u ON u.email = 'kharitonova@example.com'
WHERE NOT EXISTS (
    SELECT 1 FROM ratings AS r
    WHERE r.user_id = u.id AND r.movie_id = m.id
);

COMMIT;
