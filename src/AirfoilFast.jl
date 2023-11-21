module AirfoilFast

using DelimitedFiles, CSV, DataFrames
using PyFormattedStrings
using FLOWMath
using PyPlot, PyCall
export Airfoil, plot, plot_airfoils, scale!, normalize!, rotate!, rotated!
export twist, twistd, area, thickness, thickness_max, thickness_TE, data
export interpolate_airfoils, upper, lower, TE, LE, camberline, camberlength, chordlength
export interpolate_airfoils
export refine!
export save, save_dust

"""
    Airfoil(x, y, name)

Create an airfoil from the coordinates `x` and `y` and the name `name`.
"""
mutable struct Airfoil
    x
    y
    name
end

function fname_extension(fname)
    return split(fname, ".")[end]
end

"""
    Airfoil(fname; delimiter=' ', skipstart=1)

Read an airfoil from a file. The file can be either a .dat or a .csv file.
"""
function Airfoil(fname; delimiter=' ', skipstart=1)
    # get file extension 
    ext = fname_extension(fname)
    if ext == "dat"
        name = readlines(fname)[1]
        data = readdlm(fname, delimiter, Float64, '\n', header=false, skipstart=1)
        x = data[:, 1]
        y = data[:, 2]
    elseif ext == "csv"
        df = DataFrame(CSV.File(fname))
        x = df.x
        y = df.y
        name = df.name[1]
    end

    # if name starts with #, remove it, and remove trailing spaces
    if name[1] == '#'
        name = name[2:end]
    end
    name = strip(name)

    return Airfoil(x, y, name)
end

"""
    _polygon_area(x, y)

Calculate the area of a polygon defined by the points (x, y) using the shoelace formula.
"""
function _polygon_area(x, y)
    # Initialze area 
    area = 0.0

    # Calculate value of shoelace formula 
    j = length(x) - 1
    for i = 1:length(x)
        area += (x[j] + x[i]) * (y[j] - y[i])
        j = i   # j is previous vertex to i 
    end

    # Return absolute value 
    return abs(area / 2.0)
end

function Base.copy(af::Airfoil)
    return Airfoil(af.x, af.y, af.name)
end

"""
    scale(af::Airfoil, new_chord; LE_origin::Vector=true)

Scale an airfoil to a new chord length `new_chord`. If `LE_origin` is true, the
leading edge is used as origin, otherwise the origin is [0, 0].
"""
function scale!(af::Airfoil, new_chord; LE_origin::Vector=true)
    if LE_origin
        le = LE(af)
    else
        le = [0, 0]
    end
    af.x = (af.x .- le[1]) * new_chord .+ le[1]
    af.y = (af.y .- le[2]) * new_chord .+ le[2]
end

"""
    normalize!(af::Airfoil)

Normalize an airfoil to the chord length 1, a twist angle of 0 and the leading edge as origin.
"""
function normalize!(af::Airfoil)
    le = LE(af)
    _twist = twist(af)
    rotate!(af, -_twist)

    c = chordlength(af)
    d = data(af) / c
    d = d .- reshape(le, (1, 2))

    af.x = d[:, 1]
    af.y = d[:, 2]
end

"""
    rotate!(af::Airfoil, angle; rotation_axis=nothing)

Rotate an airfoil by `angle` [rad] around the point `rotation_axis`. 
If `rotation_axis` is not specified, the leading edge is used as rotation axis.
"""
function rotate!(af::Airfoil, angle; rotation_axis=nothing)
    if rotation_axis === nothing
        rotation_axis = LE(af)
    end
    d = data(af)
    R = [
        cos(angle) -sin(angle);
        sin(angle) cos(angle)]
    for i = 1:length(af)
        d[i, :] = R * (d[i, :] .- rotation_axis) .+ rotation_axis
    end
    af.x = d[:, 1]
    af.y = d[:, 2]
end

"""
    rotated(af::Airfoil, angle; rotation_axis=nothing)

Return a rotated copy of an airfoil by `angle` [deg] around the point `rotation_axis`. 
If `rotation_axis` is not specified, the leading edge is used as rotation axis.
"""
function rotated!(af::Airfoil, angle; rotation_axis=nothing)
    rotate!(af, deg2rad(angle); rotation_axis)
end

"""
    twist(af::Airfoil, angle; rotation_axis=nothing)

Twist of an airfoil [rad].
"""
function twist(af::Airfoil)
    # calculate angle chordline against x axis 
    te = TE(af)
    le = LE(af)
    # return atan((te[2] - le[2]) / (te[1] - le[1]))
    dx = te[1] - le[1]
    dy = te[2] - le[2]
    return atan(dy, dx)
end

"""
    twistd(af::Airfoil)

Twist of an airfoil [deg].
"""
function twistd(af::Airfoil)
    return twist(af) * 180 / pi
end

"""
    area(af::Airfoil)

Calculate the area of an airfoil.
"""
function area(af::Airfoil)
    return _polygon_area(af.x, af.y)
