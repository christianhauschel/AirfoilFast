using AirfoilFast

af = Airfoil("data/NACA4408.dat")


plot(af)
chordlength(af)
camberlength(af)

af1 = Airfoil("data/NACA0012.dat")

afs_int = interpolate_airfoils([af, af1, af1], [0., 0.5, 1.0], Vector(LinRange(0, 1, 10)))

normalize!(af1)
save_dust(af1, "test.dat")

# save.(afs_int, [joinpath("data", af.name * ".dat") for af in afs_int])