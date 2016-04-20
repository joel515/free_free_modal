module Results
  extend ActiveSupport::Concern

  def modal_fem
    fem_result(:modes)
  end

  # Read the result extracted from the parser submitted with the simulation.
  def fem_result(type)
    jobpath = Pathname.new(jobdir)
    result_file = jobpath + "#{prefix}.#{type.to_s}"

    modes = []
    if result_file.exist?
      mode = 0
      File.foreach(result_file) do |line|
        mode += 1
        arry = line.split(',') if line.include? "Mode"
        modes << Hash[mode: mode, freq: arry[2]]
      end
      modes
    else
      nil
    end
  end

  def mode_count
    jobpath = Pathname.new(jobdir)
    result_file = jobpath + "#{prefix}.modes"

    count = 0
    if result_file.exist?
      File.foreach(result_file) do |line|
        count += 1 if line.include? "Mode"
      end
    end
    count
  end

  # Gets the Paraview generated WebGL file - returns empty string if
  # nonexistant.
  def graphics_file(mode=1)
    results_dir = Pathname.new(jobdir)
    results_file = lambda { |f| f.exist? ? f : "" }
    results_file.call(results_dir + "#{prefix}_mode#{mode}.html").to_s
  end

  def next_mode(current_mode)
    current_mode == mode_count ? 1 : current_mode + 1
  end

  def previous_mode(current_mode)
    current_mode == 1 ? mode_count : current_mode - 1
  end

  def modal_frequency(mode)
    jobpath = Pathname.new(jobdir)
    result_file = jobpath + "#{prefix}.modes"

    if result_file.exist?
      File.foreach(result_file) do |line|
        if line.include? "Mode"
          split_line = line.split(',')
          return "%.2f " % split_line[2] if (split_line[1].to_i - 6) == mode.to_i
        end
      end
    end

    "---"
  end

  # def debug_info
  #   debug_file = Pathname.new(job.jobdir) + "#{prefix}.debug"
  #   debug_file.exist? ? File.open(debug_file, 'r').read : nil
  # end
end
