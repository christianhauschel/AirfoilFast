using AirfoilFast

af1 = Airfoil("data/NACA4408.dat")
af2 = Airfoil("data/NACA4412.dat")

chordlength(af1)
camberlength(af1)

normalize!(af2)


plot(af2)

afs_int = interpolate_airfoils([af1, af2, af2], [0.0, 0.5, 1.0], Vector(LinRange(0, 1, 4)))

plot(afs_int; legend=false)

af1_scaled = scale(af1, 0.5)

plot(af1_scaled)
