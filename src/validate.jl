function validate(s::AbstractVector{T}, d::SpatialData, nfold::Integer) where T<:SolverType

    m = div(size(d.co, 2), nfold)

    rsq = fill(0.0, length(s))
    rme = fill(0.0, length(s))
    msd = fill(0.0, length(s))

    idx = shuffle(1:size(d.co, 2))

    for k in 0:(nfold-1)
        ks = k * m + 1
        ke = (k + 1) * m

        ktrain = vcat(idx[1:ks-1], idx[ke+1:end])
        ktest = idx[ks:ke]

        for j in eachindex(s)
            fit!(s[j], d.co[:,ktrain], d.d[ktrain])
            pred, var = predict(s[j], d.co[:, ktest])
            err = pred - d.d[ktest]
            rme[j] += rmse(err)
            rsq[j] += rsquared(d.d[ktest], err)
            msd[j] += msdr(var, err)
        end
        println("DONE: $(k+1) of $(nfold)")
    end
    return rme ./ nfold, rsq ./ nfold, msd ./ nfold
end

rmse(err::Vector{<:Real}) = sqrt(sum(abs2, err) / length(err))
function rsquared(d::Vector{<:Real}, err::Vector{<:Real})
    mn = mean(d)
    return 1.0 - (sum(abs2, err) / sum(x->abs2(x - mn), d))
end
function msdr(var::Vector{<:Real}, err::Vector{<:Real})
    res = 0.0
    for k in eachindex(var)
        res += err[k]^2 / var[k]
    end
    return res / length(var)
end
