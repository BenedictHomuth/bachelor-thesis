CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS todos (
	uid UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    title text NOT NULL,
    description text NOT NULL,
	created_at timestamp NOT NULL DEFAULT now(),
	updated_at timestamp NOT NULL DEFAULT now()
);

 INSERT INTO todos (title, description) VALUES ('Today', 'Go shopping');
