require "test_helper"

class Upright::IncidentTest < ActiveSupport::TestCase
  test "a reactive incident is valid and is not a maintenance" do
    incident = Upright::Incident.new(title: "DB slow", impact: "major", status: "investigating", starts_at: Time.current)

    assert incident.valid?
    assert_not incident.maintenance?
  end

  test "rejects a status outside the reactive lifecycle" do
    incident = Upright::Incident.new(title: "x", impact: "minor", status: "scheduled", starts_at: Time.current)

    assert_not incident.valid?
    assert incident.errors[:status].any?
  end

  test "record_update appends an update, moves status, and stamps resolved_at on a terminal status" do
    incident = Upright::Incident.create!(title: "x", impact: "minor", status: "investigating", starts_at: Time.current)

    incident.record_update(status: "monitoring", body: "Watching recovery.")
    assert_equal "monitoring", incident.reload.status
    assert_nil incident.resolved_at
    assert_equal 2, incident.updates.count

    incident.record_update(status: "resolved", body: "All clear.")
    assert_equal "resolved", incident.reload.status
    assert_not_nil incident.resolved_at
  end

  test "creating an incident seeds an initial update from the default status" do
    incident = Upright::Incident.create!(title: "x", impact: "minor", starts_at: Time.current, body: "Looking into it.")

    assert_equal "investigating", incident.status
    assert_equal 1, incident.updates.count
    assert_equal "Looking into it.", incident.updates.first.body
  end

  test "active_statuses maps active reactive incident impact to a page status" do
    Upright::Incident.create!(title: "x", impact: "major", starts_at: 1.hour.ago)

    assert_equal [ :partial_outage ], Upright::Incident.active_statuses
  end

  test "service_codes= assigns affected services and rejects unknown codes" do
    incident = Upright::Incident.new(title: "x", impact: "minor", status: "investigating", starts_at: Time.current)

    incident.service_codes = [ "example_app" ]
    assert incident.save
    assert_equal [ "example_app" ], incident.reload.service_codes

    incident.service_codes = [ "does_not_exist" ]
    assert_not incident.valid?
  end

  test "active, upcoming, and past scopes key off timestamps and resolved_at" do
    active   = Upright::Incident.create!(title: "a", impact: "minor", status: "investigating", starts_at: 1.hour.ago)
    resolved = Upright::Incident.create!(title: "r", impact: "minor", status: "resolved", starts_at: 2.hours.ago, resolved_at: 1.hour.ago)

    assert_includes Upright::Incident.active, active
    assert_not_includes Upright::Incident.active, resolved
    assert_includes Upright::Incident.past, resolved
  end

  test "reactive scope excludes the maintenance subclass" do
    incident = Upright::Incident.create!(title: "i", impact: "minor", status: "investigating", starts_at: 1.hour.ago)
    maintenance = Upright::Maintenance.create!(title: "m", status: "in_progress", starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

    assert_includes Upright::Incident.reactive, incident
    assert_not_includes Upright::Incident.reactive, maintenance
  end

  test "for_service filters by affected service code" do
    incident = Upright::Incident.create!(title: "i", impact: "minor", status: "investigating",
      starts_at: 1.hour.ago, service_codes: [ "example_app" ])

    assert_includes Upright::Incident.for_service("example_app"), incident
    assert_not_includes Upright::Incident.for_service("internal_tools"), incident
  end
end
