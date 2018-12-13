# ============================================================================ #
function variogram_types(x::Symbol=:default)
    out = Type{<:Variogram}[GaussianVariogram,
        SphericalVariogram, ExponentialVariogram]
    if x == :all
        append!(out, Type{<:Variogram}[MaternVariogram, CubicVariogram,
            PentasphericalVariogram])
    end
    return out
end
# ============================================================================ #
function variogram(d::SpatialData; args...)
    return variogram(variogram_types(), d; args...)
end
# ---------------------------------------------------------------------------- #
function variogram(::Type{T}, d::SpatialData; args...) where T<:Variogram

    g = EmpiricalVariogram(coords(d), data(d); args...)
    t = fit(T, g)
    return g, t
end
# ---------------------------------------------------------------------------- #
function variogram(va::Vector{Type{<:Variogram}}, d::SpatialData; args...)

    g = EmpiricalVariogram(coords(d), data(d); args...)
    t = GaussianVariogram()
    err = +Inf
    for v in va
        tf, e = GeoStats.Variography.fit_impl(v, g,
            GeoStats.Variography.WeightedLeastSquares())
        if e < err
            err = e
            t = tf
        end
    end

    return g, t
end
# ============================================================================ #
