# ============================================================================ #
function default_axes(ax=nothing)
    if ax == nothing
        ax = PyPlot.axes()
    end
    #set ticks to face out
    ax[:tick_params](direction="out", length=8.0, width=4.0)

    #turn off top and right axes
    ax[:spines]["right"][:set_visible](false)
    ax[:spines]["top"][:set_visible](false)

    #remove top and right tick marks
    tmp = ax[:get_xaxis]()
    tmp[:tick_bottom]()

    tmp = ax[:get_yaxis]()
    tmp[:tick_left]()

    ax[:spines]["left"][:set_linewidth](4.0)
    ax[:spines]["bottom"][:set_linewidth](4.0)

    return ax
end
# ============================================================================ #
