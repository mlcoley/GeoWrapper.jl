# ============================================================================ #
function plot_scatter(m::PyMap, d::SpatialData, cm::String="viridis", ax=gca())
    co = coords(d)
    hp = m[:scatter](co[1,:], co[2,:], s=60, c=data(d), cmap=get_cmap(cm),
        edgecolor="none")
    hp[:set_zorder](length(ax[:get_children]()))
    colorbar(hp, fraction=0.046, pad=0.04, ax=ax, use_gridspec=true)
    return hp
end
# ============================================================================ #
function plot_variogram(g::EmpiricalVariogram, t::Variogram, ax=gca())
    return plot_variogram(g, [t], ax)
end
function plot_variogram(g::EmpiricalVariogram, t::AbstractVector{<:Variogram},
    ax=gca())

    x, y, n = values(g)
    x = x[n .> 0]
    y = y[n .> 0]
    n = n[n .> 0]

    default_axes(ax)

    ax[:plot](x ./ 1e3, y, ".", markersize=12, label="data")

    for k in eachindex(t)
        m = match(r"^(\w+)\W*", string(typeof(t[k])))
        name = m != nothing ? m[1] : "fit-$(k)"
        ax[:plot](x ./ 1e3, t[k](x), linewidth=3.0, label=name)
    end

    ax[:set_xlabel]("lag (km)", fontsize=14)
    ax[:set_ylabel](L"\gamma(h)", fontsize=14)
    ax[:legend](frameon=false, fontsize=12, loc="upper left")
    ax[:set_ylim]([0.0, ax[:get_ylim]()[2]])
    return nothing
end
# ============================================================================ #
function plot_krig(m::PyMap, dom::AbstractDomain,
    field::AbstractArray{<:Real}, typ::Symbol=:contourf, ax::PyObject=gca(), 
    cbar::Bool=true)

    if typ == :contour || typ == :contourf
        x, y = get_coordinates(dom)

        hc = m[typ](
            reshape(x, size(dom)...),
            reshape(y, size(dom)...),
            reshape(field, size(dom)...),
            ax=ax
        )

        if typ == :contour
            nc = length(gca()[:get_children]())
        else
            nc = 1
        end
        foreach(x->x[:set_zorder](nc), hc[:collections])

    elseif typ == :image
        hc = m[:imshow](permutedims(reshape(field, size(dom)...), [2,1]))
        hc[:set_zorder](1)
    end
    if cbar
        colorbar(hc, fraction=0.046, pad=0.04, ax=ax, use_gridspec=true)
    end
    return hc
end
# ============================================================================ #
