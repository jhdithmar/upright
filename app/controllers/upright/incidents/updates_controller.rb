class Upright::Incidents::UpdatesController < Upright::ApplicationController
  def create
    @incident = Upright::Incident.find(params[:incident_id])
    @incident.record_update(status: update_params[:status], body: update_params[:body])
    redirect_to edit_incident_path(@incident), notice: "Update posted."
  rescue ActiveRecord::RecordInvalid
    redirect_to edit_incident_path(@incident), alert: "Couldn't post update — check the status and message."
  end

  private
    def update_params
      params.expect(incident_update: [ :status, :body ])
    end
end
