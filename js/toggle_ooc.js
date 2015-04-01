(function() {
    var oocButton = $("#ooc_label");
    // get window
    var win = $(window);
    // use vars to short circuit doing work again
    var shown = false;
    var canClose = false;
    
    var lastScroll = 0;
    var minScroll = 200; // how far down in order to show it
    
    var timeout;
    var closeableTimeout;

    var hideButton = function() {
        shown = false;
        oocButton.removeClass('shown');
        clearHideTimer();
    }

    var showButton = function() {
        shown = true;
        oocButton.addClass('shown');
        resetHideTimer();
    }

    var allowButtonClose = function() {
        canClose = true;
    }

    var resetHideTimer = function() {
        clearTimeout(timeout);
        clearTimeout(closeableTimeout);
        canClose = false;
        timeout = setTimeout(hideButton, 2000);
        closeableTimeout = setTimeout(allowButtonClose, 500);
    }

    var clearHideTimer = function() {
        clearTimeout(timeout);
    }

    win.on("scroll", function() {
        var curScroll = win.scrollTop();
        if (!shown && curScroll > minScroll && curScroll < lastScroll) {
            showButton();
        } else if (shown && canClose && (curScroll > lastScroll || curScroll < minScroll)) {
            // keep it from closing early
            // have some min time before closing
            hideButton();
        }

        lastScroll = curScroll;
    });

    win.on("click", function(e) {
        // Don't hide the button if user clicked a real link or the label
        if (e.target.tagName === "A" || e.target.id === "ooc_label") return;

        if (!shown) {
            showButton();
        } else if (shown) {
            hideButton();
        }
    });

    $("#ooc_label").click(function(e) {
        resetHideTimer();
    });

    var toggleOOC = function(e) {
        // var topPost = $("p.rp").withinViewportTop().first();
        // var topPost = $("p.rp").not(":above-the-top").first();
        var originalScroll = $(window).scrollTop();
        var topPost = $("p.rp").filter(function(index, elem) {
            return $(elem).offset().top >= originalScroll;
        }).first();

        var originalOffset = topPost.offset();

        // checked == show; not checked == hide
        var visible = $("#ooc_toggle").is(":checked");
        $(".ooc").toggle(visible);

        $(window).scrollTop(originalScroll + (topPost.offset().top - originalOffset.top));
    }
    toggleOOC();

    $("#ooc_toggle").change(toggleOOC)
})();

