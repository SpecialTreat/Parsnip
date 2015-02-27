var agent = navigator.userAgent || navigator.vendor || window.opera || '';
var regex = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i;
var isMobile = regex.test(agent);
if (isMobile) {
    var getWindowHeight = function() {
        // Get zoom level of mobile Safari
        // Note, that such zoom detection might not work correctly in other
        // browsers. We use width, instead of height, because there are no
        // vertical toolbars :)
        var zoomLevel = (document.documentElement.clientWidth /
                         window.innerWidth);
        // window.innerHeight returns height of the visible area.
        // We multiply it by zoom and get out real height.
        return window.innerHeight * zoomLevel;
    };
} else {
    var getWindowHeight = function() {
        return $(window).height()
    };
}
jQuery(document).ready(function($) {
    var $document = $(document),
        $htmlbody = $('html,body'),
        $contactLink = $('#contact-link');
    $contactLink.click(function(event) {
        event.preventDefault();
        $htmlbody.animate({
            scrollTop: $document.height() - getWindowHeight()
        }, 500, 'easeInOutQuint');
    });
});

