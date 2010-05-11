CREATE TABLE threads (
	id SERIAL PRIMARY KEY,
	subject text NOT NULL
);

CREATE TABLE mails (
	id SERIAL PRIMARY KEY,
	thread INTEGER NOT NULL
		REFERENCES threads ON DELETE CASCADE,
	tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	sender INTEGER NOT NULL
		REFERENCES aliases ON DELETE RESTRICT,
	reply INTEGER,
	message TEXT
);
