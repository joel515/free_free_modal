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

      if !input_deck.nil? #&& !results_script.nil?
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

      e = convert(material, :modulus, get_unit_system)
      rho = convert(material, :density, get_unit_system)
      geom_file_base = geom_file.file.basename
      geom_file_ext = geom_file.file.extension

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
        f.puts "mp,nuxy,1,#{material.poisson}"
        f.puts "mp,dens,1,#{rho}"

        # Element properties for thin shell elements.
        f.puts "et,2,154"
        f.puts "keyopt,2,2,1"
        f.puts "keyopt,2,4,1"
        f.puts "keyopt,2,11,2"
        f.puts "r,2,"
        f.puts "mp,dens,2,"

        f.puts "allsel,all"
        f.puts "vatt,1,1,1"
        f.puts "smrtsize,#{meshsize}"
        f.puts "mshkey,0"
        f.puts "mshape,1,3d"
        f.puts "vmesh,all"

        # Coat the outside of the mesh with thin shell elements.
        f.puts "asel,s,all"
        f.puts "nsla,s,1"
        f.puts "type,2"
        f.puts "real,2"
        f.puts "mat,2"
        f.puts "local,100,,,,,,,"
        f.puts "csys,0"
        f.puts "esys,100"
        f.puts "esurf,"
        f.puts "allsel,all"

        f.puts "finish"

        f.puts "*get,_wallbsol,active,,time,wall"

        f.puts "/solu"
        f.puts "antype,2"
        f.puts "modopt,#{method},#{modes+6},#{freqb},#{freqe}"
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
        f.puts "*get,mode_%i_mode%,mode,%i_mode%,freq"
        f.puts "*vwrite,'Mode',%i_mode%,mode_%i_mode%"
        f.puts "%C,%I,%G"

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

        # Write nodal coordinates and displacements and element connectivity
        # to CSV file.
        f.puts "nsel,s,ext"
        f.puts "*get,nnummax,node,,num,max"
        f.puts "*get,locxmax,node,,mxloc,x"
        f.puts "*get,locymax,node,,mxloc,y"
        f.puts "*get,loczmax,node,,mxloc,z"
        f.puts "*get,locxmin,node,,mnloc,x"
        f.puts "*get,locymin,node,,mnloc,y"
        f.puts "*get,loczmin,node,,mnloc,z"
        f.puts "*get,ncount,node,0,count"
        f.puts "*del,nmask"
        f.puts "*del,narray"
        f.puts "*dim,nmask,array,nnummax"
        f.puts "*dim,narray,array,nnummax,4"
        f.puts "*vget,nmask(1),node,1,nsel"
        f.puts "*vmask,nmask(1)"
        f.puts "*vget,narray(1,1),node,1,loc,x"
        f.puts "*vmask,nmask(1)"
        f.puts "*vget,narray(1,2),node,1,loc,y"
        f.puts "*vmask,nmask(1)"
        f.puts "*vget,narray(1,3),node,1,loc,z"
        f.puts "*vfill,narray(1,4),ramp,1,1"
        f.puts "esel,s,type,,2"
        f.puts "*get,enummax,elem,,num,max"
        f.puts "*get,ecount,elem,0,count"
        f.puts "*del,emask"
        f.puts "*del,earray"
        f.puts "*dim,emask,array,enummax"
        f.puts "*dim,earray,array,enummax,4"
        f.puts "*vget,emask(1),elem,1,esel"
        f.puts "*vmask,emask(1)"
        f.puts "*vget,earray(1,1),elem,1,node,1"
        f.puts "*vmask,emask(1)"
        f.puts "*vget,earray(1,2),elem,1,node,2"
        f.puts "*vmask,emask(1)"
        f.puts "*vget,earray(1,3),elem,1,node,3"
        f.puts "*cfopen,#{prefix},csv"
        f.puts "*vwrite,ncount,ecount,locxmax,locymax,loczmax,locxmin,locymin,loczmin"
        f.puts "%I,%I,%G,%G,%G,%G,%G,%G"
        f.puts "*do,i_mode,7,_nummodes"
        f.puts "set,,, ,,, ,i_mode"
        f.puts "*del,darray"
        f.puts "*dim,darray,array,nnummax,3"
        f.puts "*vmask,nmask(1)"
        f.puts "*vget,darray(1,1),node,1,u,x"
        f.puts "*vmask,nmask(1)"
        f.puts "*vget,darray(1,2),node,1,u,y"
        f.puts "*vmask,nmask(1)"
        f.puts "*vget,darray(1,3),node,1,u,z"
        f.puts "*vscfun,dmax1,max,darray(1,1)"
        f.puts "*vscfun,dmax2,max,darray(1,2)"
        f.puts "*vscfun,dmax3,max,darray(1,3)"
        f.puts "*vscfun,dmin1,min,darray(1,1)"
        f.puts "*vscfun,dmin2,min,darray(1,2)"
        f.puts "*vscfun,dmin3,min,darray(1,3)"
        f.puts "*get,freq,mode,i_mode,freq"
        f.puts "*vwrite,'MODE',i_mode,freq,dmax1,dmax2,dmax3,dmin1,dmin2,dmin3"
        f.puts "%C,%I,%G,%G,%G,%G,%G,%G,%G"
        f.puts "*vmask,nmask(1)"
        f.puts "*vwrite,narray(1,4),darray(1,1),darray(1,2),darray(1,3)"
        f.puts "%I,%G,%G,%G"
        f.puts "*enddo"
        f.puts "*vwrite,'STARTNODES'"
        f.puts "%C"
        f.puts "*vmask,nmask(1)"
        f.puts "*vwrite,narray(1,4),narray(1,1),narray(1,2),narray(1,3)"
        f.puts "%I,%G,%G,%G"
        f.puts "*vwrite,'STARTELEMENTS'"
        f.puts "%C"
        f.puts "*vmask,emask(1)"
        f.puts "*vwrite,earray(1,1),earray(1,2),earray(1,3)"
        f.puts "%I,%I,%I"
        f.puts "*vwrite,'EOF'"
        f.puts "%C"
        f.puts "*cfclos"
        f.puts "finish"

        f.puts "*get,_walldone,active,,time,wall"
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
      ruby_cmd = `which ruby`.strip
      current_directory = `pwd`.strip
      lib_directory = Pathname.new(current_directory) + "lib"
      csv2vtu_script = lib_directory + "csv2vtu.rb"
      File.open(submit_script, 'w') do |f|
        f.puts "#!#{shell_cmd}"

        f.puts "#PBS -S #{shell_cmd}"
        f.puts "#PBS -N #{prefix}"
        f.puts "#PBS -l nodes=#{nodes}:ppn=#{processors}"
        f.puts "#PBS -j oe"
        f.puts "module load openmpi/gcc/64/1.10.1"
        f.puts "machines=`uniq -c ${PBS_NODEFILE} | " \
          "awk '{print $2 \":\" $1}' | paste -s -d ':'`"
        f.puts "cd ${PBS_O_WORKDIR}"
        f.puts "#{ANSYS_EXE} -b -dis -machines $machines -i #{input_deck}"

        f.puts "#{ruby_cmd} #{csv2vtu_script} \"#{jobpath}\" \"#{prefix}\" " \
          "1 \"#{modes}\""

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
