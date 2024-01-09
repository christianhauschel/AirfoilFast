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


"""
    scale(af::Airfoil, new_chord; LE_origin::Vector=true)

Scale an airfoil to a new chord length `new_chord`. If `LE_origin` is true, the
leading edge is used as origin, otherwise the origin is [0, 0].
"""
function scale!(af::Airfoil, scaling; LE_origin::Bool=true)
    if LE_origin
        le = LE(af)
    else
        le = [0, 0]
    end
    af.x = (af.x .- le[1]) * scaling .+ le[1]
    af.y = (af.y .- le[2]) * scaling .+ le[2]
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
Calculates the centroid of an airfoil.

# References 
https://en.wikipedia.org/wiki/Centroid#Of_a_polygon
"""
function centroid(af::Airfoil)::Vector
    points = data(af)
    n = length(af)
    A = area(af)

    cx = 0
    cy = 0
    for i = 1:n-1
        cx += (points[i, 1] + points[i+1, 1]) * (points[i, 1] * points[i+1, 2] - points[i+1, 1] * points[i, 2])
        cy += (points[i, 2] + points[i+1, 2]) * (points[i, 1] * points[i+1, 2] - points[i+1, 1] * points[i, 2])
    end
    cx /= (6 * A)
    cy /= (6 * A)
    return [cx, cy]
end