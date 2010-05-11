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
