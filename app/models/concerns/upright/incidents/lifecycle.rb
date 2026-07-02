module Upright::Incidents::Lifecycle
  extend ActiveSupport::Concern

  included do
    scope :active,   -> { where(resolved_at: nil).where(starts_at: ..Time.current) }
    scope :upcoming, -> { where(resolved_at: nil).where(starts_at: Time.current..) }
    scope :past,     -> { where.not(resolved_at: nil).order(starts_at: :desc) }

    scope :reactive, -> { where.not(type: "Upright::Maintenance").or(where(type: nil)) }

    scope :for_service, ->(code) {
      joins(:affected_services).where(upright_incident_affected_services: { service_code: code })
    }
  end

  def active?   = resolved_at.nil? && starts_at <= Time.current
  def upcoming? = resolved_at.nil? && starts_at > Time.current
  def past?     = resolved_at.present?

  def record_update(status:, body:)
    transaction do
      updates.create!(status: status, body: body)
      self.status = status
      self.resolved_at = Time.current if resolved_at.nil? && self.class::TERMINAL_STATUSES.include?(status)
      save!
    end
  end
end
