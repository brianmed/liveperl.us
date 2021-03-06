$(document).ready(function() {
    var $code = $('#code');
    var $description = $('.description');
    var $masthead = $('.masthead');
    var $output = $('#output');
    var editor = CodeMirror($code[0], { lineNumbers: true });
    var $reloader = $();
    var initialized, timeout;

    // resize the editor and output blocks when the screen change size
    $(window).resize(function() {
        var height = $(window).height() - $masthead.height() - $description.height() - 30;
        editor.setSize($code.width(), height);
        $output.height(height);
    }).resize();

    // post the form to a hidden iframe to re-use the form functionality
    $('#joy').submit(function(e) {
        e.preventDefault();
        $('form [name="code"]').val(editor.getValue());
        $.post(this.action, $(this).serialize(), function(output) { 
          if(initialized) {
                $("#output").html("<pre>" + output.output + "</pre>");

                $('#save').hide()
          }
          else {
                $.getJSON("/tutorial/run", function(output) { 
                    $('#save').hide()

                    $("#output").html("<pre>" + output.output + "</pre>")

                    initialized = true;
                });
          }
        });
    });

    $("#run").click(function() {
        $.getJSON("/tutorial/run", function(output) { $("#output").html("<pre>" + output.output + "</pre>")});
    });

    // autosave the content of the editor
    editor.on("update", function() {
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            $('#save').show();
            $('#joy').submit();
        }, 1000);
    });

    editor.setValue($('form [name="code"]').val());

});
