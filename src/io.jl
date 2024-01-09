function fname_extension(fname)
    return split(fname, ".")[end]
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