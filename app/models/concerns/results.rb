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

  # Gets the Paraview generated WebGL file - returns empty string if
  # nonexistant.
  def graphics_file(mode=1)
    results_dir = Pathname.new(jobdir)
    results_file = lambda { |f| f.exist? ? f : "" }
    results_file.call(results_dir + "#{prefix}_mode#{mode}.html").to_s
  end

  # def debug_info
  #   debug_file = Pathname.new(job.jobdir) + "#{prefix}.debug"
  #   debug_file.exist? ? File.open(debug_file, 'r').read : nil
  # end
end
