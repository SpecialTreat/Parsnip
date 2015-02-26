

var agent = navigator.userAgent || navigator.vendor || window.opera || '';
var regex = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i;
var isMobile = regex.test(agent);

// begin_appear
// finish_appear
// begin_disappear
// finish_disappear
var constants = {

    home: 0,
    home_begin_disappear: 900,
    home_finish_disappear: 1400,

    title_begin_disappear: 0,
    title_finish_disappear: 500,

    title_bubbles_begin_appear: 0,
    title_bubbles_finish_disappear: 800,

    quote_bubbles_begin_appear: 750,
    quote_bubbles_finish_disappear: 1750,

    quotes_begin_appear: 200,
    quotes_finish_appear: 600,
    quotes_begin_disappear: 900,
    quotes_finish_disappear: 1400,

    quote_a_begin_appear: 200,
    quote_a_finish_appear: 700,

    quote_b_begin_appear: 400,
    quote_b_finish_appear: 900,

    design: 1400,

    parsnip: 1900,
    parsnip_begin_disappear: 1950,
    parsnip_finish_disappear: 2550,

    charity: 2550,
    charity_finish_disappear: 3150,

    contact_begin_appear: 2900,
    contact: 3300,

    end: 3350
};

var s = skrollr.init({
    edgeStrategy: 'set',
    smoothScrolling: true,
    mobileCheck: function() { return isMobile; },
    easing: {
        inOut: function(p) {
            if (p <= 0.5) {
                return 2 * p * p;
            } else {
                return 1 - (2 * (1 - p) * (1 - p));
            }
        }
    },
    constants: constants
});

skrollr.menu.init(s, {
    handleLink: function(link) {
        var hash = link.getAttribute('href');
        var id = hash.substr(1);
        return constants[id];
    }
});

var ids = ['quotes', 'design', 'parsnip', 'charity', 'contact'];
for(var i = 1; i <= 10; i++) {
    ids.push('bubble-layer-' + i);
}

var ids_len = ids.length;
for(var i = 0; i < ids_len; i++) {
    var id = ids[i];
    var el = document.getElementById(id);
    el.style.display = 'inherit';
}

