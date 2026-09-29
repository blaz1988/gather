# Scenarios that use several database connections at once (threads) cannot run
# inside the default cleaner transaction, so they commit and are wiped afterwards.
After("@no-database-cleaner") do
  DatabaseCleaner.clean_with(:deletion)
end
