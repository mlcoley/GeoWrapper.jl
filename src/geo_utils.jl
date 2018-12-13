# ============================================================================ #
function orient_image(im::AbstractVector, dims::Tuple{Int,Int})
    return reverse(transpose(reshape(im, dims...)), dims=1)
end
# ============================================================================ #
function get_coordinates(d::AbstractDomain{T}) where T<:Real
    n = npoints(d)
    x = Vector{T}(undef, n)
    y = copy(x)
    tmp = [0., 0.]
    for k in 1:n
        coordinates!(tmp, d, k)
        x[k] = tmp[1]
        y[k] = tmp[2]
    end
    return x, y
end
# ============================================================================ #
function bounding_grid(d::SpatialData{T,}, dims::NTuple{N,Int}) where {T, N}
    return bounding_grid(coords(d), dims)
end
# ============================================================================ #
function bounding_grid(co::AbstractArray{T,N}, dims::NTuple{N,Int}) where {T<:Real,N}
    n = size(co, 1)

    start = fill(typemax(T), n)
    stop = fill(typemin(T), n)

    for k in 1:size(co, 2)
        for j in 1:n
            if co[j,k] < start[j]
                start[j] = co[j,k]
            end
            if co[j,k] > stop[j]
                stop[j] = co[j,k]
            end
        end
    end
    return RegularGrid(tuple(start...), tuple(stop...), dims=dims)
end
# ============================================================================ #
