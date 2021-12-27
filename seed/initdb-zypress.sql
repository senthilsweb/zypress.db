/* Create the database */
-- This is to create a schema inside a database instead of creating a blank database.
-- Postgres does not allow to drop a database within the same connection. 
-- Also, postgres does not allow switch database within sql statement. A new connection must be estabilished for changing database target.
drop schema if exists zypress cascade;
create schema zypress;
set schema 'zypress';


/* Generic DB objects (Starts)*/

--UUID Extension
drop EXTENSION if exists "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--View to extract postgres metadata

  CREATE OR REPLACE VIEW vw_meta_column AS
 SELECT a.attname AS column_name,
    d.description,
    c.relname
   FROM pg_class c
     JOIN pg_attribute a ON c.oid = a.attrelid
     LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
     LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
     LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = a.attnum
  WHERE (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char"])) AND c.relname = 'State'::name
  ORDER BY n.nspname, c.relname, a.attname;
ALTER TABLE vw_meta_column
    OWNER TO zypress_user;

/*Table creation (Starts)*/

  CREATE TABLE configuration
  (
        id                SERIAL,
        code CHARACTER VARYING,
        NAME              CHARACTER VARYING NOT NULL,
        parent_code       CHARACTER VARYING,
        description       CHARACTER VARYING,

        additional_attributes JSONB,
        is_enabled        BOOLEAN DEFAULT true,
        mark_as_delete    BOOLEAN DEFAULT false,
        tenant CHARACTER VARYING,
        published_at      TIMESTAMP(6) WITH time zone,
        update_count      INTEGER DEFAULT 0,
        created_by        INTEGER,
        updated_by        INTEGER,
        created_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id),
        CONSTRAINT uc__configuration__code__parent_code UNIQUE (code, parent_code)
  ); 
  CREATE SEQUENCE configuration_sequence OWNED BY configuration.id;
  select setval('configuration_sequence',  (SELECT MAX(id) FROM configuration));

CREATE TABLE 
    configurations
    ( 
        id                  SERIAL NOT NULL, 
        code                CHARACTER VARYING, 
        parent_code         CHARACTER VARYING, 
        NAME                CHARACTER VARYING NOT NULL, 
        description         CHARACTER VARYING, 

        additional_attributes JSONB,
        is_enabled          BOOLEAN DEFAULT true,
        mark_as_delete      BOOLEAN DEFAULT false,
        tenant              CHARACTER VARYING,
        published_at        TIMESTAMP(6) WITH time zone,
        update_count        INTEGER DEFAULT 0,
        created_by          INTEGER,
        updated_by          INTEGER,
        created_at          TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at          TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id),
        CONSTRAINT uc_configurations_code_parent_code UNIQUE (code, parent_code) 
    );
    CREATE SEQUENCE configurations_sequence OWNED BY configurations.id;
    select setval('configurations_sequence',  (SELECT MAX(id) FROM configurations));


CREATE TABLE
    users
    (
        id SERIAL NOT NULL,
        code CHARACTER VARYING,
        login CHARACTER VARYING DEFAULT ''::CHARACTER VARYING NOT NULL,
        hashed_password CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING NOT NULL,
        firstname CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING,
        lastname CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING,
        email CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING NOT NULL,
        admin BOOLEAN DEFAULT false NOT NULL,
        last_login_on TIMESTAMP(6) WITH TIME ZONE,
        language CHARACTER VARYING(5) DEFAULT ''::CHARACTER VARYING,
        auth_source_id INTEGER,
        salt CHARACTER VARYING(64),
        must_change_password BOOLEAN DEFAULT false NOT NULL,
        passwd_changed_on TIMESTAMP(6) WITH TIME ZONE,

        additional_attributes JSONB,
        is_enabled        BOOLEAN DEFAULT true,
        mark_as_delete    BOOLEAN DEFAULT false,
        tenant CHARACTER VARYING,
        published_at      TIMESTAMP(6) WITH time zone,
        update_count      INTEGER DEFAULT 0,
        created_by        INTEGER,
        updated_by        INTEGER,
        created_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id)
    );
    CREATE SEQUENCE users_sequence OWNED BY users.id;
    select setval('users_sequence',  (SELECT MAX(id) FROM users));

    CREATE TABLE 
    role
    ( 
        id SERIAL NOT NULL,
        code CHARACTER VARYING,
        NAME CHARACTER VARYING NOT NULL, 
        description CHARACTER VARYING, 

        additional_attributes JSONB,
        is_enabled        BOOLEAN DEFAULT true,
        mark_as_delete    BOOLEAN DEFAULT false,
        tenant CHARACTER VARYING,
        published_at      TIMESTAMP(6) WITH time zone,
        update_count      INTEGER DEFAULT 0,
        created_by        INTEGER,
        updated_by        INTEGER,
        created_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id)
    );
    CREATE SEQUENCE role_sequence OWNED BY role.id;
    select setval('role_sequence',  (SELECT MAX(id) FROM role));

