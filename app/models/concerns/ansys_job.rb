module AnsysJob
  extend ActiveSupport::Concern

  ANSYS_EXE = "/gpfs/apps/ansys/v162/ansys/bin/ansys162"

  # Capture the job stats and return the data as a hash.
  def job_stats
    jobpath = Pathname.new(jobdir)
    std_out = jobpath + "#{prefix}.o#{pid.split('.')[0]}"

    nodes, elements, cputime, walltime = nil
    if std_out.exist?
      File.foreach(std_out) do |line|
        nodes    = line.split[4] if line.include? "MAXIMUM NODE NUMBER"
        elements = line.split[4] if line.include? "MAXIMUM ELEMENT NUMBER"
        cputime  = "#{line.split[5]} s" if line.include? "CP Time"
        walltime = "#{line.split[5]} s" if line.include? "Elapsed Time"
      end
    end
    Hash["Number of Nodes" => nodes,
         "Number of Elements" => elements,
         "CPU Time" => cputime,
         "Wall Time" => walltime]
  end

  def result_path
    Pathname.new(jobdir)
  end

  private

    # Generate the submit script and submit the job using qsub.
    def submit_job
      input_deck = generate_input_deck
      # results_script = generate_results_script

      if !input_deck.nil? && !results_script.nil?
        submit_script = generate_submit_script(input_deck: input_deck)
        # submit_script = generate_submit_script(input_deck:     input_deck,
        #                                        results_script: results_script)

        if !submit_script.nil?
          Dir.chdir(jobdir) {
            cmd =  "qsub #{prefix}.sh"
            self.pid = `#{cmd}`
          }
        end
      end

      # If successful, set the status to "Submitted" and save to database.
      unless pid.nil? || pid.empty?
        self.pid = pid.strip
        # self.submitted_at = Time.new.ctime
        set_status! :b
      else
        self.pid = nil
        # self.submitted_at = '---'
        set_status! :f
      end
    end

    # Write the input deck for solving in Ansys.
    def generate_input_deck
      input_deck = Pathname.new(jobdir) + "#{prefix}.dat"

      e = convert(beam.material, :modulus)
      rho = convert(beam.material, :density)
      geom_file_base = nil
      geom_file_ext = nil

      File.open(input_deck, 'w') do |f|
        f.puts "/batch"
        f.puts "*get,_wallstrt,active,,time,wall"

        f.puts "/aux15"
        f.puts "ioptn,iges,smooth"
        f.puts "ioptn,merge,yes"
        f.puts "ioptn,solid,yes"
        f.puts "ioptn,small,yes"
        f.puts "ioptn,gtoler,defa"
        f.puts "igesin,#{geom_file_base},#{geom_file_ext}"
        f.puts "finish"

        f.puts "/prep7"
        f.puts "et,1,solid187"
        f.puts "r,1"
        f.puts "mp,ex,1,#{e},"
        f.puts "mp,nuxy,1,#{poisson}"
        f.puts "mp,dens,1,#{rho}"
        f.puts "allsel,all"
        f.puts "vatt,1,1,1"
        f.puts "smrtsize,#{meshsize}"
        f.puts "mshkey,0"
        f.puts "mshape,1,3d"
        f.puts "vmesh,all"
        f.puts "finish"

        f.puts "get,_wallbsol,active,,time,wall"

        f.puts "/solu"
        f.puts "antype,2"
        if nummodes.nil?
          f.puts "modopt,#{method},,#{freqb},#{freqe}"
        else
          f.puts "modopt,#{method},#{modes+6}"
        end
        f.puts "outres,erase"
        f.puts "outres,all,none"
        f.puts "outres,nsol,all"
        f.puts "mxpand"
        f.puts "solve"
        f.puts "finish"

        f.puts "*get,_numnode,node,0,count"
        f.puts "*get,_numelem,elem,0,count"
        f.puts "*get,_wallasol,active,,time,wall"

        f.puts "/post1"
        f.puts "*dim,_direction,char,6,1"
        f.puts "_direction(1) = 'X'"
        f.puts "_direction(2) = 'Y'"
        f.puts "_direction(3) = 'Z'"
        f.puts "_direction(4) = 'ROTX'"
        f.puts "_direction(5) = 'ROTY'"
        f.puts "_direction(6) = 'ROTZ'"
        f.puts "*get,_nummodes,active,0,set,nset"
        f.puts "*cfopen,#{prefix},modes,,"
        f.puts "*do,i_mode,7,_nummodes"
        f.puts "  *get,mode_%i_mode%,mode,%i_mode%,freq"
        f.puts "  *vwrite,'Mode',%i_mode%,mode_%i_mode%"
        f.puts "  %C,%I,%G"

        # If boundary conditions are ever implemented, modal participation and
        # effective mass would be good to know.
        # f.puts "  *do,j_component,1,6"
        # f.puts "    *get,PFACT_%i_mode%_%j_component%,MODE,%i_mode%,PFACT,,DIREC,_direction(%j_component%)"
        # f.puts "    *vwrite,'PFACT',%j_component%,PFACT_%i_mode%_%j_component%"
        # f.puts "    %C,%I,%G"
        # f.puts "  *enddo"
        # f.puts "  *do,j_component,1,6"
        # f.puts "    *get,MEFF_%i_mode%_%j_component%,MODE,%i_mode%,MODM,,DIREC,_direction(%j_component%)"
        # f.puts "    *vwrite,'MEFF',%j_component%,MEFF_%i_mode%_%j_component%"
        # f.puts "    %C,%I,%G"
        # f.puts "  *enddo"

        f.puts "*enddo"
        f.puts "*cfclos"
        f.puts "finish"

        f.puts "get,_walldone,active,,time,wall"
        f.puts "_preptime=(_wallbsol-_wallstrt)*3600"
        f.puts "_solvtime=(_wallasol-_wallbsol)*3600"
        f.puts "_posttime=(_walldone-_wallasol)*3600"
        f.puts "_totaltim=(_walldone-_wallstrt)*3600"
        f.puts "/eof"
      end

      input_deck.exist? ? input_deck : nil
    end

        # Write the Bash script used to submit the job to the cluster.  The job
    # first generates the geometry and mesh using GMSH, converts the mesh to
    # Elmer format using ElmerGrid, solves using ElmerSolver, then creates
    # 3D visualization plots of the results using Paraview (batch).
    def generate_submit_script(args)
      jobpath = Pathname.new(jobdir)
      input_deck = Pathname.new(args[:input_deck]).basename
      # results_script = Pathname.new(args[:results_script]).basename
      submit_script = jobpath + "#{prefix}.sh"
      shell_cmd = `which bash`.strip
      # ruby_cmd = `which ruby`.strip
      # current_directory = `pwd`.strip
      # lib_directory = Pathname.new(current_directory) + "lib"
      # csv2vtu_script = lib_directory + "csv2vtu.rb"
      File.open(submit_script, 'w') do |f|
        f.puts "#!#{shell_cmd}"

        f.puts "#PBS -S #{shell_cmd}"
        f.puts "#PBS -N #{prefix}"
        f.puts "#PBS -l nodes=#{machines}:ppn=#{cores}"
        f.puts "#PBS -j oe"
        f.puts "module load openmpi/gcc/64/1.10.1"
        f.puts "machines=`uniq -c ${PBS_NODEFILE} | " \
          "awk '{print $2 \":\" $1}' | paste -s -d ':'`"
        f.puts "cd ${PBS_O_WORKDIR}"
        f.puts "#{ANSYS_EXE} -b -dis -machines $machines -i #{input_deck}"

        # f.puts "#{ruby_cmd} #{csv2vtu_script} \"#{jobpath}\" \"#{prefix}\" " \
        #   "\"#{displ_scale}\""

        # f.puts "#{MPI_EXE} -np #{cores * machines} " * use_mpi?.to_i +
        #   "#{PARAVIEW_EXE} #{results_script}"
      end

      submit_script.exist? ? submit_script : nil
    end

    def output_ok?(std_out)
      errors = nil
      File.foreach(std_out) do |line|
        errors = line.split[5].to_i if line.include? \
          "NUMBER OF ERROR   MESSAGES ENCOUNTERED="
      end

      !errors.nil? && errors == 0
    end
end
