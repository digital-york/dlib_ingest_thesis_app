var ready = function() {

    $('#btnColl').on('click', function (e, data) {
        $("#divColl").toggle();
        $("#btnColl").remove();
        // pull in the tree
        $.ajax({
            url: "/ingests/collection",
            cache: true, //???
            success: function(html){
                $("#divColl").append(html);
                $('#html1')
                    // listen for event
                    .on('changed.jstree', function (e, data) {
                        var i, j, r = [], id = [];
                        // only take one value?
                        for(i = 0, j = data.selected.length; i < j; i++) {
                            r.push(data.instance.get_node(data.selected[i]).text);
                            id.push(data.instance.get_node(data.selected[i]).id);
                        }
                        // populate the input box with selected collection pid and label with the collection title
                        $('.remove').remove()
                        $('.remove').remove()
                        $( '<label class="remove">You selected: ' + r.join(', ') + '</label><br class="remove" /><label class="remove">PID:&nbsp;</label>' ).insertBefore('#ingest_parent')
                        $('#ingest_parent').val(id.join(', '));
                        $('#ingest_parent').prop("readonly", true);

                    })
                    // create the instance
                    .jstree();
            }
        });
    });

    $('#ingest_content').change(function() {
        if ($(this).val().startsWith("Images")) {
            $('.field-toggle-off').toggle()
        }
        $('.3').toggle()
        $('#ingest_content').unbind()
    });

    $('#ingest_rights').change(function() {
        $('.4').toggle()
        $('#ingest_rights').unbind()
    });

    $('#ingest_filestore').change(function() {
        $('.remove').remove()
        $('<label class="remove">' + $(this).val() + '/&nbsp;</label>' ).insertBefore('#ingest_folder')
        $('.1').toggle()
        $('#ingest_filestore').unbind()
    });

    $('#ingest_file').change(function() {
        $('.2').toggle()
        $('#ingest_file').unbind()
    });
}

$(document).ready(ready);
$(document).on('page:load', ready);