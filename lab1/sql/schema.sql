CREATE DATABASE IF NOT EXISTS faculty_newspaper CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE faculty_newspaper;

DROP TABLE IF EXISTS material_stats, reviews, readers, publication_files, material_authors, materials, authors;

CREATE TABLE authors (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    position  VARCHAR(80)  NOT NULL,
    email     VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE materials (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    kind         ENUM('article', 'graphic') NOT NULL,
    annotation   TEXT NOT NULL,
    published_on DATE NOT NULL
);

CREATE TABLE material_authors (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    author_id   INT NOT NULL,
    UNIQUE (material_id, author_id),
    FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE,
    FOREIGN KEY (author_id)   REFERENCES authors (id)   ON DELETE CASCADE
);

CREATE TABLE publication_files (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    path        VARCHAR(255) NOT NULL,
    format      VARCHAR(20)  NOT NULL,
    FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE
);

CREATE TABLE readers (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email     VARCHAR(120) NOT NULL UNIQUE,
    grp       VARCHAR(40)  NOT NULL
);

CREATE TABLE reviews (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    reader_id   INT NOT NULL,
    rating      TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT NOT NULL,
    FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE,
    FOREIGN KEY (reader_id)   REFERENCES readers (id)   ON DELETE CASCADE
);

CREATE TABLE material_stats (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL UNIQUE,
    views       INT NOT NULL DEFAULT 0,
    downloads   INT NOT NULL DEFAULT 0,
    FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE
);
