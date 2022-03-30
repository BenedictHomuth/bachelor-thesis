CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS tasks (
	task_uid UUID PRIMARY KEY NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
	created_at timestamp NOT NULL DEFAULT now(),
	updated_at timestamp NOT NULL DEFAULT now()
);

 INSERT INTO tasks (task_uid,name, description) VALUES (uuid_generate_v4(),'Heute', 'Einkaufen')