require "test_helper"

class Upright::MaintenanceTest < ActiveSupport::TestCase
  test "is an Incident via STI and forces the maintenance impact" do
    maintenance = Upright::Maintenance.create!(title: "Upgrade", status: "scheduled",
      starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)

    assert maintenance.maintenance?
    assert_kind_of Upright::Incident, maintenance
    assert_equal "maintenance", maintenance.impact
    assert_equal "Upright::Maintenance", maintenance.type
  end

  test "requires an end that is after the start" do
    maintenance = Upright::Maintenance.new(title: "x", status: "scheduled",
      starts_at: 2.hours.from_now, ends_at: 1.hour.from_now)

    assert_not maintenance.valid?
    assert maintenance.errors[:ends_at].any?
  end

  test "rejects a reactive-incident status" do
    maintenance = Upright::Maintenance.new(title: "x", status: "investigating",
      starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)

    assert_not maintenance.valid?
  end

  test "auto_advance starts an in-window maintenance without completing it" do
    maintenance = Upright::Maintenance.create!(title: "x", status: "scheduled",
      starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

    maintenance.auto_advance!

    assert_equal "in_progress", maintenance.reload.status
    assert_nil maintenance.resolved_at
  end

  test "auto_advance catches up a fully-elapsed window through to completed" do
    maintenance = Upright::Maintenance.create!(title: "x", status: "scheduled",
      starts_at: 2.hours.ago, ends_at: 1.hour.ago)

    maintenance.auto_advance!

    assert_equal "completed", maintenance.reload.status
    assert_not_nil maintenance.resolved_at
  end

  test "upcoming and active scopes" do
    upcoming = Upright::Maintenance.create!(title: "u", status: "scheduled", starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)
    active   = Upright::Maintenance.create!(title: "a", status: "in_progress", starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

    assert_includes Upright::Maintenance.upcoming, upcoming
    assert_not_includes Upright::Maintenance.upcoming, active
    assert_includes Upright::Maintenance.active, active
    assert_not_includes Upright::Maintenance.active, upcoming
  end
end
