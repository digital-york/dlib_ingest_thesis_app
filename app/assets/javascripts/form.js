// javascript code for submission form
$(document).ready(function() {
    var multiple_photos_form   = $('#new_thesis');
    var submit_btn             = $('#btnSubmit');
    var add_supervisor_btn     = $('#add_supervisor');
    var add_department_btn     = $('#add_department');
    var add_subjectkeyword_btn = $('#add_subjectkeyword');

    var txt_thesis_title       = $('#thesis_title');

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
        if(txt_thesis_title.val()=="") {
            alert('Please enter dissertation title before submit!');
            return;
        }

        licence = "";
        var radioBtn1 = $('#licence_self:checked');
        var radioBtn2 = $('#licence_other:checked');

        if(typeof radioBtn1 != "undefined" && (typeof radioBtn1.val() != "undefined" )) {
          licence = radioBtn1.val();
        }else if(typeof radioBtn2 != "undefined" && (typeof radioBtn2.val() != "undefined" )) {
          licence = radioBtn2.val();
        }

        mfile = $('input[name=defaultFile]:checked').val();
        if (typeof mfile === "undefined") {
            alert('Please upload files / choose your main Theses file (PDF only) before submit!');
            return;
        }

        var more_supervisors = [];
        $("input[name='more_supervisors']").each(function() {
            more_supervisors.push($(this).val());
        });

        var more_subject_keywords = [];
        $("input[name='more_subject_keywords']").each(function() {
            more_subject_keywords.push($(this).val());
        });

        var more_departments = [];
        $("select[name='more_departments']").each(function() {
            more_departments.push($(this).val());
        });

        $("div#spinner").fadeIn("fast");
        spinnerVisible = true;

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
                                 licence:         licence
                               },
                        submission_type:       'submit',
                        more_supervisors:      more_supervisors,
                        more_subject_keywords: more_subject_keywords,
                        more_departments:      more_departments,
                        mainfile: mfile,
                      },
                success: function(resp){
                    window.location.href = "/submit_success";
                }
        });

        //alert('submit done.');
    });

    add_supervisor_btn.on('click', function (e, data) {
        var container = $("#divSupervisor");
        var delImgSrc  = $(".delete_img_template").attr('src');

        var newDiv1  = $(container).parent().append("<div class=\"control-label col-xs-2 form-fields\"></div>");
        var $newDiv2  = $("<div class=\"col-xs-10 form-fields\"></div>");
        $(container).parent().append($newDiv2);
        var $inputElt = $("<input size=\"80\" placeholder=\"Surname, Forename\" type=\"text\" name=\"more_supervisors\">");
        $inputElt.appendTo($newDiv2).after(" ");

        $delImgElt = $("<img alt=\"Delete supervisor\" title=\"Delete supervisor\" name=\"delete_supervisor\" src=\""+delImgSrc+"\" width=\"16\" height=\"16\" class=\"add_image\">");
        $delImgElt.appendTo($newDiv2);

        $delImgElt.on('click', function (e, data) {
            var $parent = $(this).parent();
            $parent.prev().fadeOut();
            $parent.fadeOut();
        });
    });

    add_department_btn.on('click', function (e, data) {
        var container = $("#divDepartment");
        var delImgSrc = $(".delete_img_template").attr('src');

        var newDiv1   = $(container).parent().append("<div class=\"control-label col-xs-2 form-fields\"></div>");
        var $newDiv2  = $("<div class=\"col-xs-10 form-fields\"></div>");
        $(container).parent().append($newDiv2);

        var $deptElt   = $("#thesis_department").clone();
        $deptElt.removeAttr('id');
        $deptElt.attr('name', 'more_departments');

        $deptElt.appendTo($newDiv2).after(" ");

        $delImgElt = $(" <img alt=\"Delete department\" title=\"Delete department\" name=\"delete_department\" src=\""+delImgSrc+"\" width=\"16\" height=\"16\" class=\"add_image\">");
        $delImgElt.appendTo($newDiv2);

        $delImgElt.on('click', function (e, data) {
            var $parent = $(this).parent();
            $parent.prev().fadeOut();
            $parent.fadeOut();
        });
    });

    add_subjectkeyword_btn.on('click', function (e, data) {
        var container = $("#divSubjectKeyword");
        var delImgSrc  = $(".delete_img_template").attr('src');

        var newDiv1  = $(container).parent().append("<div class=\"control-label col-xs-2 form-fields\"></div>");
        var $newDiv2  = $("<div class=\"col-xs-10 form-fields\"></div>");
        $(container).parent().append($newDiv2);
        var $inputElt = $("<input size=\"80\" placeholder=\"Subject keyword\" type=\"text\" name=\"more_subject_keywords\">");
        $inputElt.appendTo($newDiv2).after(" ");

        $delImgElt = $(" <img alt=\"Delete subject keyword\" title=\"Delete subject keyword\" name=\"delete_subject_keyword\" src=\""+delImgSrc+"\" width=\"16\" height=\"16\" class=\"add_image\">");
        $delImgElt.appendTo($newDiv2);

        $delImgElt.on('click', function (e, data) {
            var $parent = $(this).parent();
            //$parent.prev().remove();
            //$parent.remove();
            $parent.prev().fadeOut();
            $parent.fadeOut();
        });
    });

    txt_thesis_title.on('change keyup blur paste mouseup', function (e, data) {
        if($(this).val()!="") {
            $(this).css({'backgroundColor' : '#FFFFFF'});
        }else{
            $(this).css({'backgroundColor' : '#FFFF00'});
        }
    });
});