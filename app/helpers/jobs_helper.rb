module JobsHelper
  def setup_job(job)
    job.material ||= Material.any? ? Material.find(1) : Material.create!
    job
  end

  def status_label(job, **opts)
    label_class = "label-default"

    if job
      status = job.check_status
      job.set_status! status if status != job.status

      if job.completed?
        label_class = "label-success"
      elsif job.failed?
        label_class = "label-danger"
      elsif job.running?
        label_class = "label-primary"
      elsif job.active?
        label_class = "label-info"
      end
    end

    text = opts[:text].nil? ? status : "#{opts[:text]} - #{status}"

    "<span class=\"label #{label_class}\">#{text}</span>".html_safe
  end

  def button(job, type, opts = { text: false, size: 'btn-xs',
    disabled: false })

    if type == :submit
      link_to "<span class='glyphicon glyphicon-flash'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        submit_job_path(job),
        method: :put,
        class: "btn btn-success #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'Submit job to cluster'
    elsif type == :edit
      link_to "<span class='glyphicon glyphicon-pencil'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        edit_job_path(job),
        class: "btn btn-fteblue #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'Edit job'
    elsif type == :delete
      link_to "<span class='glyphicon glyphicon-trash'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        job,
        method: :delete,
        class: "btn btn-ftered #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { confirm: 'Are you sure?', toggle: 'tooltip',
          placement: 'top' },
        title: 'Delete job'
    elsif type == :copy
      link_to "<span class='glyphicon glyphicon-duplicate'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        copy_job_path(job),
        method: :put,
        class: "btn btn-ftegray #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'Copy job'
    elsif type == :clean
      link_to "<span class='glyphicon glyphicon-erase'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        clean_job_path(job),
        method: :put,
        class: "btn btn-fteyellow #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'Clean job directory'
    elsif type == :results
      link_to "<span class='glyphicon glyphicon-stats'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        results_job_path(job),
        class: "btn btn-primary #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'View results'
    elsif type == :refresh
      link_to "<span class='glyphicon glyphicon-refresh'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        request.original_url,
        class: "btn btn-info #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'Refresh page'
    elsif type == :kill
      link_to "<span class='glyphicon glyphicon-remove'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        kill_job_path(job),
        method: :put,
        class: "btn btn-danger #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'Kill job'
    elsif type == :stdout
      link_to "<span class='glyphicon glyphicon-open-file'></span> "\
          "#{type.capitalize if opts[:text]}".html_safe,
        stdout_job_path(job),
        class: "btn btn-ftegreen #{opts[:size]} " \
          "#{'disabled' * opts[:disabled].to_i}".strip,
        data: { toggle: 'tooltip', placement: 'top' },
        title: 'View standard output',
        target: '_blank'
    end
  end

  def button_group(job, opts = { text: false, size: 'btn-xs'} )
    div = "<div class=\"btn-group\">"
    if job.ready?
      div += button(job, :submit, opts)
    else
      if job.active? || job.running?
        div += button(job, :kill,  opts)
        opts[:disabled] = true
      else
        div += button(job, :clean,  opts)
      end
    end

    div += button(job, :edit,   opts)
    div += button(job, :copy,   opts)
    div += button(job, :delete, opts)
    div += "</div>"
    div.html_safe
  end

  def result_table(job, result)
    html = ""
    modes = job.send(result.to_s<<"_fem")
    if modes.nil?
      html<<"<tr><td>N/A</td><td>N/A</td></tr><td></td>"
    else
      modes.each do |mode|
        html<<"<tr><td>#{mode[:mode]}</td>" \
        "<td>#{'%.2f' % mode[:freq]}</td>" \
        "<td>" +
          link_to("<span class='glyphicon glyphicon-sunglasses'>" \
          "</span>".html_safe,
          results_job_path(job, mode: mode[:mode].to_i),
          class: "btn btn-success btn-xs",
          data: { toggle: 'tooltip', placement: 'top' },
          title: 'Plot mode ' + mode[:mode].to_s) +
        "</td></tr>"
      end
    end

    html.html_safe
  end
end
