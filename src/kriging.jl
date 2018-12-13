import GeoStats.fit!
# ============================================================================ #
function krig(t::Variogram, d::SpatialData, dim::Tuple{N,Int}) where {T<:Real,N}
    return krig(bounding_grid(coords(d), dim), t, d)
end
# ---------------------------------------------------------------------------- #
function krig(::Type{T}, t::Variogram, d::SpatialData,
    dim::Tuple{N,Int}, param::Real) where {T<:SolverType,N}

    est = T(coords(d), data(d), t, mu)
    return krig(est, bounding_grid(coords(d), dim), d)
end
# ---------------------------------------------------------------------------- #
function krig(::Type{OrdinaryKriging}, t::Variogram, d::SpatialData,
    dim::Tuple{N,Int}, args...) where N
    return krig(bounding_grid(coords(d), dim), t, d)
end
# ---------------------------------------------------------------------------- #
function krig(dom::AbstractDomain, t::Variogram, d::SpatialData{L,T}) where
    {L,T<:Real}

    est = OrdinaryKriging(coords(d), data(d), t)
    return krig(est, dom, d)
end
# ---------------------------------------------------------------------------- #
function krig(est::SolverType, dom::AbstractDomain, d::SpatialData)

    fit!(est, d)

    xmean, xvar = predict(est, dom)
    return xmean, xvar, dom
end
# ---------------------------------------------------------------------------- #
@inline function GeoStats.fit!(est::SolverType, d::SpatialData)
    return fit!(est, coords(d), data(d))
end
# ---------------------------------------------------------------------------- #
function predict(est::SolverType, dom::AbstractDomain)
    xmean = Vector{Float64}(undef, npoints(dom))
    xvar = Vector{Float64}(undef, npoints(dom))

    co = GeoStats.MVector{ndims(dom), coordtype(dom)}(undef)

    for k in 1:npoints(dom)
        coordinates!(co, dom, k)
        xmean[k], xvar[k] = estimate(est, co)
    end
    return xmean, xvar
end
# ---------------------------------------------------------------------------- #
function predict(est::SolverType, co::AbstractMatrix{T}) where T<:Real
    xmean = Vector{T}(undef, size(co, 2))
    xvar = Vector{T}(undef, size(co, 2))

    for k in 1:size(co, 2)
        xmean[k], xvar[k] = estimate(est, co[:,k])
    end
    return xmean, xvar
end
# ============================================================================ #
function solver(t::Variogram, sd::SpatialData{C,D}; args...) where {C<:Real, D}
    return solver(C, t, args...)
end
# ---------------------------------------------------------------------------- #
function solver(::Type{C}, t::Variogram{D}; mu::Real=NaN, degree::Integer=-1,
    drifts::AbstractVector{Function}=Function[]) where {C<:Real, D}

    if !isempty(drifts)
        return ExternalDriftKriging{C,D}(t, drifts)
    elseif degree > 0
        return UniversalKriging{C,D}(t, degree)
    elseif !isnan(mu)
        return SimpleKriging{C,D}(t, mu)
    else
        return OrdinaryKriging{C,D}(t)
    end
end
# ============================================================================ #
# function krig(t::Variogram, d::Dict{Symbol,Vector}, co::AbstractMatrix{<:Real},
#     var::Symbol)
#
#     ps = PointSetData(d, co)
#
#     # domain of just the data points
#     # domain = boundgrid(ps, (100,100))
#
#     # domain of the whole map of (Ethiopia)
#     domain = RegularGrid(
#         (0.0, 0.0),
#         (1.77e6, 1.31e6),
#         dims=(100,100)
#     )
#
#     problem = EstimationProblem(ps, domain, var)
#     solver = Kriging(
#         var => (variogram=t,)
#     )
#     return solve(problem, solver)
# end
# ============================================================================ #