CREATE TABLE 
    users_role
    ( 
        id SERIAL NOT NULL,
        role_id INTEGER NOT NULL, 
        user_id INTEGER NOT NULL,
        code CHARACTER VARYING, 
        address_type INTEGER, 
       
        additional_attributes JSONB,
        is_enabled        BOOLEAN DEFAULT true,
        mark_as_delete    BOOLEAN DEFAULT false,
        tenant CHARACTER VARYING,
        published_at      TIMESTAMP(6) WITH time zone,
        update_count      INTEGER DEFAULT 0,
        created_by        INTEGER,
        updated_by        INTEGER,
        created_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id)
    );
    CREATE SEQUENCE users_role_sequence OWNED BY users_role.id;
    select setval('users_role_sequence',  (SELECT MAX(id) FROM users_role));

CREATE TABLE 
    address
    ( 
        id SERIAL,
        code CHARACTER VARYING, 
        addressline1 CHARACTER VARYING,
        addressline2 CHARACTER VARYING,
        city       CHARACTER VARYING,
        state      CHARACTER VARYING,
        country    CHARACTER VARYING,
        postalcode CHARACTER VARYING,
        latitude DOUBLE PRECISION, 
        longitude DOUBLE PRECISION, 
        radius       BIGINT, 
        primary_address   BOOLEAN DEFAULT false,
        address_type CHARACTER VARYING,
        entity_type  CHARACTER VARYING,

        additional_attributes JSONB,
        is_enabled        BOOLEAN DEFAULT true,
        mark_as_delete    BOOLEAN DEFAULT false,
        tenant CHARACTER VARYING,
        published_at      TIMESTAMP(6) WITH time zone,
        update_count      INTEGER DEFAULT 0,
        created_by        INTEGER,
        updated_by        INTEGER,
        created_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id)
    );
    CREATE SEQUENCE address_sequence OWNED BY address.id;
    select setval('address_sequence',  (SELECT MAX(id) FROM address));

CREATE TABLE 
    navigation
    ( 
        id SERIAL,
        code        CHARACTER VARYING, 
        parent_code CHARACTER VARYING, 
        NAME        CHARACTER VARYING NOT NULL, 
        description CHARACTER VARYING, 
        icon        CHARACTER VARYING, 
        link        CHARACTER VARYING, 

        additional_attributes JSONB,
        is_enabled        BOOLEAN DEFAULT true,
        mark_as_delete    BOOLEAN DEFAULT false,
        tenant CHARACTER VARYING,
        published_at      TIMESTAMP(6) WITH time zone,
        update_count      INTEGER DEFAULT 0,
        created_by        INTEGER,
        updated_by        INTEGER,
        created_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id),

        CONSTRAINT uc_navigation_code_parent_code UNIQUE (code, parent_code) 
    );
    CREATE SEQUENCE navigation_sequence OWNED BY navigation.id;
    select setval('navigation_sequence',  (SELECT MAX(id) FROM navigation));


