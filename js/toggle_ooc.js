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
    var lastOffset = 0;

    var resetHideTimer = function() {
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            oocButton.css('opacity', 0);
            shown = false;
        }, 2000);
    }

    $(window).on("scroll", function() {
        var curOffset = oocButton.offset().top;
        if (!shown && curOffset > 200 && curOffset < lastOffset) {
            oocButton.css('opacity', 1);
            shown = true;
        } else if (shown && curOffset > lastOffset) {
            oocButton.css('opacity', 0);
            shown = false;
        }

        lastOffset = curOffset;
        resetHideTimer();
    });

    $(window).on("click", function() {
        if (!shown) {
            oocButton.css('opacity', 1);
            shown = true;
        } else if (shown) {
            oocButton.css('opacity', 0);
            shown = false;
        }

        resetHideTimer();
    })
})();

toggleOOC();