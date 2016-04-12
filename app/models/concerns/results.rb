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

  # # Gets the Paraview generated WebGL file - returns empty string if
  # # nonexistant.
  # # TODO: Remove reference to job configuration below:
  # def graphics_file(type=:stress)
  #   job.configure_concern
  #   results_dir = job.result_path
  #   results_file = lambda { |f| f.exist? ? f : "" }
  #   if type == :stress
  #     results_file.call(results_dir + "#{prefix}_stress.html").to_s
  #   elsif type == :displ
  #     results_file.call(results_dir + "#{prefix}_displ.html").to_s
  #   else
  #     return ""
  #   end
  # end

  # def debug_info
  #   debug_file = Pathname.new(job.jobdir) + "#{prefix}.debug"
  #   debug_file.exist? ? File.open(debug_file, 'r').read : nil
  # end
end
