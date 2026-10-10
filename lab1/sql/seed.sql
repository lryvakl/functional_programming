USE faculty_newspaper;

INSERT INTO authors (full_name, position, email) VALUES
    ('Олена Коваль', 'редактор', 'koval@fac.edu'),
    ('Андрій Мельник', 'студент', 'melnyk@fac.edu'),
    ('Ірина Шевчук', 'фотограф', 'shevchuk@fac.edu');

INSERT INTO materials (title, kind, annotation, published_on) VALUES
    ('Хакатон факультету 2026', 'article', 'Підсумки щорічного хакатону.', '2026-09-20'),
    ('Новий корпус: фоторепортаж', 'graphic', 'Фото з відкриття нового корпусу.', '2026-09-28'),
    ('Інтерв''ю з деканом', 'article', 'Плани факультету на навчальний рік.', '2026-10-01');

INSERT INTO material_authors (material_id, author_id) VALUES
    (1, 1), (1, 2), (2, 3), (3, 1);

INSERT INTO publication_files (material_id, path, format) VALUES
    (1, '/files/2026/hackathon.html', 'html'),
    (2, '/files/2026/campus.zip', 'zip'),
    (3, '/files/2026/dean.pdf', 'pdf');

INSERT INTO readers (full_name, email, grp) VALUES
    ('Максим Бондар', 'bondar@stud.fac.edu', 'КН-41'),
    ('Софія Лисенко', 'lysenko@stud.fac.edu', 'КН-42');

INSERT INTO reviews (material_id, reader_id, rating, comment) VALUES
    (1, 1, 5, 'Чудовий огляд!'),
    (1, 2, 4, 'Цікаво, але хотілося б більше фото.'),
    (3, 2, 5, 'Корисна інформація.');

INSERT INTO material_stats (material_id, views, downloads) VALUES
    (1, 340, 25), (2, 512, 80), (3, 128, 12);
