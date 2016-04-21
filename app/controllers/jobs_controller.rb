class JobsController < ApplicationController
  before_action :set_job, only: [:show, :submit, :edit, :update, :results,
                                 :embed, :stdout, :destroy]
  before_action :get_displayed_mode, only: [:results, :embed]
  before_action :get_last_page, only: [:destroy]

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
    if @job.destroyable?
      @job.delete_staging_directories
      @job.destroy
      flash[:success] = "Job deleted."
    else
      flash[:danger] = "Job cannot be deleted at this time."
    end

    if request.referrer.include? index_path
      if @last_page > Job.page.num_pages
        redirect_to index_path(page: Job.page.num_pages)
      else
        redirect_to request.referrer
      end
    else
      redirect_to index_url
    end
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

    # Get the last visited paginated index page when destroying job.  This
    # provides input to handle a redirect to the previous pagination if the
    # job being deleted is the last one on the page.
    def get_last_page
      query = URI.parse(request.referrer).query
      @last_page = query.nil? ? 0 : CGI.parse(query)["page"].first.to_i
    end
end
