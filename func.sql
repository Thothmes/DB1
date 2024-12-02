CREATE TABLE spec (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(255) NOT NULL,
    column_name VARCHAR(255) NOT NULL,
    current_max_value INTEGER NOT NULL);

INSERT INTO spec (table_name, column_name, current_max_value) VALUES ('spec', 'id', 1);

CREATE FUNCTION func(val_table_name VARCHAR, val_column_name VARCHAR) RETURNS INTEGER AS $$
DECLARE
    next_value INTEGER;
    new_id INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM spec WHERE table_name = val_table_name AND column_name = val_column_name) THEN
        UPDATE spec
        SET current_max_value = current_max_value + 1
        WHERE table_name = val_table_name AND column_name = val_column_name
        RETURNING current_max_value INTO next_value;
    ELSE
        EXECUTE format('SELECT COALESCE(MAX(%I), 0) FROM %I', val_column_name, val_table_name) INTO next_value;
        new_id = func('spec', 'id');
        INSERT INTO spec (id, table_name, column_name, current_max_value) VALUES (new_id, val_table_name, val_column_name, next_value + 1);
        next_value = next_value + 1;
    END IF;
    RETURN next_value;
END;
$$ LANGUAGE plpgsql;

SELECT func('spec', 'id');
SELECT * FROM spec;
SELECT func('spec', 'id');
SELECT * FROM spec;

CREATE TABLE test (
    id INTEGER
);

INSERT INTO test (id) VALUES (10);

SELECT func('test', 'id');
SELECT * FROM spec;
SELECT func('test', 'id');
SELECT * FROM spec;

CREATE TABLE test2 (
    num_value1 INTEGER,
    num_value2 INTEGER
);

SELECT func('test2', 'num_value1');
SELECT * FROM spec;
SELECT func('test2', 'num_value1');
SELECT * FROM spec;

INSERT INTO test2 (num_value1, num_value2) VALUES (2, 13);

SELECT func('test2', 'num_value2');
SELECT * FROM spec;
SELECT func('test2', 'num_value1');
SELECT func('test2', 'num_value1');
SELECT func('test2', 'num_value1');
SELECT func('test2', 'num_value1');
SELECT func('test2', 'num_value1');
SELECT * FROM spec;

DROP FUNCTION func;

DROP TABLE test;
DROP TABLE test2;
DROP TABLE spec;