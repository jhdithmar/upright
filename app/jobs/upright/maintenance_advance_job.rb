class Upright::MaintenanceAdvanceJob < Upright::ApplicationJob
  queue_as :default

  def perform
    Upright::Maintenance.where(resolved_at: nil).find_each(&:auto_advance_status)
    Upright::Maintenance.export_service_metrics
  end
end
