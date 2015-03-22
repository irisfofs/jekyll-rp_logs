function toggleOOC() {
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

(function() {
    var oocButton = $("#ooc_label");
    //  get window
    // use vars to short circuit doing work again
    var shown = false;
    var timeout;
    var lastScroll = 0;
    var minScroll = 200; // how far down in order to show it

    var resetHideTimer = function() {
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            oocButton.removeClass('shown');
            shown = false;
        }, 2000);
    }

    var clearHideTimer = function() {
        clearTimeout(timeout);
    }

    var win = $(window);

    win.on("scroll", function() {
        var curScroll = win.scrollTop();
        if (!shown && curScroll > minScroll && curScroll < lastScroll) {
            shown = true;
            oocButton.addClass('shown');
            resetHideTimer();
        } else if (shown && (curScroll > lastScroll || curScroll < minScroll)) {
            shown = false;
            oocButton.removeClass('shown');
            clearTimeout();
        }

        lastScroll = curScroll;
    });

    win.on("click", function() {
        if (!shown) {
            shown = true;
            oocButton.addClass('shown');
            resetHideTimer();
        } else if (shown) {
            shown = false;
            oocButton.removeClass('shown');
            clearHideTimer();
        }
    })
})();

toggleOOC();