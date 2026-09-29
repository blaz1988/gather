# Works against the rsvps table directly, since there is no Rsvp model yet.
# Shared by spec/ and features/.
module RsvpsTableHelpers
  CREATE_RSVPS_VERSION = 20260929214624

  def db
    ActiveRecord::Base.connection
  end

  def insert_rsvp(event_id:, user_id:, status: "going")
    now = Time.current
    db.insert(ActiveRecord::Base.sanitize_sql_array([
      "INSERT INTO rsvps (event_id, user_id, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
      event_id, user_id, status, now, now
    ]))
  end

  def rsvps_index(name)
    db.indexes(:rsvps).find { |index| index.name == name }
  end

  def table_snapshot(*tables)
    tables.index_with do |table|
      {
        columns: db.columns(table).map { |c| [ c.name, c.sql_type, c.null, c.default ] },
        indexes: db.indexes(table).map { |i| [ i.name, i.columns, i.unique ] },
        foreign_keys: db.foreign_keys(table).map { |fk| [ fk.to_table, fk.column, fk.on_delete ] },
        rows: db.select_rows("SELECT * FROM #{db.quote_table_name(table)} ORDER BY id")
      }
    end
  end

  def run_create_rsvps(direction)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection_pool.migration_context.run(direction, CREATE_RSVPS_VERSION)
    end
    db.schema_cache.clear!
  end
end
