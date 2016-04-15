class JobsController < ApplicationController
  before_action :set_job, only: [:show, :submit, :edit, :update, :results, :embed]
  before_action :get_displayed_mode, only: [:results, :embed]

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

  def results
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
    if @job.editable?
      if @job.update_attributes(job_params)
        @job.delete_staging_directories
        @job.ready
        flash[:success] = "Successully updated #{@job.name}."
        redirect_to @job
      else
        render 'edit'
      end
    else
      flash[:danger] = "#{@job.name} is not editable at this time."
      render 'edit'
    end
  end

  def destroy
  end

  def submit
    submit_job
  end

  def kill
  end

  def copy
  end

  def clean
  end

  def download
  end

  def stdout
    render layout: false
  end

  def files
  end

  def embed
    render layout: false, file: @job.graphics_file(@mode)
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

    def get_displayed_mode
      @mode = params[:mode].nil? ? 1 : params[:mode]
    end

    def submit_job
      @job.submit if @job.ready?
      if @job.submitted?
        flash[:success] = "Simulation for #{@job.name} successfully submitted!"
      else
        flash[:danger] = "Submission for #{@job.name} failed."
      end

      if request.referrer.include? index_path
        redirect_to request.referrer
      else
        redirect_to @job
      end
    end
end
