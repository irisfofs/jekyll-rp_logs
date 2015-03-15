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

toggleOOC();