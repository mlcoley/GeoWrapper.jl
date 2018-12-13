module GeoWrapper

#TODO
# 1. change name of data() method, maybe coords() too

using PyCall

const basemap = PyObject(PyNULL)

function __init__()
    if !("." in LOAD_PATH)
        push!(LOAD_PATH, ".")
    end
    copy!(basemap, pyimport("mpl_toolkits.basemap"))
end

using PyPlot, GeoStats, Random, Statistics

include("./CSV/CSV.jl")

using .CSV

const Coords = AbstractMatrix{<:Real}
const SolverType = Union{AbstractEstimationSolver, KrigingEstimator}

export PyMap,
    load_shapefile!,
    project,
    project!,
    SpatialData,
    variogram_types,
    variogram,
    krig,
    plot_scatter,
    plot_variogram,
    plot_krig,
    outline_shapes,
    GaussianVariogram,
    SphericalVariogram,
    ExponentialVariogram,
    RegularGrid,
    bounding_grid,
    validate,
    solver,
    data,
    coords,
    rsquared,
    rmse,
    msdr

include("./spatialdata.jl")
include("./pymap.jl")
include("./geo_utils.jl")
#
include("./variogram.jl")
include("./kriging.jl")
#
include("./validate.jl")
#
include("./plot_utils.jl")
include("./plotting.jl")

end
