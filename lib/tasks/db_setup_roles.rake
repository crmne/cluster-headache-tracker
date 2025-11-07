# frozen_string_literal: true

def run
  load_dotenv
  ensure_psql_available

  host = ENV.fetch("PGHOST", "localhost")
  port = ENV.fetch("PGPORT", "5432")
  superuser = ENV.fetch("PG_SUPERUSER", ENV.fetch("PGUSER", "postgres"))
  superuser_password = ENV["PG_SUPERUSER_PASSWORD"] || ENV["PGPASSWORD"]
  maintenance_db = ENV.fetch("PG_MAINTENANCE_DB", ENV.fetch("PGDATABASE", "postgres"))

  app_role = ENV.fetch("DB_APP_USER", "cluster_headache_tracker")
  app_password = ENV["POSTGRES_PASSWORD"] || ENV["DB_APP_PASSWORD"]
  abort_with("Missing POSTGRES_PASSWORD (or DB_APP_PASSWORD). Set it in your environment or .env first.") unless app_password

  databases = ENV.fetch("DB_APP_DATABASES", "cluster_headache_tracker_development,cluster_headache_tracker_test")
  database_names = databases.split(",").map(&:strip).reject(&:empty?)
  abort_with("DB_APP_DATABASES is empty; nothing to do.") if database_names.empty?

  psql_env = {
    "PGHOST" => host,
    "PGPORT" => port,
    "PGUSER" => superuser,
    "PGDATABASE" => maintenance_db
  }
  psql_env["PGPASSWORD"] = superuser_password if superuser_password

  puts "Connecting to #{psql_env['PGHOST']}:#{psql_env['PGPORT']} as #{psql_env['PGUSER']} (database: #{psql_env['PGDATABASE']})"

  ensure_role(psql_env, app_role, app_password)
  database_names.each { |db_name| ensure_database(psql_env, db_name, app_role) }

  puts "PostgreSQL role and databases are ready."
  puts "Next: run `bin/rails db:prepare` to migrate and seed the schema."
end

def load_dotenv
  require "dotenv"
  Dotenv.load
rescue LoadError
  # Dotenv is optional; skip if the gem isn't available yet.
end

def ensure_psql_available
  Open3.capture3("psql", "--version")
rescue Errno::ENOENT
  abort_with("psql command not found. Please install the PostgreSQL client tools.")
end

def ensure_role(env, role, password)
  role_exists = run_psql(env, "SELECT 1 FROM pg_roles WHERE rolname = #{quote_literal(role)}")
  if role_exists.empty?
    puts "Creating role #{role.inspect}..."
    run_psql(env, "CREATE ROLE #{quote_ident(role)} WITH LOGIN PASSWORD #{quote_literal(password)}")
  else
    puts "Role #{role.inspect} already exists; updating password..."
    run_psql(env, "ALTER ROLE #{quote_ident(role)} WITH LOGIN PASSWORD #{quote_literal(password)}")
  end
  puts "Ensuring #{role.inspect} can create databases..."
  run_psql(env, "ALTER ROLE #{quote_ident(role)} CREATEDB")
  puts "Granting #{role.inspect} superuser privileges so Rails can disable referential integrity during tests..."
  run_psql(env, "ALTER ROLE #{quote_ident(role)} SUPERUSER")
end

def ensure_database(env, database_name, owner)
  db_exists = run_psql(env, "SELECT 1 FROM pg_database WHERE datname = #{quote_literal(database_name)}")
  if db_exists.empty?
    puts "Creating database #{database_name.inspect} owned by #{owner.inspect}..."
    run_psql(env, "CREATE DATABASE #{quote_ident(database_name)} OWNER #{quote_ident(owner)}")
  else
    puts "Database #{database_name.inspect} already exists; ensuring owner is #{owner.inspect}..."
    run_psql(env, "ALTER DATABASE #{quote_ident(database_name)} OWNER TO #{quote_ident(owner)}")
  end
end

def run_psql(env, sql)
  stdout, stderr, status = Open3.capture3(env, "psql", "-v", "ON_ERROR_STOP=1", "-Atqc", sql)
  abort_with("psql failed:\n#{stderr}") unless status.success?
  stdout.strip
end

def quote_ident(identifier)
  %("#{identifier.gsub('"', '""')}")
end

def quote_literal(value)
  "'#{value.gsub("'", "''")}'"
end

def abort_with(message)
  warn(message)
  exit(1)
end

namespace :db do
  desc "Provision the PostgreSQL role and databases required by the app"
  task :setup_roles do
    run
  end
end
