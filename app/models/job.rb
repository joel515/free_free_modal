class Job < ActiveRecord::Base
  belongs_to :material
  after_create :create_staging_directories!
  mount_uploader :geom_file, GeometryUploader
  before_destroy :delete_staging_directories
  default_scope -> { order(created_at: :desc) }
  validates :name,       presence: true, length: { maximum: 15 }
  validates :status,     presence: true
  validates :method,     presence: true
  validates :processors, presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 1,
                                         less_than_or_equal_to: 16 }
  validates :nodes,      presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 1,
                                         less_than_or_equal_to: 32 }
  validates :meshsize,   presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 1,
                                         less_than_or_equal_to: 10 }
  validates_presence_of :geom_file
  validates :geom_units, presence: true
  validates :material,   presence: true
  validates :modes,      presence: true,
                         numericality: { only_integer: true,
                                         greater_than_or_equal_to: 1 }

  include UnitsHelper

  HOME = "/gpfs/home"

  JOB_STATUS = {
    u: "Unsubmitted",
    e: "Exiting",
    h: "Held",
    q: "Queued",
    r: "Running",
    t: "Moving",
    w: "Waiting",
    s: "Suspended",
    c: "Completed",
    f: "Failed",
    b: "Submitted",
    m: "Terminated",
    k: "Unknown"
  }

  validates_inclusion_of :status, in: JOB_STATUS.values

  def configure_concern
    extend AnsysJob
  end

  def prefix
    name.gsub(/\s+/, "").downcase
  end

  # Job status queries.
  def running?
    [JOB_STATUS[:r]].include? status
  end

  def completed?(state = status)
    [JOB_STATUS[:c]].include? state
  end

  def active?
    [JOB_STATUS[:h], JOB_STATUS[:q], JOB_STATUS[:s], JOB_STATUS[:e],
     JOB_STATUS[:t], JOB_STATUS[:w], JOB_STATUS[:b]].include? status
  end

  def failed?
    [JOB_STATUS[:f], JOB_STATUS[:k], JOB_STATUS[:m]].include? status
  end

  def ready?
    [JOB_STATUS[:u]].include? status
  end

  def ready
    self.pid = nil
    set_status! :u
  end

  def submitted?
    [JOB_STATUS[:b]].include? status
  end

  def terminated?
    [JOB_STATUS[:m], JOB_STATUS[:e]].include? status
  end

  def destroyable?
    !active? & !running?
  end

  def cleanable?
    !active? & !running? & !ready?
  end

  def terminatable?
    active? | running?
  end

  def editable?
    !active? & !running?
  end

  # Submit the job.  Use qsub if using PBS scheduler.  Otherwise run the bash
  # script.  If the latter, capture the group id from the process spawned.
  def submit
    configure_concern
    submit_job
  end

  # Check the job's status.  Use qstat if submitted via PBS, otherwise check
  # the child PIDs from the submitted group PID.
  def check_status
    return status if pid.nil?

    pre_status = `#{check_status_command}`
    unless pre_status.nil? || pre_status.empty?
      state = check_process_status(pre_status)
      completed?(state) ? check_completed_status : state
    else
      failed? ? status : check_completed_status
    end
  end

  def set_status(arg)
    if arg.is_a? String
      self.status = JOB_STATUS.has_value?(arg) ? arg : JOB_STATUS[:k]
    elsif arg.is_a? Symbol
      self.status = JOB_STATUS.has_key?(arg) ? JOB_STATUS[arg] : JOB_STATUS[:k]
    else
      self.status = JOB_STATUS[:k]
    end
  end

  def set_status!(arg)
    set_status(arg)
    self.save
  end

  # Kill the job.  If running with scheduler, submit qdel command.  Otherwise,
  # submit a SIGTERM to the process group.
  def kill
    unless pid.nil?
      `qdel #{pid}`
      set_status! :m
    end
  end

  def clean_staging_directories
    unless jobdir.nil?
      jobpath = Pathname.new(jobdir)
      if jobpath.directory?
        jobpath.children.each do |f|
          f.rmtree if f.directory?
          f.delete unless f.eql? Pathname.new(inputfile.path)
        end
      end
    end
  end

  def delete_staging_directories
    unless jobdir.nil?
      jobpath = Pathname.new(jobdir)
      if jobpath.directory?
        jobpath.rmtree
      end
    end
  end

  def stats
    configure_concern
    job_stats
  end

  def stdout
    jobpath = Pathname.new(jobdir)
    jobpath + "#{prefix}.o#{pid.split('.')[0]}"
  end

  # def get_version
  #   eval("#{config.capitalize}Job::VERSIONS[version.to_sym]")
  # end

  def duplicate
    duplicate_job = self.dup
    duplicate_job.jobdir = nil
    # duplicate_job.submitted_at = "---"
    # duplicate_job.inputfile = inputfile
    duplicate_job.ready
    duplicate_job
  end

  def get_unit_system
    case geom_units
    when "mm"
      "mpa"
    when "cm"
      "cgs"
    when "in"
      "usi"
    when "ft"
      "usf"
    else
      "si"
    end
  end

  private

    def create_staging_directories!
      create_staging_directories
      self.save
    end

    def create_staging_directories
      homedir = Pathname.new(HOME) + "#{`whoami`.strip}"
      return nil unless homedir.directory?

      scratchdir = homedir + "Scratch"
      Dir.mkdir(scratchdir) unless scratchdir.directory?

      appdir = scratchdir + "ffm"
      Dir.mkdir(appdir) unless appdir.directory?

      stagedir = appdir + id.to_s
      Dir.mkdir(stagedir) unless stagedir.directory?

      self.jobdir = stagedir.to_s
    end

    def check_process_status(pre_status)
      JOB_STATUS[Nokogiri::XML(pre_status).xpath( \
        '//Data/Job/job_state').children.first.content.downcase.to_sym] \
        || JOB_STATUS[:k]
    end

    def check_status_command
      "qstat #{pid} -x"
    end

    def check_completed_status
      configure_concern
      std_out = stdout

      if std_out.exist?
        if output_ok? std_out
            JOB_STATUS[:c]
        else
          JOB_STATUS[:f]
        end
      else
        JOB_STATUS[:f]
      end
    end
end
