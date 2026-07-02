class Upright::Incident < Upright::PersistentRecord
  include Upright::Incidents::Lifecycle

  enum :status, %w[ investigating monitoring resolved
                    scheduled in_progress completed ].index_with(&:itself)
  enum :impact, %w[ minor major critical maintenance ].index_with(&:itself), prefix: true

  STATUSES          = %w[ investigating monitoring resolved ]
  TERMINAL_STATUSES = %w[ resolved ]
  IMPACTS           = %w[ minor major critical ]

  has_many :updates, -> { order(created_at: :desc) },
    class_name: "Upright::IncidentUpdate", inverse_of: :incident, dependent: :destroy
  has_many :affected_services,
    class_name: "Upright::IncidentAffectedService", inverse_of: :incident, dependent: :destroy

  validates :title, :starts_at, presence: true
  validates :status, inclusion: { in: ->(incident) { incident.class::STATUSES } }
  validates :impact, inclusion: { in: ->(incident) { incident.class::IMPACTS } }

  def maintenance? = false

  def service_codes = affected_services.map(&:service_code)

  def service_codes=(codes)
    self.affected_services = Array(codes).reject(&:blank?).uniq.map do |code|
      affected_services.find { |s| s.service_code == code } ||
        affected_services.build(service_code: code)
    end
  end

  def services
    service_codes.filter_map { |code| Upright::Service.find_by(code: code) }
  end
end
