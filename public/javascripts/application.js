var Search = {
    init: function() {
        this.addTerm()

        $('form#search').submit(function() {
            Search.search()

            return false
        })

        $('#show_analysis').live('click', function() {
            $('div.original').toggle()
            $('div.analysis').toggle()
        })

        $('#terms').sortable({
            axis: "y",

            update: function(event, ui) {
                Search.toggleDistanceFields()

                Search.setIndexes()
            }
        })
    } ,

    setIndexes: function() {
       $('div.search-term').each(function(index){
            $(this).find('input.index').val(index)
        })
    } ,

    toggleDistanceFields: function() {
        $('div.search-term tr.distance').show()
        $('div.search-term:first tr.distance').hide()
        $('div.search-term:first tr.distance:hidden input.distance-field').val("")
    } ,

    search: function() {
        $("#search-results").html('<img src="/images/ajax-loader.gif" />')

        $("#search-results").load("/search/search_preview", $('form#search').serialize())
    } ,

    addTerm: function() {
        var index = 0

        if($('div.search-term').size() > 0) {
            index = parseInt($('div.search-term').last().find('input.index').val()) + 1
        }

        $.get("/search/search_term", { index: index }, function(data) {
            $('#search #terms').append(data)

            Search.setIndexes()
        })

        Search.toggleDistanceFields()
    } ,

    removeTerm: function($term) {
        $term.remove()
        this.toggleDistanceFields()
        this.setIndexes()
    } ,

    exportToExcel: function() {
        document.location = "/search/excel_export?" + $('form#search').serialize()
    } ,

    invertTypes: function($container) {
        $container.find('input[type=checkbox]').each(function() {
            this.checked = !this.checked
        })
    }

}

$(function() {
    Search.init()
})
