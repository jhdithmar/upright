require "test_helper"

class Upright::Public::IncidentsControllerTest < ActionDispatch::IntegrationTest
  setup { on_subdomain Upright.configuration.public_status_subdomain }

  test "incident detail never shows the author" do
    incident = Upright::Incident.create!(
      title: "Public incident", impact: "minor", starts_at: Time.current, created_by: "Ada Lovelace"
    )

    get upright.public_incident_path(incident)

    assert_response :success
    assert_no_match "Ada Lovelace", response.body
  end
end
