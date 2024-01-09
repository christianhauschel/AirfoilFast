"""
    Airfoil(x, y, name)

Create an airfoil from the coordinates `x` and `y` and the name `name`.
"""
mutable struct Airfoil
    x
    y
    name
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

function Base.copy(af::Airfoil)
    return Airfoil(af.x, af.y, af.name)
end



""" 
    data(af::Airfoil)

Return the data of an airfoil as a matrix with two columns, the first one 
being the x coordinates and the second one the y coordinates.
"""
function data(af::Airfoil)
    return [af.x af.y]
end


function Base.:+(af1::Airfoil, af2::Airfoil)
    x = (af1.x .+ af2.x) / 2
    y = (af1.y .+ af2.y) / 2
    return Airfoil(x, y, "Mean Airfoil")
end