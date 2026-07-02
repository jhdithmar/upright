class Upright::IncidentUpdate < Upright::PersistentRecord
  belongs_to :incident, class_name: "Upright::Incident", inverse_of: :updates

  validates :status, :body, presence: true
end
