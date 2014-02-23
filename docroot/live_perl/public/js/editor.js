$(document).ready(function() {
    var $code = $('#code');
    var $description = $('.description');
    var $masthead = $('.masthead');
    var $output = $('#output');
    var editor = CodeMirror($code[0], { lineNumbers: true });
    var $reloader = $();
    var initialized, timeout;

    // reload the output iframe without flickering, by adding a new iframe that loads in the background
    var reload = function() {
        if($reloader.hasClass('hidden')) $reloader.remove(); // abort unfinished iframe

        $reloader = $('<iframe class="hidden"></iframe>');
        $reloader.attr('src', $output.attr('data-url'));
        $reloader.load(function() {
            $output.find('iframe').not('.hidden').remove();
            $output.children().not('iframe').remove();
            $reloader.removeClass('hidden').attr('data-ts', new Date());
            $('form button[type="submit"]').text('Save');
            initialized = true;
        });

        $output.append($reloader);
    };

    // post the form to a hidden iframe to re-use the form functionality
    $('#joy').submit(function(e) {
        e.preventDefault();
        $("#the_code").val(editor.getValue());
        setTimeout(function() { reload(); }, 3000); // delay to enable morbo to reload
        $.post(this.action, $(this).serialize());
    });

    // resize the editor and output blocks when the screen change size
    $(window).resize(function() {
        var height = $(window).height() - $masthead.height() - $description.height() - 30;
        editor.setSize($code.width(), height);
        $output.height(height);
    }).resize();

    // autosave the content of the editor
    editor.on("update", function() {
        clearTimeout(timeout);
        timeout = setTimeout(function() {
          $('form button[type="submit"]').text('Saving...');
          if(initialized) $('#joy').submit();
        }, 1000);
    });

    editor.setValue(document.getElementById("the_code").value);
    $('#joy').submit(); // make sure #output reflect the right sample
});
