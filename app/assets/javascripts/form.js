// javascript code for submission form
$(document).ready(function() {
    var multiple_photos_form = $('#new_thesis');
    var submit_btn           = $('#btnSubmit');
    var wrapper      = multiple_photos_form.find('.progress-wrapper');
    var bitrate      = wrapper.find('.bitrate');
    var progress_bar = wrapper.find('.progress-bar');

    $(document).bind('dragover', function (e) {
        var dropZone = $('#dropzone'),
            timeout = window.dropZoneTimeout;

        if (!timeout) {
            dropZone.addClass('in');
        } else {
            clearTimeout(timeout);
        }

        var found = false,
            node = e.target;
        do {
            if (node === dropZone[0]) {
                found = true;
                break;
            }
            node = node.parentNode;
        } while (node != null);

        if (found) {
            dropZone.addClass('hover');
        } else {
            dropZone.removeClass('hover');
        }

        window.dropZoneTimeout = setTimeout(function () {
            window.dropZoneTimeout = null;
            dropZone.removeClass('in hover');
        }, 100);
    });

    multiple_photos_form.on('fileuploadstart', function() {
        wrapper.show();
    });

    multiple_photos_form.on('fileuploaddone', function() {
        wrapper.hide();
        progress_bar.width(0);
    });

    //multiple_photos_form.on('fileuploadsubmit', function (e, data) {
    //    data.formData = {'photo[author]': $('#photo_author').val()};
    //});
    multiple_photos_form.on('fileuploadsubmit', function (e, data) {
        data.formData = {
            //'thesis[name]':           $('#thesis_name').val(),
            //'thesis[title]':          $('#thesis_title').val(),
            //'thesis[date]':           $('#thesis_date').val(),
            //'thesis[abstract]':       $('#thesis_abstract').val(),
            //'thesis[degreetype]':     $('#thesis_degreetype').val(),
            //'thesis[supervisorfiledo]':     $('#thesis_supervisor').val(),
            //'thesis[department]':     $('#thesis_department').val(),
            //'thesis[subjectkeyword]': $('#thesis_subjectkeyword').val(),
            //'thesis[rightsholder]':   $('#thesis_rightsholder').val(),
            //'thesis[licence]':        $('#thesis_licence').val(),
            //
            //'thesis[uploaded_files]': $('#thesis_uploaded_files').val()
            'submission_type':   'upload',
            'uploaded_files':   $('#thesis_uploaded_files').val()
        };
    });

    multiple_photos_form.on('fileuploadprogressall', function (e, data) {
        bitrate.text((data.bitrate / 1024).toFixed(2) + 'Kb/s');
        var progress = parseInt(data.loaded / data.total * 100, 10);
        progress_bar.css('width', progress + '%').text(progress + '%');
    });

    multiple_photos_form.fileupload({
        dataType: 'script',
        dropZone: $('#dropzone'),
        add: function (e, data) {
            types = /(\.|\/)(pdf|doc|docx|jpe?g|png|zip)$/i;
            file = data.files[0];
            if (types.test(file.type) || types.test(file.name)) {
                data.submit();
            }
            else { alert(file.name + ": only PDF, DOC, DOCX, JPEG, PNG, OR ZIP file allowed."); }
        }
    });

    submit_btn.on('click', function (e, data) {
        // alert('Submitting...');
        //data.formData = {
        //    'thesis[name]':             $('#thesis_name').val(),
        //    'thesis[title]':            $('#thesis_title').val(),
        //    'thesis[date]':             $('#thesis_date').val(),
        //    'thesis[abstract]':         $('#thesis_abstract').val(),
        //    'thesis[degreetype]':       $('#thesis_degreetype').val(),
        //    'thesis[supervisor]': $('#thesis_supervisor').val(),
        //    'thesis[department]':       $('#thesis_department').val(),
        //    'thesis[subjectkeyword]':   $('#thesis_subjectkeyword').val(),
        //    'thesis[rightsholder]':     $('#thesis_rightsholder').val(),
        //    'thesis[licence]':          $('#thesis_licence').val(),
        //
        //    'submission_type':        'submit'
        //};

        $.ajax({
                url: "/theses",
                type: "POST",
                data: {thesis: {
                                 name:            $('#thesis_name').val(),
                                 title:            $('#thesis_title').val(),
                                 date:            $('#thesis_date').val(),
                                 abstract:        $('#thesis_abstract').val(),
                                 degreetype:      $('#thesis_degreetype').val(),
                                 supervisor:      $('#thesis_supervisor').val(),
                                 department:      $('#thesis_department').val(),
                                 subjectkeyword:  $('#thesis_subjectkeyword').val(),
                                 rightsholder:    $('#thesis_rightsholder').val(),
                                 licence:         $('#thesis_licence').val()
                               },
                        submission_type: 'submit'
                      },
                success: function(resp){

                }
        });
    });

});