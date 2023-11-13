using AirfoilFast

af = Airfoil("data/NACA4408.dat")
plot(af)
chordlength(af)
camberlength(af)

af1 = Airfoil("data/NACA0012.dat")

afs_int = interpolate_airfoils([af, af1, af1], [0., 0.5, 1.0], Vector(LinRange(0, 1, 10)))

plot_airfoils(afs_int)