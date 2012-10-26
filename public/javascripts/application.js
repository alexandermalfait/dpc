var Search = {
    init: function() {
        this.addTerm(true)

        $('form#search').submit(function() {
            Search.search()

            return false
        })

        $('#show_analysis').live('click', function() {
            $('div.original').toggle()
            $('div.analysis').toggle()
        })

        $('#active-languages input[type=checkbox]').click(function() {
            Search.updateVisibleTypeFields()
        })

        $('#terms').sortable({
            axis: "y",

            update: function(event, ui) {
                Search.toggleDistanceFields()

                Search.setIndexes()
            }
        })

        $(".search-term input.filter-selection").live('click', function() {
            var $relevantRow = $(this).closest('.search-term').find('tr.' + this.value + "-filter")

            if(this.checked) {
                $relevantRow.show()
                $relevantRow.find('input[type=text]').first().focus()
            }
            else {
                $relevantRow.hide()
                $relevantRow.find('input[type=text]').val('')
                $relevantRow.find('input[type=checkbox]').attr('checked','')
            }
        })

        $(".search-term td.occurrence-type input[type=radio]").live('click', function() {
            if(this.checked && this.value == "wildcard") {
                $(this).closest('.search-term').addClass('wildcard-term')
            }
            else {
                $(this).closest('.search-term').removeClass('wildcard-term')
            }

            if(this.checked && this.value != "range") {
                $(this).siblings("input.occurrence-range").val('')
            }
        })

        $(".search-term input.occurrence-range").live('change', function() {
            $(this).siblings("input[value=range]").attr('checked','checked')
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

        this.startProgressPoll()

        $("#search-results").load("/search/search_preview", $('form#search').serializeArray(), function() {
            Search.endProgressPoll()
        })
    } ,

    endProgressPoll: function() {
        window.clearInterval(Search.progressPollingInterval)
        $("#current-progress").hide()

        document.title = "DPC: Done"
    } ,

    startProgressPoll:function () {
        $("#current-progress").show()
        $("#current-progress").html("Working...")

        Search.progressPollingInterval = window.setInterval(function () {
            Search.pollProgress()
        }, 1000)
    } ,

    pollProgress: function() {
        $("#current-progress").load("/current_progress.txt?nocache=" + (new Date()).getTime())

        document.title = "DPC: " + $("#current-progress").html()

        if($("#current-progress").html() == "Done") {
            this.endProgressPoll()
        }
    } ,

    addTerm: function(wildcard) {
        var index = 0

        if($('div.search-term').size() > 0) {
            index = parseInt($('div.search-term').last().find('input.index').val()) + 1
        }

        $.get("/search/search_term", { index: index, wildcard: wildcard }, function(data) {
            $('#search #terms').append(data)

            Search.setIndexes()

            Search.autoLinkCheckboxLabels()

            Search.updateVisibleTypeFields()
        })
    } ,

    autoIdIndex: 0,

    autoLinkCheckboxLabels: function() {
        $('#search #terms input[type=checkbox], #search #terms input[type=radio]').each(function() {
            if(!this.id) {
                Search.autoIdIndex++
                $(this).attr('id', "auto-id-" + Search.autoIdIndex)
            }

            $(this).next('label').attr('for', this.id)
        })
    } ,

    removeTerm: function($term) {
        $term.remove()
        this.toggleDistanceFields()
        this.setIndexes()
    } ,

    exportToExcel: function() {
        this.startProgressPoll()

        $('#download-form').empty()

        $.each($('form#search').serializeArray(), function() {
            $('#download-form').append($('<input type="hidden" />').attr('name', this.name).val(this.value))
        })

        $('#download-form').submit()
    } ,

    invertTypes: function($container) {
        $container.find('input[type=checkbox]').each(function() {
            this.checked = !this.checked
        })
    } ,

    updateVisibleTypeFields: function() {
        var languages = []

        $('#active-languages input[type=checkbox]:checked').each(function() {
            var language = $(this).attr('data-language-base')

            if(languages.indexOf(language) == -1) {
                languages.push(language)
            }
        })

        $('table.word-types').hide()

        $.each(languages, function() {
            $('table.word-types[data-language=' + this + ']').show()
        })
    }

}

$(function() {
    Search.init()
})
