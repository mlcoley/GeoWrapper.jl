mutable struct PyMap
    h::PyObject
    shp::String
end

function PyMap(proj::String, lowleft::AbstractVector, upright::AbstractVector,
    res::String="c")

    return PyMap(
        basemap[:Basemap](
            projection = proj,
            llcrnrlon = lowleft[1],
            llcrnrlat = lowleft[2],
            urcrnrlon = upright[1],
            urcrnrlat = upright[2],
            resolution = res
        ),
        ""
    )
end

project(m::PyMap, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}) =
    m.h(x, y)
project(m::PyMap, co::AbstractVector{<:Real}) = (m.h(co...))
project(m::PyMap, co::Coords) = transpose(hcat(m.h(co[1,:], co[2,:])...))
function project!(d::SpatialData, m::PyMap)
    for k in 1:size(d.co, 2)
        d.co[:, k] = [m.h(d.co[1,k], d.co[2,k])...]
    end
end

function load_shapefile!(m::PyMap, ifile::String, name::String)
    m.h[:readshapefile](ifile, name, drawbounds = false)
    m.shp = name
    return m
end

Base.getindex(m::PyMap, s::Symbol) = m.h[s]

shapes(m::PyMap) = haskey(m.h, Symbol(m.shp)) ? m[Symbol(m.shp)] : [()]
function shape_info(m::PyMap)
    fn = Symbol(m.shp * "_info")
    !haskey(m.h, fn) && return []
    return m[fn]
end

function outline_shapes(m::PyMap, color::String="black", ax=gca())
    isempty(m.shp) && return nothing

    for shape in shapes(m)
        m.h[:plot](first.(shape), last.(shape), color=color, linewidth=1, ax=ax)
    end
    return nothing
end

# fill_shapes => see http://www.datadependence.com/2016/06/creating-map-visualisations-in-python/
