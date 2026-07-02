class Upright::IncidentsController < Upright::ApplicationController
  before_action :set_incident, only: %i[ edit update destroy ]

  def index
    @current = Upright::Incident.active.order(starts_at: :desc)
    @upcoming = Upright::Maintenance.upcoming.order(:starts_at)
    @past = Upright::Incident.past.limit(50)
  end

  def new
    @incident = build_class.new(starts_at: Time.current)
  end

  def create
    @incident = build_class.new(incident_params.except(:body))
    @incident.status = @incident.maintenance? ? "scheduled" : "investigating"

    if @incident.save
      @incident.updates.create!(status: @incident.status, body: initial_body)
      redirect_to incidents_path, notice: "#{@incident.maintenance? ? "Maintenance" : "Incident"} created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @incident.update(incident_params.except(:body))
      redirect_to incidents_path, notice: "Saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @incident.destroy
    redirect_to incidents_path, notice: "Deleted."
  end

  private
    def set_incident
      @incident = Upright::Incident.find(params[:id])
    end

    def build_class
      maintenance = ActiveModel::Type::Boolean.new.cast(params[:maintenance])
      maintenance ? Upright::Maintenance : Upright::Incident
    end

    def incident_params
      params.require(:incident).permit(:title, :impact, :starts_at, :ends_at, :body, service_codes: [])
    end

    def initial_body
      incident_params[:body].presence ||
        (@incident.maintenance? ? "Maintenance scheduled." : "We are investigating.")
    end
end
