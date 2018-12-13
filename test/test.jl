function test_data(co::Coords, n::Integer=100)
    minx, maxx = extrema(co[1,:])
    miny, maxy = extrema(co[2,:])

    idx = rand(CartesianIndices(100, 100), n)
    lat = zeros(length(idx))
    lon = zeros(length(idx))
    c = zeros(length(idx))
    for k in eachindex(idx)
        p = idx[k].I .- idx[k].I[1]
        c[k] = sqrt(sum(abs2, p))
        lat[k] = ((idx[k].I[1] / 100) * (maxy - miny)) + miny
        lon[k] = ((idx[k].I[2] / 100) * (maxx - minx)) + minx
    end

    co = hcat([Float64[ind[i] for i=1:2] for ind in idx]...)

    return co, c
end
