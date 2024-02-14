module AirfoilFast

using DelimitedFiles, CSV, DataFrames
using PyFormattedStrings
using FLOWMath
# using PyPlot, PyCall

include("base.jl")
export Airfoil, data

include("geometry.jl")
export centroid, scale!, scale, normalize!, rotate!, rotated!
export interpolate_airfoils, upper, lower, TE, LE, camberline, camberlength, chordlength
export twist, twistd, area, thickness, thickness_max, thickness_TE

include("io.jl")
export save, save_dust

# include("plot.jl")
# export plot

end
