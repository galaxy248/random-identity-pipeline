DROP SCHEMA IF EXISTS random_user;

CREATE SCHEMA IF NOT EXISTS random_user;

set search_path = "random_user";

DROP TABLE IF EXISTS users;

CREATE TABLE IF NOT EXISTS users (
    username varchar(255) PRIMARY KEY,
    email varchar(255) NOT NULL,
    id varchar(255)NOT NULL,
    first_name varchar(128) NOT NULL,
    last_name varchar(128) NOT NULL,
    gender varchar(8) NOT NULL,
    address TEXT NOT NULL,
    post_code varchar(16) NOT NULL,
    dob varchar(32) NOT NULL,
    registered_date varchar(32) NOT NULL,
    phone varchar(32) NOT NULL,
    picture varchar(255) NOT NULL,
    credit_card varchar(255) NOT NULL
);