CREATE TABLE 
    country
    ( 
        id SERIAL, 
        NAME CHARACTER VARYING, 
        code CHARACTER VARYING, 
        alpha_2 CHARACTER VARYING, 
        alpha_3 CHARACTER VARYING,
        isdcode       CHARACTER VARYING,
        language       CHARACTER VARYING,

        additional_attributes JSONB,
        is_enabled        BOOLEAN DEFAULT true,
        mark_as_delete    BOOLEAN DEFAULT false,
        tenant CHARACTER VARYING,
        published_at      TIMESTAMP(6) WITH time zone,
        update_count      INTEGER DEFAULT 0,
        created_by        INTEGER,
        updated_by        INTEGER,
        created_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        updated_at        TIMESTAMP(6) WITH time zone DEFAULT now(),
        PRIMARY KEY (id)
    );
    CREATE SEQUENCE country_sequence OWNED BY country.id;
    select setval('country_sequence',  (SELECT MAX(id) FROM country));

/*Table creation (Ends)*/


/* Seed data population (Starts) */

--Navigation

INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (1, 'a9e15ed3-4368-464c-a4a2-7cf95fa62fa5', null, 'About Us', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (2, '04d8f41f-7eee-42c8-af3d-d501c03c60a8', null, 'Services', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (3, '2c272665-2e3e-475a-b789-0215292c0fed', null, 'Industries', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (4, '007962cf-0a63-4d82-b633-ade017635c7b', 'a9e15ed3-4368-464c-a4a2-7cf95fa62fa5', 'Company', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (6, 'd8c2fc4f-c7ef-481d-a50f-f34258168df9', 'a9e15ed3-4368-464c-a4a2-7cf95fa62fa5', 'Facilities', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (8, 'e694d4af-0367-4204-9e90-28ea9dbc6ebe', '04d8f41f-7eee-42c8-af3d-d501c03c60a8', 'Mobile App Development', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (12, 'a171aa22-821b-4844-9682-58bd9e3e45cd', '2c272665-2e3e-475a-b789-0215292c0fed', 'Healthcare & Pharma', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (14, '22d77230-791d-42a0-a175-7abfd701bd5a', '2c272665-2e3e-475a-b789-0215292c0fed', 'Retail & Manufacturing', null, null, null, null, true, false, null, 0, null, null, null, '2021-04-25 07:05:05', '2021-04-25 07:05:05');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (11, '172dc9ac-3b6f-472b-a4d2-4d27638da6c0', '2c272665-2e3e-475a-b789-0215292c0fed', 'Fintech', null, null, null, null, true, true, null, 1, null, null, null, '2021-04-25 07:05:05', '2021-05-16 13:41:16');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (7, 'a136fc96-ea7d-4e70-98ad-3f9ebdee6b35', '04d8f41f-7eee-42c8-af3d-d501c03c60a8', 'Web Development', '', null, null, null, false, false, null, 3, null, null, null, '2021-04-25 07:05:05', '2021-05-16 13:41:51');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (9, '8ad963ed-b640-48bf-b05f-771201e2bac9', '04d8f41f-7eee-42c8-af3d-d501c03c60a8', 'Digital Marketing', '', null, null, null, false, false, null, 7, null, null, null, '2021-04-25 07:05:05', '2021-05-16 13:42:26');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (5, '2b8889d0-df91-4350-a05c-4e14f36adc5e', 'a9e15ed3-4368-464c-a4a2-7cf95fa62fa5', 'Board of Directors', '', null, null, null, true, false, null, 1, null, null, null, '2021-04-25 07:05:05', '2021-05-16 13:45:00');
INSERT INTO navigation (id, code, parent_code, name, description, icon, link, additional_attributes, is_enabled, mark_as_delete, published_at, update_count, tenant, created_by, updated_by, created_at, updated_at) VALUES (13, 'c0f3c73f-3ad5-42a7-9b61-bfad888b76eb', '2c272665-2e3e-475a-b789-0215292c0fed', 'Aerospace', '', null, null, null, false, false, null, 6, null, null, null, '2021-04-25 07:05:05', '2021-05-16 13:55:42');

--Countries (Download from github)
--https://github.com/stefangabos/world_countries/




/* Seed data population (Ends) */

/* Generic DB objects (Ends)*/

/* Specific DB objects (Starts)*/

/* Specific DB objects (Ends)*/
