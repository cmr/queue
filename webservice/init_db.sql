CREATE TABLE IF NOT EXISTS users (
	userid uuid PRIMARY KEY,
	username text NOT NULL,
	password bytea NOT NULL
);

CREATE TABLE IF NOT EXISTS items (
	itemid uuid PRIMARY KEY,
	content text NOT NULL,
	sorted boolean NOT NULL,
	sort_index integer,
	userid uuid REFERENCES users ON DELETE CASCADE
);
