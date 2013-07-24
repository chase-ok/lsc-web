define ['other', 'triggers/plot', 'jquery'], (other, plot, $) ->
    console.log "Loaded"
    $ ->
        other.helloFromJS()
        plot.makePlot()
