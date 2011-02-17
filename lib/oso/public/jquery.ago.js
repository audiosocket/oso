(function($) {
    $.fn.ago = function() {
        var now = parseInt((new Date()).getTime() / 1000)

        return this.each(function() {
            var then    = parseInt($(this).attr("data-at"), 10)
            var delta   = now - then
            var message = "" + delta + " seconds ago"

            if (delta < 30)
                message = "just now"

            else if (delta >= 60 && delta < 120)
                message = "a minute ago"

            else if (delta >= 120 && delta < 3300)
                message = "" + parseInt(delta / 60) + " minutes ago"

            else if (delta >= 3300 && delta < 3600)
                message = "almost an hour ago"

            else if (delta >= 3600) {
                var hours = parseInt(delta / 3600)
                var unit  = hours > 1 ? "hours" : "hour"
                message = "" + hours + " " + unit + " ago"
            }

            $(this).html(message)
        })
    }
})(jQuery)
