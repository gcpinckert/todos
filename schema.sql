CREATE TABLE lists (
  id serial PRIMARY KEY,
  name varchar(100) UNIQUE NOT NULL
);

CREATE TABLE todos (
  id serial PRIMARY KEY,
  name varchar(100) NOT NULL,
  list_id integer NOT NULL REFERENCES lists(id) ON DELETE CASCADE,
  completed boolean NOT NULL DEFAULT false
);