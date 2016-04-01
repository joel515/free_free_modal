ready = ->

  $("#job_material_id").change ->
    $.ajax
      url: "/jobs/update_material"
      data:
        config: $("#job_material_id option:selected").val()
      dataType: "script"

  $("#job_geom_file").change ->
    $("#file-button").text(" " + $("#job_geom_file").val().split('\\').reverse()[0])
    $("#file-button").prepend($('<span></span>').addClass('glyphicon glyphicon-ok'))
    $("#file-button").removeClass("btn btn-ftered btn-md").addClass("btn btn-ftegreen btn-md")

$(document).ready(ready)
$(document).on('page:load', ready)
