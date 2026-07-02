require "test_helper"

class Upright::ServiceMaintenanceTest < ActiveSupport::TestCase
  test "maintenance_active? is true while a covering window is in progress" do
    Upright::Maintenance.create!(title: "m", status: "in_progress",
      starts_at: 1.hour.ago, ends_at: 1.hour.from_now, service_codes: [ "example_app" ])

    assert Upright::Service.find_by(code: "example_app").maintenance_active?
    assert_not Upright::Service.find_by(code: "internal_tools").maintenance_active?
  end

  test "degraded suppresses a service that is under maintenance" do
    Upright::Maintenance.create!(title: "m", status: "in_progress",
      starts_at: 1.hour.ago, ends_at: 1.hour.from_now, service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)
    Upright::Service.any_instance.stubs(:current_outage_started_at).returns(nil)

    codes = Upright::Service.degraded.map { |item| item[:service].code }

    assert_not_includes codes, "example_app"
    assert_includes codes, "internal_tools"
  end

  test "overall_status reads maintenance when the only down services are under maintenance" do
    Upright::Service.all.each do |service|
      Upright::Maintenance.create!(title: "m #{service.code}", status: "in_progress",
        starts_at: 1.hour.ago, ends_at: 1.hour.from_now, service_codes: [ service.code ])
    end
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)

    assert_equal :maintenance, Upright::Service.overall_status
  end

  test "a real outage on another service still outranks maintenance" do
    Upright::Maintenance.create!(title: "m", status: "in_progress",
      starts_at: 1.hour.ago, ends_at: 1.hour.from_now, service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)

    assert_equal :major_outage, Upright::Service.overall_status
  end

  test "an active incident raises the overall status even when probes are green" do
    Upright::Incident.create!(title: "x", impact: "critical", starts_at: 1.hour.ago, service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:operational)

    assert_equal :major_outage, Upright::Service.overall_status
  end

  test "overall status takes the worse of probe status and incident impact" do
    Upright::Incident.create!(title: "x", impact: "minor", starts_at: 1.hour.ago, service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)

    assert_equal :major_outage, Upright::Service.overall_status
  end
end
