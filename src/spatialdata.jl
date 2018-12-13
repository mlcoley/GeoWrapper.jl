mutable struct SpatialData{T<:Real, L<:Real}
    co::Matrix{T}
    d::Vector{L}
end

function SpatialData(x::AbstractVector{<:Real}, y::AbstractVector{<:Real},
    d::AbstractVector{<:Real})
    return SpatialData(
        permutedims(hcat(x, y), [2, 1]),
        d
    )
end

@inline coords(d::SpatialData) = d.co
@inline data(d::SpatialData) = d.d
