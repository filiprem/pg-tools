-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION ddl_versioning" to load this file. \quit

CREATE TABLE ddl_versioning_object (
	object_id serial PRIMARY KEY,
	object_type text NOT NULL,
	object_identity text NOT NULL,
	UNIQUE (object_type, object_identity)
);

CREATE TABLE ddl_versioning_version (
	object_id integer NOT NULL REFERENCES ddl_versioning_object,
	version_id integer NOT NULL,
	object_definition text NOT NULL,
	created_at timestamptz NOT NULL,
	created_by name NOT NULL,
	PRIMARY KEY (object_id, version_id)
);

CREATE OR REPLACE FUNCTION ddl_versioning_get_tabledef(oid) RETURNS text
LANGUAGE sql STRICT AS $$
/* snatched from https://github.com/filiprem/pg-tools */
WITH attrdef AS (
    SELECT
        n.nspname,
        c.relname,
        pg_catalog.array_to_string(c.reloptions || array(select 'toast.' || x from pg_catalog.unnest(tc.reloptions) x), ', ') as relopts,
        c.relpersistence,
        a.attnum,
        a.attname,
        pg_catalog.format_type(a.atttypid, a.atttypmod) as atttype,
        (SELECT substring(pg_catalog.pg_get_expr(d.adbin, d.adrelid, true) for 128) FROM pg_catalog.pg_attrdef d
            WHERE d.adrelid = a.attrelid AND d.adnum = a.attnum AND a.atthasdef) as attdefault,
        a.attnotnull,
        (SELECT c.collname FROM pg_catalog.pg_collation c, pg_catalog.pg_type t
            WHERE c.oid = a.attcollation AND t.oid = a.atttypid AND a.attcollation <> t.typcollation) as attcollation,
        a.attidentity,
        a.attgenerated
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON a.attrelid = c.oid
    JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
    LEFT JOIN pg_catalog.pg_class tc ON (c.reltoastrelid = tc.oid)
    WHERE a.attrelid = $1
        AND a.attnum > 0
        AND NOT a.attisdropped
    ORDER BY a.attnum
),
coldef AS (
    SELECT
        attrdef.nspname,
        attrdef.relname,
        attrdef.relopts,
        attrdef.relpersistence,
        pg_catalog.format(
            '%I %s%s%s%s%s',
            attrdef.attname,
            attrdef.atttype,
            case when attrdef.attcollation is null then '' else pg_catalog.format(' COLLATE %I', attrdef.attcollation) end,
            case when attrdef.attnotnull then ' NOT NULL' else '' end,
            case when attrdef.attdefault is null then ''
                else case when attrdef.attgenerated = 's' then pg_catalog.format(' GENERATED ALWAYS AS (%s) STORED', attrdef.attdefault)
                    when attrdef.attgenerated <> '' then ' GENERATED AS NOT_IMPLEMENTED'
                    else pg_catalog.format(' DEFAULT %s', attrdef.attdefault)
                end
            end,
            case when attrdef.attidentity<>'' then pg_catalog.format(' GENERATED %s AS IDENTITY',
                    case attrdef.attidentity when 'd' then 'BY DEFAULT' when 'a' then 'ALWAYS' else 'NOT_IMPLEMENTED' end)
                else '' end
        ) as col_create_sql
    FROM attrdef
    ORDER BY attrdef.attnum
),
tabdef AS (
    SELECT
        coldef.nspname,
        coldef.relname,
        coldef.relopts,
        coldef.relpersistence,
        string_agg(coldef.col_create_sql, E',\n    ') as cols_create_sql
    FROM coldef
    GROUP BY
        coldef.nspname, coldef.relname, coldef.relopts, coldef.relpersistence
)
SELECT
    format(
        'CREATE%s TABLE %I.%I%s%s%s;',
        case tabdef.relpersistence when 't' then ' TEMP' when 'u' then ' UNLOGGED' else '' end,
        tabdef.nspname,
        tabdef.relname,
        coalesce(
            (SELECT format(E'\n    PARTITION OF %I.%I %s\n', pn.nspname, pc.relname,
                pg_get_expr(c.relpartbound, c.oid))
                FROM pg_class c JOIN pg_inherits i ON c.oid = i.inhrelid
                JOIN pg_class pc ON pc.oid = i.inhparent
                JOIN pg_namespace pn ON pn.oid = pc.relnamespace
                WHERE c.oid = $1),
            format(E' (\n    %s\n)', tabdef.cols_create_sql)
        ),
        case when tabdef.relopts <> '' then format(' WITH (%s)', tabdef.relopts) else '' end,
        coalesce(E'\nPARTITION BY '||pg_get_partkeydef($1), '')
    ) as table_create_sql
