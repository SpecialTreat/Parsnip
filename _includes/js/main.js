var agent = navigator.userAgent || navigator.vendor || window.opera || '';
var isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(agent);
var isIOS = /iPhone|iPad|iPod/i.test(agent);

if (isIOS) {
    {% include js/iosfix.js %}
}

jQuery(document).ready(function($) {

    var $document = $(document),
        $window = $(window),
        $body = $('body'),
        $navbar = $('#top-navbar'),
        $navbarContent = $('#top-navbar-content'),
        $slides = $('#slides');

    $navbarContent.on('hide.bs.collapse', function () {
        $navbar.removeClass('expanded');
    });

    $navbarContent.on('show.bs.collapse', function () {
        $navbar.addClass('expanded');
    });

    $slides.on('movestart', function(e) {
        // If the movestart is heading off in an upwards or downwards
        // direction, prevent it so that the browser scrolls normally.
        if ((e.distX > e.distY && e.distX < -e.distY) || (e.distX < e.distY && e.distX > -e.distY)) {
            e.preventDefault();
        }
    });

    $slides.on('mousedown', function(e) {
        e.preventDefault();
        $body.addClass('grabbing');
    });

    $body.on('mouseup touchend', function() {
        $body.removeClass('grabbing');
    });

    $slides.on('swiperight', function() {
        $slides.carousel('prev');
        $body.removeClass('grabbing');
    });

    $slides.on('swipeleft', function() {
        $slides.carousel('next');
        $body.removeClass('grabbing');
    });

    var updateNavbarTransparency = function() {
        if ($window.scrollTop() > 0) {
            $navbar.addClass('opaque');
        } else {
            $navbar.removeClass('opaque');
        }
    };
    updateNavbarTransparency();
    $window.scroll(updateNavbarTransparency);
});
