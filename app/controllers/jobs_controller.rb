class JobsController < ApplicationController
  before_action :set_job, only: [:show]

  def index
    if Job.any?
      @jobs = Job.order(:created_at).page params[:page]
    else
      redirect_to request.referrer || root_url
    end
  end

  def new
    @job = Job.new
  end

  def show
  end

  def edit
  end

  def create
    @job =Job.new(job_params)
    if @job.save
      flash[:success] = "Successfully created #{@job.name}."
      redirect_to @job
    else
      render 'new'
    end
  end

  def update
  end

  def destroy
  end

  def submit
  end

  def kill
  end

  def copy
  end

  def clean
  end

  def download
  end

  def files
  end

  def update_material
    @material_id = params[:material_id].to_i
  end

  private

    def job_params
      params.require(:job).permit(:name, :nodes, :processors, :meshsize,
                                  :method, :modes, :freqb, :freqe,
                                  :geom_units, :geom_file, :material_id)
    end

    def set_job
      @job = Job.find(params[:id])
    end

    def submit_job
      @job.submit if @job.ready?
      if @job.submitted?
        flash[:success] = "Simulation for #{@job.name} successfully submitted!"
      else
        flash[:danger] = "Submission for #{@job.name} failed."
      end

      redirect_to root_url
    end
end
