# Durable, replicated source-of-truth data (rollups, later incidents/maintenance) on the persistent DB.
class Upright::PersistentRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :persistent, reading: :persistent }
end