end

function Base.length(af::Airfoil)
    return length(af.x)
end

function Base.show(io::IO, af::Airfoil)
    println(io, f"──── Airfoil {af.name} ────")
    println(io, f" n                {length(af):9d}")
    println(io, f" chord            {chordlength(af):9.2f}")
    println(io, f" thickness_max    {thickness_max(af):9.2e}")
    println(io, f" area             {area(af):9.2e}")
end

"""
    thickness(af::Airfoil)

Calculate the thickness distribution of an airfoil.
"""
function thickness(af::Airfoil)
    u = upper(af)[1:end-1, :]
    l = lower(af)[end:-1:1, :]

    # calculate distance between u and l 
    d = u .- l
    d = sqrt.(d[:, 1] .^ 2 .+ d[:, 2] .^ 2)
    return d
end

"""
    thickness_max(af::Airfoil)
"""
function thickness_max(af::Airfoil)
    return maximum(thickness(af))
end

"""
    thickness_TE(af::Airfoil)

Calculate the thickness at the trailing edge of an airfoil.
"""
function thickness_TE(af::Airfoil)
    return thickness(af)[1]
end

""" 
    data(af::Airfoil)

Return the data of an airfoil as a matrix with two columns, the first one 
being the x coordinates and the second one the y coordinates.
"""
function data(af::Airfoil)
    return [af.x af.y]
end


# function refine!(af::Airfoil, n::Int; order=2)
#     l = lower(af)
#     u = upper(af)

#     # raise error if n is even 
#     if n % 2 == 0
#         error("n must be odd!")
#     end

#     n_half = n ÷ 2

#     # interpolate lower and upper
#     l_extended = vcat(reshape(u[end,:], 1, 2), l)
#     x_int_l = _cosspacing(0, 1, n_half + 1)
#     l_int = akima(l_extended[:, 1], l_extended[:, 2], x_int_l)

#     # interpolate upper
#     x_int_u = _cosspacing(1, 0, n_half + 1)
#     u_int = akima(u[:, 1], u[:, 2], x_int_u)

#     # remove first point from l_int 
#     x_int_l = x_int_l[2:end]
#     l_int = l_int[2:end, :]

#     # vcat u_int and l_int 
#     af.x = vcat(u_int[:, 1], l_int[:, 1])
#     af.y = vcat(u_int[:, 2], l_int[:, 2])
# end

# function _cosspacing(x_start, x_end, n; m=π, coeff=1)
#     x = Vector(LinRange(m, 0, n))
#     cosspacing = cos.(x)
#     s = ((cosspacing .+ 1) / 2 .- x / π) .* coeff .+ x / π
#     return s .* (x_end - x_start) .+ x_start
# end

"""
    interpolate(list_af::Vector{Airfoil}, s::Vector, s_int::Vector)

Interpolate an airfoil at span `s_int` using the span `s` as reference.
"""
function interpolate_airfoils(list_af::Vector{Airfoil}, s::Vector, s_int::Vector)
    n = length(s)
    n_int = length(s_int)

    lenghts_af = length.(list_af)
    #check if lengths_af are all equal 
    n_af = 0
    if all(lenghts_af .== lenghts_af[1])
        n_af = lenghts_af[1]
    else
        error("Airfoils must have the same number of points!")
    end


    data = zeros(n, n_af, 2)
    for i = 1:n
        data[i, :, 1] = list_af[i].x
        data[i, :, 2] = list_af[i].y
    end

    data_int = zeros(n_int, n_af, 2)
    for i in 1:n_af
        data_int[:, i, 1] = akima(s, data[:, i, 1], s_int)
        data_int[:, i, 2] = akima(s, data[:, i, 2], s_int)
    end

    list_af_int = Vector{Airfoil}(undef, n_int)
    for i = 1:n_int
        af = Airfoil(data_int[i, :, 1], data_int[i, :, 2], f"Interpolation {i}")
        list_af_int[i] = af
    end

    return list_af_int
end

function _upper_lower_split(af::Airfoil)

    le = LE(af)

    # find point index of LE 
    i_LE = 0
    for i = 1:length(af)
        if af.x[i] == le[1] && af.y[i] == le[2]
            i_LE = i
            break
        end
    end

    d = data(af)
    upper = d[1:i_LE, :]
    lower = d[i_LE+1:end, :]
    return upper, lower
end

"""
    upper(af::Airfoil)

Return the upper pts of an airfoil.
"""
function upper(af::Airfoil)
    return _upper_lower_split(af)[1]
end

"""
    lower(af::Airfoil)

Return the lower pts of an airfoil.
"""
function lower(af::Airfoil)
    return _upper_lower_split(af)[2]
end

"""
    TE(af::Airfoil)

Return the trailing edge of an airfoil.
"""
function TE(af::Airfoil)
    return [af.x[1], af.y[1]]
end

