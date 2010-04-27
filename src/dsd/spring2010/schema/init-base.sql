CREATE TABLE files (
	id SERIAL PRIMARY KEY
);

CREATE TABLE paths (
	id SERIAL PRIMARY KEY,
	file INTEGER NOT NULL
		REFERENCES files ON DELETE CASCADE,
	name VARCHAR(256) NOT NULL,
	
	CONSTRAINT unique_path UNIQUE (file, name)
);

CREATE TABLE persons (
	id SERIAL PRIMARY KEY,
	fname VARCHAR(128),
	lname VARCHAR(128)
);

CREATE TABLE aliases (
	id SERIAL PRIMARY KEY,
	person INTEGER NOT NULL
		REFERENCES persons ON DELETE CASCADE,
	name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE versions (
	id SERIAL PRIMARY KEY,
	name VARCHAR(128) NOT NULL,
	release BOOLEAN NOT NULL DEFAULT TRUE,
	revision INTEGER,

	CONSTRAINT valid_version_revision CHECK (revision IS NULL OR revision > 0)
);

CREATE FUNCTION add_path(filename paths.name%TYPE)
	RETURNS paths AS $$
DECLARE
	file_id files.id%TYPE;
	result paths%ROWTYPE;
BEGIN
	SELECT file INTO file_id FROM paths
		WHERE name = filename ORDER BY id DESC;
	IF file_id IS NULL THEN
		SELECT * FROM add_path_unique(filename) INTO result;
	ELSE
		SELECT * FROM paths INTO result
			WHERE name = filename AND file = file_id LIMIT 1;
	END IF;

	RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION add_path_unique(filename paths.name%TYPE)
	RETURNS paths AS $$
DECLARE
	file_id files.id%TYPE;
	path_id paths.id%TYPE;
	result paths%ROWTYPE;
BEGIN
	file_id := nextval('files_id_seq');
	INSERT INTO files (id) VALUES (file_id);
	path_id := nextval('paths_id_seq');
	INSERT INTO paths (id, file, name) VALUES (path_id, file_id, filename);

	SELECT * FROM paths INTO result WHERE id = path_id;
	RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION add_path_renamed(file_id files.id%TYPE,
	filename paths.name%TYPE) RETURNS paths AS $$
DECLARE
	path_id paths.id%TYPE;
	result paths%ROWTYPE;
BEGIN
	SELECT id INTO path_id FROM paths WHERE file = file_id AND name = filename;
	IF path_id IS NULL THEN
		path_id := nextval('paths_id_seq');
		INSERT INTO paths (id, file, name) VALUES (path_id, file_id, filename);
	END IF;
	
	SELECT * FROM paths INTO result WHERE id = path_id;
	RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION add_person(username aliases.name%TYPE)
	RETURNS aliases AS $$
DECLARE
	person_id persons.id%TYPE;
	result aliases%ROWTYPE;
BEGIN
	SELECT person INTO person_id FROM aliases WHERE name = username;
	IF person_id IS NULL THEN
		SELECT * FROM add_person_unique(username) INTO result;
	ELSE
		SELECT * INTO result FROM aliases
			WHERE name = username AND person = person_id;
	END IF;

	RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION add_person_unique(username aliases.name%TYPE)
	RETURNS aliases AS $$
DECLARE
	person_id persons.id%TYPE;
	alias_id aliases.id%TYPE;
	result aliases%ROWTYPE;
BEGIN
	person_id := nextval('persons_id_seq');
	INSERT INTO persons (id) VALUES (person_id);
	alias_id := nextval('aliases_id_seq');
	INSERT INTO aliases (id, person, name)
		VALUES (alias_id, person_id, username);

	SELECT * FROM aliases INTO result WHERE id = alias_id;
	RETURN result;
END;
$$ LANGUAGE plpgsql;