FROM tabdef
$$;

CREATE OR REPLACE FUNCTION ddl_versioning_record(_type text, _identity text, _definition text)
RETURNS void
STRICT
LANGUAGE plpgsql AS $$
DECLARE
	_object_id integer;
	_version_id integer;
BEGIN
	SELECT object_id INTO _object_id FROM ddl_versioning_object WHERE object_type = _type AND object_identity = _identity;
	IF _object_id IS NULL THEN
		INSERT INTO ddl_versioning_object(object_type, object_identity) SELECT _type, _identity RETURNING object_id INTO _object_id;
	END IF;
	SELECT max(version_id)+1 INTO _version_id FROM ddl_versioning_version WHERE object_id = _object_id;
	IF _version_id IS NULL THEN
		_version_id := 1;
	END IF;

	RAISE LOG 'ddl_versioning_record type[%] identity[%] object_id[%] version_id[%]', _type, _identity, _object_id, _version_id;

	INSERT INTO ddl_versioning_version (object_id, version_id, object_definition, created_at, created_by)
	SELECT _object_id, _version_id, _definition, current_timestamp, current_user;
END;
$$;

CREATE OR REPLACE FUNCTION ddl_versioning_trigger() RETURNS event_trigger
LANGUAGE plpgsql AS $$
DECLARE
	r record;
	objdef text;
BEGIN
	RAISE DEBUG 'ddl_versioning_trigger event[%] tag[%]', TG_EVENT, TG_TAG;
	FOR r IN SELECT
		classid, objid, objsubid, command_tag, object_type, schema_name, object_identity, in_extension, command
		FROM pg_event_trigger_ddl_commands() WHERE NOT in_extension
	LOOP
		IF r.object_type = 'table' THEN
			objdef := ddl_versioning_get_tabledef(r.objid);
		ELSIF r.object_type = 'index' THEN
			objdef := pg_get_indexdef(r.objid);
		ELSIF r.object_type = 'function' THEN
			objdef := pg_get_functiondef(r.objid);
		ELSIF r.object_type = 'view' THEN
			objdef := pg_get_viewdef(r.objid);
		ELSE
			RAISE LOG 'ddl_versioning_trigger object_type[%] is not supported', r.object_type;
		END IF;
		RAISE DEBUG 'ddl_versioning_trigger command_tag[%] object_type[%] object_identity[%] objdef[%]',
			r.command_tag, r.object_type, r.object_identity, objdef;
		PERFORM ddl_versioning_record(r.object_type, r.object_identity, objdef);
	END LOOP;
END;
$$;

CREATE EVENT TRIGGER ddl_versioning_trigger ON ddl_command_end
WHEN tag IN (
	'ALTER DOMAIN',
	'ALTER FOREIGN TABLE',
	'ALTER FUNCTION',
	'ALTER MATERIALIZED VIEW',
	'ALTER PROCEDURE',
	'ALTER SEQUENCE',
	'ALTER TABLE',
	'ALTER VIEW',
	'CREATE DOMAIN',
	'CREATE FOREIGN TABLE',
	'CREATE FUNCTION',
	'CREATE INDEX',
	'CREATE MATERIALIZED VIEW',
	'CREATE PROCEDURE',
	'CREATE SEQUENCE',
	'CREATE TABLE',
	'CREATE TABLE AS',
	'CREATE VIEW',
	'DROP DOMAIN',
	'DROP FOREIGN TABLE',
	'DROP FUNCTION',
	'DROP INDEX',
	'DROP MATERIALIZED VIEW',
	'DROP PROCEDURE',
	'DROP SEQUENCE',
	'DROP TABLE',
	'DROP VIEW',
	'IMPORT FOREIGN SCHEMA',
	'SELECT INTO'
)
EXECUTE FUNCTION ddl_versioning_trigger();

