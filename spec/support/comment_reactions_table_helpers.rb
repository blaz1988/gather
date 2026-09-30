require_relative "comments_table_helpers"

# Works against the comment_reactions table directly, since there is no CommentReaction model yet.
# Shared by spec/ and features/.
module CommentReactionsTableHelpers
  include CommentsTableHelpers

  CREATE_COMMENT_REACTIONS_VERSION = 20260930183400

  def insert_comment_reaction(comment_id:, user_id:, kind: "like")
    now = Time.current
    db.insert(ActiveRecord::Base.sanitize_sql_array([
      "INSERT INTO comment_reactions (comment_id, user_id, kind, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
      comment_id, user_id, kind, now, now
    ]))
  end

  def comment_reactions_index(name)
    db.indexes(:comment_reactions).find { |index| index.name == name }
  end

  def comment_reactions_count(where = nil)
    db.select_value("SELECT COUNT(*) FROM comment_reactions#{" WHERE #{where}" if where}")
  end

  def run_create_comment_reactions(direction)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Base.connection_pool.migration_context.run(direction, CREATE_COMMENT_REACTIONS_VERSION)
    end
    db.schema_cache.clear!
  end
end