"""
    LE(af::Airfoil)

Return the leading edge of an airfoil.
"""
function LE(af::Airfoil)
    # find point furthert away from TE in distance 
    d = data(af)

    # convert TE(af) to 1x2 matrix 
    te = reshape(TE(af), (1, 2))

    d_TE = d .- te
    d_TE = sqrt.(d_TE[:, 1] .^ 2 .+ d_TE[:, 2] .^ 2)
    i_LE = argmax(d_TE)
    return [d[i_LE, 1], d[i_LE, 2]]
end

"""
    camberline(af::Airfoil)

Return the camberline of an airfoil.
"""
function camberline(af::Airfoil)
    u = upper(af)[1:end-1, :]
    l = lower(af)
    l = l[end:-1:1, :]
    return (u .+ l) / 2
end

function _arclength(pts)
    n = size(pts)[1]
    println(n)
    println(size(pts))
    s = 0.0
    for i = 2:n
        s += sqrt(
            (pts[i, 1] - pts[i-1, 1])^2 +
            (pts[i, 2] - pts[i-1, 2])^2
        )
    end
    return s
end

function camberlength(af::Airfoil)
    return _arclength(camberline(af))
end

function chordlength(af::Airfoil)
    te = TE(af)
    le = LE(af)
    return sqrt((te[1] - le[1])^2 + (te[2] - le[2])^2)
end

"""
    _figure_sizing(af::Airfoil)

Calculate the figure size for a plot of an airfoil.
"""
function _figure_sizing(af)
    # Figure Sizing
    fct_size = 1.0 / abs(maximum(af.y) - minimum(af.y))
    width = 18 / 2.54
    if fct_size > 5
        space = 1
    else
        space = 0.5
    end
    height = width / fct_size + min(1, space)
    return width, height
end

function plot(af::Airfoil; fname=nothing, dpi=300, legend=false)

    pplt = pyimport("proplot")
    fig, ax = pplt.subplots(figsize=_figure_sizing(af))

    u = upper(af)
    l = lower(af)
    c = camberline(af)

    ax[1].plot(u[:, 1], u[:, 2], ".-", lw=1, c="tab:red", s=2, label="upper")
    ax[1].plot(l[:, 1], l[:, 2], ".-", lw=1, c="tab:blue", s=2, label="lower")
    ax[1].plot(c[:, 1], c[:, 2], "--", lw=0.5, c="tab:green", label="camber")

    ax[1].set(
        aspect="equal",
        xlabel=L"$x$",
        ylabel=L"$y$",
        title=af.name,
        xlim=[minimum(af.x) - 0.01, maximum(af.x) + 0.01],
    )

    if legend
        ax[1].legend(ncol=1)
    end


    if fname !== nothing
        savefig(fname, dpi=dpi)
    end

    return fig
end

function Base.:+(af1::Airfoil, af2::Airfoil)
    x = (af1.x .+ af2.x) / 2
    y = (af1.y .+ af2.y) / 2
    return Airfoil(x, y, "Mean Airfoil")
end

"""
    plot_airfoils(list_airfoils::Vector{Airfoil}; dpi=300, fname=nothing, legend=true)

Plot a list of airfoils.
"""
function plot_airfoils(list_airfoils::Vector{Airfoil}; dpi=300, fname=nothing, legend=true)
    pplt = pyimport("proplot")

    width = 0.0
    height = 0.0
    for af in list_airfoils
        width_new, height_new = _figure_sizing(af)
        width = max(width, width_new)
        height = max(height, height_new)
    end

    fig, ax = pplt.subplots(figsize=(width, height))
    for af in list_airfoils
        ax[1].plot(af.x, af.y, "-", lw=1, label=af.name)
    end

    xmax = maximum([maximum(af.x) for af in list_airfoils])
    xmin = minimum([minimum(af.x) for af in list_airfoils])

    ax[1].set(
        aspect="equal",
        xlabel=L"$x$",
        ylabel=L"$y$",
        xlim=[xmin - 0.01, xmax + 0.01],
    )


    if legend
        ax[1].legend(ncol=1)
    end
    if fname !== nothing
        savefig(fname, dpi=dpi)
    end
    return fig
end

function save(af::Airfoil, fname)
    ext = fname_extension(fname)

    if ext == "dat"
        f = open(fname, "w")
        println(f, af.name)
        for i = 1:length(af)
            println(f, af.x[i], " ", af.y[i])
        end
        close(f)
    elseif ext == "csv"
        df = DataFrame(x=af.x, y=af.y, name=af.name)
        CSV.write(fname, df)
    end
end 
"""
    save_dust(af::Airfoil, fname)

Saves the airfoil for the dust solver.

The curve must start at the TE, pass from the lower side of the airfoil, the LE, 
the upper side and end again at the TE. The first and last point can be not 
coinciding, to generate an open TE. 
"""
function save_dust(af::Airfoil, fname)
    x = reverse(af.x)
    y = reverse(af.y)
    
    f = open(fname, "w")
        println(f, length(af))
        for i = 1:length(af)
            println(f, x[i], " ", y[i])
        end
    close(f)
end


end
