require "test_helper"

class Upright::ServiceMaintenanceTest < ActiveSupport::TestCase
  setup { travel_to Time.utc(2026, 6, 15, 12) }

  test "maintenance_active? is true while a covering window is in progress" do
    upright_incidents(:in_progress).update!(service_codes: [ "example_app" ])

    assert Upright::Service.find_by(code: "example_app").maintenance_active?
    assert_not Upright::Service.find_by(code: "internal_tools").maintenance_active?
  end

  test "degraded suppresses a service that is under maintenance" do
    upright_incidents(:in_progress).update!(service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)
    Upright::Service.any_instance.stubs(:current_outage_started_at).returns(nil)

    codes = Upright::Service.degraded.map { |item| item[:service].code }

    assert_not_includes codes, "example_app"
    assert_includes codes, "internal_tools"
  end

  test "overall_status reads maintenance when the only down services are under maintenance" do
    upright_incidents(:in_progress).update!(service_codes: [ "example_app" ])
    upright_incidents(:started_scheduled).update!(service_codes: [ "internal_tools" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)

    assert_equal :maintenance, Upright::Service.overall_status
  end

  test "a real outage on another service still outranks maintenance" do
    upright_incidents(:in_progress).update!(service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)

    assert_equal :major_outage, Upright::Service.overall_status
  end

  test "an active incident raises the overall status even when probes are green" do
    upright_incidents(:reactive_resolved).update!(impact: "critical", status: "investigating",
      starts_at: 1.hour.ago, resolved_at: nil, service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:operational)

    assert_equal :major_outage, Upright::Service.overall_status
  end

  test "overall status takes the worse of probe status and incident impact" do
    upright_incidents(:reactive_resolved).update!(impact: "minor", status: "investigating",
      starts_at: 1.hour.ago, resolved_at: nil, service_codes: [ "example_app" ])
    Upright::Service.any_instance.stubs(:live_status).returns(:major_outage)

    assert_equal :major_outage, Upright::Service.overall_status
  end
end
