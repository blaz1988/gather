require_relative "rsvps_table_helpers"

# Works against the comments table directly, since there is no Comment model yet.
# Shared by spec/ and features/.
module CommentsTableHelpers
  include RsvpsTableHelpers

  CREATE_COMMENTS_VERSION = 20260930133104

  def insert_comment(event_id:, user_id:, body: "Is there parking nearby?")
    now = Time.current
    db.insert(ActiveRecord::Base.sanitize_sql_array([
      "INSERT INTO comments (event_id, user_id, body, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
      event_id, user_id, body, now, now
    ]))
  end

  def comments_index(name)
    db.indexes(:comments).find { |index| index.name == name }
  end

  def run_create_comments(direction)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection_pool.migration_context.run(direction, CREATE_COMMENTS_VERSION)
    end
    db.schema_cache.clear!
  end
end
