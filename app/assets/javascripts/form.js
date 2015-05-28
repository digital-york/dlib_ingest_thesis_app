// javascript code for submission form
$(document).ready(function() {
    var multiple_photos_form = $('#new_thesis');
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

    multiple_photos_form.on('fileuploadsubmit', function (e, data) {
        data.formData = {'photo[author]': $('#photo_author').val()};
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
            types = /(\.|\/)(pdf|doc|docx|gif|jpe?g|png|bmp)$/i;
            file = data.files[0];
            if (types.test(file.type) || types.test(file.name)) {
                data.submit();
            }
            else { alert(file.name + ": only PDF, DOC, DOCX, GIF, JPEG, BMP or PNG file allowed."); }
        }
    });

});