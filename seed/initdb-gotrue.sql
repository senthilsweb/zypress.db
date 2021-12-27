/* Create the database */
-- This is to create a schema inside a database instead of creating a blank database.
-- Postgres does not allow to drop a database within the same connection. 
-- Also, postgres does not allow switch database within sql statement. A new connection must be estabilished for changing database target.
CREATE USER zypress_admin LOGIN CREATEROLE
CREATEDB REPLICATION BYPASSRLS;

CREATE SCHEMA
IF NOT EXISTS auth AUTHORIZATION zypress_admin;


set schema 'auth';


-- auth.users definition

CREATE TABLE auth.users
(
    instance_id uuid NULL,
    id uuid NOT NULL UNIQUE,
    aud varchar(255) NULL,
    "role" varchar(255) NULL,
    email varchar(255) NULL UNIQUE,
    encrypted_password varchar(255) NULL,
    confirmed_at timestamptz NULL,
    invited_at timestamptz NULL,
    confirmation_token varchar(255) NULL,
    confirmation_sent_at timestamptz NULL,
    recovery_token varchar(255) NULL,
    recovery_sent_at timestamptz NULL,
    email_change_token varchar(255) NULL,
    email_change varchar(255) NULL,
    email_change_sent_at timestamptz NULL,
    last_sign_in_at timestamptz NULL,
    raw_app_meta_data jsonb NULL,
    raw_user_meta_data jsonb NULL,
    is_super_admin bool NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE INDEX users_instance_id_email_idx ON auth.users USING btree
(instance_id, email);
CREATE INDEX users_instance_id_idx ON auth.users USING btree
(instance_id);
comment on table auth.users is 'Auth: Stores user login data within a secure schema.';

-- auth.refresh_tokens definition

CREATE TABLE auth.refresh_tokens
(
    instance_id uuid NULL,
    id bigserial NOT NULL,
    "token" varchar(255) NULL,
    user_id varchar(255) NULL,
    revoked bool NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id)
);
CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree
(instance_id);
CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree
(instance_id, user_id);
CREATE INDEX refresh_tokens_token_idx ON auth.refresh_tokens USING btree
(token);
comment on table auth.refresh_tokens is 'Auth: Store of tokens used to refresh JWT tokens once they expire.';

-- auth.instances definition

CREATE TABLE auth.instances
(
    id uuid NOT NULL,
    uuid uuid NULL,
    raw_base_config text NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT instances_pkey PRIMARY KEY (id)
);
comment on table auth.instances is 'Auth: Manages users across multiple sites.';

-- auth.audit_log_entries definition

CREATE TABLE auth.audit_log_entries
(
    instance_id uuid NULL,
    id uuid NOT NULL,
    payload json NULL,
    created_at timestamptz NULL,
    CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id)
);
CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree
(instance_id);
comment on table auth.audit_log_entries is 'Auth: Audit trail for user actions.';

-- auth.schema_migrations definition

CREATE TABLE auth.schema_migrations
(
    "version" varchar(255) NOT NULL,
    CONSTRAINT schema_migrations_pkey PRIMARY KEY ("version")
);
comment on table auth.schema_migrations is 'Auth: Manages updates to the auth system.';

INSERT INTO auth.schema_migrations
    (version)
VALUES
    ('20171026211738'),
    ('20171026211808'),
    ('20171026211834'),
    ('20180103212743'),
    ('20180108183307'),
    ('20180119214651'),
    ('20180125194653');

-- Gets the User ID from the request cookie
create or replace function auth.uid
() returns uuid as $$
select nullif(current_setting('request.jwt.claim.sub', true), '')
::uuid;
$$ language sql stable;

-- Gets the User ID from the request cookie
create or replace function auth.role
() returns text as $$
select nullif(current_setting('request.jwt.claim.role', true), '')
::text;
$$ language sql stable;

-- zypress super admin
CREATE USER zypress_auth_admin NOINHERIT CREATEROLE
LOGIN NOREPLICATION;
GRANT ALL PRIVILEGES ON SCHEMA auth TO zypress_auth_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO zypress_auth_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO zypress_auth_admin;
ALTER USER zypress_auth_admin
SET search_path
= "auth";
ALTER USER zypress_auth_admin with password 'root';
ALTER table "auth".users OWNER TO zypress_auth_admin;
ALTER table "auth".refresh_tokens OWNER TO zypress_auth_admin;
ALTER table "auth".audit_log_entries OWNER TO zypress_auth_admin;
ALTER table "auth".instances OWNER TO zypress_auth_admin;
ALTER table "auth".schema_migrations OWNER TO zypress_auth_admin;


/*Custom*/

-- alter user schema

ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS phone VARCHAR(15) NULL UNIQUE DEFAULT NULL,
ADD COLUMN IF NOT EXISTS phone_confirmed_at timestamptz NULL DEFAULT NULL,
ADD COLUMN IF NOT EXISTS phone_change VARCHAR(15) NULL DEFAULT '',
ADD COLUMN IF NOT EXISTS phone_change_token VARCHAR(255) NULL DEFAULT '',
ADD COLUMN IF NOT EXISTS phone_change_sent_at timestamptz NULL DEFAULT NULL;

DO $$
BEGIN
  IF NOT EXISTS(SELECT *
    FROM information_schema.columns
    WHERE table_schema = 'auth' and table_name='users' and column_name='email_confirmed_at')
  THEN
      ALTER TABLE "auth"."users" RENAME COLUMN "confirmed_at" TO "email_confirmed_at";
  END IF;
END $$;


ALTER TABLE auth.users
ADD COLUMN IF NOT EXISTS confirmed_at timestamptz GENERATED ALWAYS AS (LEAST (users.email_confirmed_at, users.phone_confirmed_at)) STORED;

-- adds email_change_confirmed

ALTER TABLE auth.users
ADD COLUMN IF NOT EXISTS email_change_token_current varchar(255) null DEFAULT '', 
ADD COLUMN IF NOT EXISTS email_change_confirm_status smallint DEFAULT 0 CHECK (email_change_confirm_status >= 0 AND email_change_confirm_status <= 2);

DO $$
BEGIN
  IF NOT EXISTS(SELECT *
    FROM information_schema.columns
    WHERE table_schema = 'auth' and table_name='users' and column_name='email_change_token_new')
  THEN
      ALTER TABLE "auth"."users" RENAME COLUMN "email_change_token" TO "email_change_token_new";
  END IF;
END $$;

-- adds identities table 

CREATE TABLE IF NOT EXISTS auth.identities (
    id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data JSONB NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamptz NULL,
    created_at timestamptz NULL,
    updated_at timestamptz NULL,
    CONSTRAINT identities_pkey PRIMARY KEY (provider, id),
    CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);
COMMENT ON TABLE auth.identities is 'Auth: Stores identities associated to a user.';



