using GeoWrapper, GeoStats, PyPlot, Statistics

import GeoWrapper.CSV

# --- Paths to data file and ethiopia regions shapefile --- #
shppath = joinpath(@__DIR__, "demo_data", "regions", "Eth_Region_2013")

ifile = joinpath(@__DIR__, "demo_data", "layer1_well.csv")

basepath = joinpath(@__DIR__, "demo_data")

# --- Read in the data --- #

d = CSV.parse(ifile, ',', vcat([Int, Int, Int, Int, String, String, String, Float64, Float64, Float64, Float64, String], fill(Float64, 7), [String, String, Float64, Float64]))

# --- Construct a Basemap for a rectangle containing ethiopia --- #

# long, lat format (x, y)
lowleft = [32.360254, 3.167433]
upright = [48.218180, 15.121328]

# use cea projection
m = PyMap("cea", lowleft, upright)

# --- Construct a SpatialData object to hold the data and coordinates --- #
sd = SpatialData(d["long"], d["lat"], d["Total.Carbon"])

# --- Project data onto our map (coordinate units are now meters) --- #
project!(sd, m)

emp, theo = variogram(SphericalVariogram, sd, nlags=20, maxlag=300e3)

# --- load a shapefile into the map (does not plot anything yet) --- #
# NOTE: shapefile *MUST* already be in geographic coordinates (limitation of
# Basemap, sorry)
load_shapefile!(m, shppath, "regions")

# --- Plot region outlines (from shapefile) and plot our data points --- #
figure()
outline_shapes(m)
plot_scatter(m, sd)

# --- Fit a lVariograms to our data and plot the results --- #
@info("Constructing variogram...")

emp, theo = variogram(SphericalVariogram, sd, nlags=10, maxlag=70e3)
theo2 = fit(ExponentialVariogram, emp)
theo3 = fit(GaussianVariogram, emp)

figure()
plot_variogram(emp, [theo, theo2, theo3])

# --- Construct a grid on which we will krig --- #
# NOTE: here we are using the full extent of the map

# # grid for full map
# domain = RegularGrid(
#     project(m, lowleft),
#     project(m, upright),
#     dims=(100,100)
# )

# grid for area surrounding the data points
domain = bounding_grid(sd, (100, 100))

# --- Run the kriging interpolation --- #
@info("Kriging...")

# third output is the domain which we already have so ignore it with '_'
mn, var, _ = krig(domain, theo, sd)

# --- Plot the estimated field (mn2 = mean, first output of krig()) --- #
h, ax = subplots(1, 2)
plot_krig(m, domain, mn, :contourf, ax[1])
outline_shapes(m, "black", ax[1])
ax[1][:set_title]("Prediction", fontsize=16)

plot_krig(m, domain, var, :contourf, ax[2])
outline_shapes(m, "black", ax[2])
ax[2][:set_title]("Variance", fontsize=16)
m[:plot](sd.co[1,:], sd.co[2,:], ".k", markersize=5, ax=ax[2])
tight_layout()

# --- Cross-validation: variograms --- #
emp, theo = variogram(SphericalVariogram, sd, nlags=10, maxlag=70e3)
theo2 = fit(ExponentialVariogram, emp)
theo3 = fit(GaussianVariogram, emp)

slvr = [
    solver(Float64, theo),  #OrdinaryKriging w/ SphericalVariogram
    solver(Float64, theo2), #OrdinaryKriging w/ ExponentialVariogram
    solver(Float64, theo3)  #OrdinaryKriging w/ GaussianVariogram
]

rme, rsq, msd = validate(slvr, sd, 50)

# --- Cross-validation: angles --- #
angles = 0:pi/4:3pi/4
slvr = Vector{GeoWrapper.SolverType}(undef, length(angles))

for k in eachindex(angles)
    emp, theo = variogram(ExponentialVariogram, sd, nlags=10, maxlag=70e3,
        distance=Ellipsoidal([1.0, 0.5], [angles[k]]))
    t = ExponentialVariogram(range=theo.range, sill=theo.sill,
        nugget=theo.nugget, distance=Ellipsoidal([1.0, 0.5], [angles[k]]))
    slvr[k] = solver(Float64, t)
end

rme, rsq, msd = validate(slvr, sd, 50)

# --- Plotting for all three regions: exp variogram at 90 degrees --- #

emp, t = variogram(ExponentialVariogram, sd, nlags=10, maxlag=70e3,
    distance=Ellipsoidal([1.0, 0.5], [pi/2.0]))

theo = ExponentialVariogram(range=t.range, sill=t.sill,
    nugget=t.nugget, distance=Ellipsoidal([1.0, 0.5], [pi/2.0]))

files = ["layer1_well", "layer1_bor", "layer1_ars"]
hc = Vector{Any}(undef, length(files))

h, ax = subplots(1, 3)

for k in eachindex(files)
    ifile = joinpath(basepath, files[k] * ".csv")
    d = CSV.parse(ifile, ',', vcat([Int, Int, Int, Int, String, String, String, Float64, Float64, Float64, Float64, String], fill(Float64, 7), [String, String, Float64, Float64]))

    sd = SpatialData(d["long"], d["lat"], d["Total.Carbon"])
    project!(sd, m)

    domain = bounding_grid(sd, (100, 100))

    mn, _, _ = krig(domain, theo, sd)

    cbar = k == 3 ? true : false

    hc[k] = plot_krig(m, domain, mn, :contourf, ax[k], cbar)

    hc[k][:set_clim](0.8, 7.2)

    outline_shapes(m, "black", ax[k])
    println("DONE: $(k) of 3")
end
