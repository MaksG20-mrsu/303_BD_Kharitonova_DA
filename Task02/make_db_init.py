import csv
import re


def sql_text(value):
    value = value.replace("'", "''")
    return "'" + value + "'"


sql = []


# MOVIES

sql.append("DROP TABLE IF EXISTS movies;")

sql.append("""
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title VARCHAR(159),
    year INTEGER,
    genres VARCHAR(96)
);
""")

with open("movies.csv", "r", encoding="utf-8") as file:
    reader = csv.DictReader(file)

    for row in reader:
        movie_id = row["movieId"]
        full_title = row["title"]
        genres = row["genres"]

        match = re.search(r"\((\d{4})\)$", full_title)

        if match:
            year = match.group(1)
            title = full_title[:match.start()].strip()
        else:
            year = "NULL"
            title = full_title

        sql.append(
            "INSERT INTO movies (id, title, year, genres) VALUES ("
            + movie_id + ", "
            + sql_text(title) + ", "
            + year + ", "
            + sql_text(genres) + ");"
        )


# RATINGS

sql.append("DROP TABLE IF EXISTS ratings;")

sql.append("""
CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);
""")

with open("ratings.csv", "r", encoding="utf-8") as file:
    reader = csv.DictReader(file)

    record_id = 1

    for row in reader:
        sql.append(
            "INSERT INTO ratings "
            "(id, user_id, movie_id, rating, timestamp) VALUES ("
            + str(record_id) + ", "
            + row["userId"] + ", "
            + row["movieId"] + ", "
            + row["rating"] + ", "
            + row["timestamp"] + ");"
        )

        record_id += 1


# TAGS

sql.append("DROP TABLE IF EXISTS tags;")

sql.append("""
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    tag VARCHAR(85),
    timestamp INTEGER
);
""")

with open("tags.csv", "r", encoding="utf-8") as file:
    reader = csv.DictReader(file)

    record_id = 1

    for row in reader:
        sql.append(
            "INSERT INTO tags "
            "(id, user_id, movie_id, tag, timestamp) VALUES ("
            + str(record_id) + ", "
            + row["userId"] + ", "
            + row["movieId"] + ", "
            + sql_text(row["tag"]) + ", "
            + row["timestamp"] + ");"
        )

        record_id += 1


# USERS

sql.append("DROP TABLE IF EXISTS users;")

sql.append("""
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name VARCHAR(22),
    email VARCHAR(32),
    gender VARCHAR(6),
    register_date VARCHAR(10),
    occupation VARCHAR(13)
);
""")

with open("users.txt", "r", encoding="utf-8") as file:

    for line in file:
        parts = line.strip().split("|")

        user_id = parts[0]
        name = parts[1]
        email = parts[2]
        gender = parts[3]
        register_date = parts[4]
        occupation = parts[5]

        sql.append(
            "INSERT INTO users "
            "(id, name, email, gender, register_date, occupation) VALUES ("
            + user_id + ", "
            + sql_text(name) + ", "
            + sql_text(email) + ", "
            + sql_text(gender) + ", "
            + sql_text(register_date) + ", "
            + sql_text(occupation) + ");"
        )


# SQL-ФАЙЛ

with open("db_init.sql", "w", encoding="utf-8") as file:
    file.write("\n".join(sql))

print("Файл db_init.sql создан.")