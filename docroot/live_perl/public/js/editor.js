$(document).ready(function() {
    var $code = $('#code');
    var $information = $('.information');
    var $masthead = $('.masthead');
    var $output = $('#output');
    var editor = CodeMirror($code[0], { lineNumbers: true });
    var $reloader = $();
    var timeout;

    // reload the output iframe without flickering, by adding a new iframe that loads in the background
    var reload = function() {
        if($reloader.hasClass('hidden')) $reloader.remove(); // abort unfinished iframe

        $reloader = $('<iframe class="hidden"></iframe>');
        $reloader.attr('src', $output.attr('data-url'));
        $reloader.load(function() {
            $output.find('iframe').not('.hidden').remove();
            $output.children().not('iframe').remove();
            $reloader.removeClass('hidden').attr('data-ts', new Date());
        });

        $output.append($reloader);
    };

    // post the form to a hidden iframe to re-use the form functionality
    $('body').append('<iframe name="autosave" style="position:absolute;left:-1000px;width:100px;"></iframe>');
    $('#joy').attr('target', 'autosave').submit(function(e) {
        $("#the_code").val(editor.getValue());
        setTimeout(function() { reload(); }, 3000);
        return true;
    });

    // resize the editor and output blocks when the screen change size
    $(window).resize(function() {
        var height = $(window).height() - $masthead.height() - $information.height() - 50;
        editor.setSize($code.width(), height);
        $output.height(height);
    }).resize();

    // autosave the content of the editor
    editor.on("cursorActivity", function() {
        clearTimeout(timeout);
        timeout = setTimeout(function() { $('#joy').submit(); }, 700);
    });

    editor.setValue(document.getElementById("the_code").value);
    setTimeout(function() { reload(); }, 3000); // load inital page
});
