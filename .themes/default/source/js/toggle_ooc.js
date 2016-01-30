(function() {
    "use strict";
    var fixedMenu = $("#fixed_menu");
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

    var hideMenu = function() {
        shown = false;
        fixedMenu.removeClass('shown');
        clearHideTimer();
    };

    var showMenu = function() {
        shown = true;
        fixedMenu.addClass('shown');
        resetHideTimer();
    };

    var allowMenuClose = function() {
        canClose = true;
    };

    var resetHideTimer = function() {
        clearTimeout(timeout);
        clearTimeout(closeableTimeout);
        canClose = false;
        timeout = setTimeout(hideMenu, 2000);
        closeableTimeout = setTimeout(allowMenuClose, 500);
    };

    var clearHideTimer = function() {
        clearTimeout(timeout);
    };

    win.on("scroll", function() {
        var curScroll = win.scrollTop();
        if (!shown && curScroll > minScroll && curScroll < lastScroll) {
            showMenu();
        } else if (shown && canClose && (curScroll > lastScroll || curScroll < minScroll)) {
            // keep it from closing early
            // have some min time before closing
            hideMenu();
        }

        lastScroll = curScroll;
    });

    win.on("click", function(e) {
        // Don't hide the button if user clicked a real link or the label
        if (e.target.tagName === "A" || e.originalEvent.passedThroughFixedMenu) return;

        if (!shown) {
            showMenu();
        } else if (shown) {
            hideMenu();
        }
    });

    fixedMenu.click(function(e) {
        resetHideTimer();
        e.originalEvent.passedThroughFixedMenu = true;
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
    };
    toggleOOC();

    $("#ooc_toggle").change(toggleOOC);
})();
