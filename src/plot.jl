

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

# function plot(af::Airfoil; fname=nothing, dpi=300, legend=false)

#     pplt = pyimport("proplot")
#     fig, ax = pplt.subplots(figsize=_figure_sizing(af))

#     u = upper(af)
#     l = lower(af)
#     c = camberline(af)

#     ax[1].plot(u[:, 1], u[:, 2], ".-", lw=1, c="tab:red", s=2, label="upper")
#     ax[1].plot(l[:, 1], l[:, 2], ".-", lw=1, c="tab:blue", s=2, label="lower")
#     ax[1].plot(c[:, 1], c[:, 2], "--", lw=0.5, c="tab:green", label="camber")

#     center = centroid(af)
#     ax[1].plot(center[1], center[2], "x", c="k")

#     ax[1].set(
#         aspect="equal",
#         xlabel=L"$x$",
#         ylabel=L"$y$",
#         title=af.name,
#         xlim=[minimum(af.x) - 0.01, maximum(af.x) + 0.01],
#     )

#     if legend
#         ax[1].legend(ncol=1)
#     end


#     if fname !== nothing
#         savefig(fname, dpi=dpi)
#     end

#     return fig
# end


# function plot(list_airfoils::Vector{Airfoil}; dpi=300, fname=nothing, legend=true)
#     pplt = pyimport("proplot")

#     width = 0.0
#     height = 0.0
#     for af in list_airfoils
#         width_new, height_new = _figure_sizing(af)
#         width = max(width, width_new)
#         height = max(height, height_new)
#     end

#     fig, ax = pplt.subplots(figsize=(width, height))
#     for af in list_airfoils
#         ax[1].plot(af.x, af.y, "-", lw=1, label=af.name)
#     end

#     xmax = maximum([maximum(af.x) for af in list_airfoils])
#     xmin = minimum([minimum(af.x) for af in list_airfoils])

#     ax[1].set(
#         aspect="equal",
#         xlabel=L"$x$",
#         ylabel=L"$y$",
#         xlim=[xmin - 0.01, xmax + 0.01],
#     )


#     if legend
#         ax[1].legend(ncol=1)
#     end
#     if fname !== nothing
#         savefig(fname, dpi=dpi)
#     end
#     return fig
# end



# function plot(airfoil::Airfoil; fname=nothing, px_per_unit=2, legend=false)
#     f = Figure(size=_figure_sizing(airfoil) .* 150)

#     ax = Axis(
#         f[1, 1],
#         xlabel="x",
#         ylabel="y",
#         title=airfoil.name,
#         subtitle=string(length(airfoil)),
#         aspect=DataAspect(),
#     )

#     xlims!(ax, low=minimum(airfoil.x) - 0.01, high=maximum(airfoil.x) + 0.01)

#     u = upper(airfoil)
#     l = lower(airfoil)
#     c = camberline(airfoil)
#     center = centroid(airfoil)

#     lines!(ax, u[:, 1], u[:, 2], linewidth=1, linestyle=:solid, label="upper")
#     lines!(ax, l[:, 1], l[:, 2], linewidth=1, linestyle=:solid, label="lower")
#     lines!(ax, c[:, 1], c[:, 2], linewidth=1, linestyle=:dash, label="camber")
#     scatter!(ax, center[1], center[2], color=:black, markersize=10, label="centroid")

#     if legend
#         axislegend()
#     end

#     if fname !== nothing
#         CairoMakie.save(fname, f; px_per_unit=px_per_unit)
#     end
#     return f
# end

# """
#     plot_airfoils(list_airfoils::Vector{Airfoil}; dpi=300, fname=nothing, legend=true)

# Plot a list of airfoils.
# """
# function plot(airfoils::Vector{Airfoil}; px_per_unit=2, fname=nothing, legend=true)

#     width = 0.0
#     height = 0.0
#     for airfoil in airfoils
#         width_new, height_new = _figure_sizing(airfoil)
#         width = max(width, width_new)
#         height = max(height, height_new)
#     end

#     f = Figure(size=(width, height) .* 150)

#     ax = Axis(
#         f[1, 1],
#         xlabel="x",
#         ylabel="y",
#         aspect=DataAspect(),
#     )

#     xmax = maximum([maximum(af.x) for af in airfoils])
#     xmin = minimum([minimum(af.x) for af in airfoils])

#     xlims!(ax, low=xmin - 0.01, high=xmax + 0.01)


#     for airfoil in airfoils
#         lines!(ax, airfoil.x, airfoil.y, linewidth=1, label=airfoil.name)
#     end

#     if legend
#         axislegend()
#     end


#     if fname !== nothing
#         CairoMakie.save(fname, f; px_per_unit=px_per_unit)
#     end
#     return f
# end


function plot(airfoil::Airfoil; fname=nothing, dpi=300, legend=false)
    u = upper(airfoil)
    l = lower(airfoil)
    c = camberline(airfoil)
    center = centroid(airfoil)

    p = Plots.plot(
        layout=(1, 1),
        size=_figure_sizing(airfoil) .* 80,
        dpi=dpi,
        title=airfoil.name,
        titlefontsize=10,
        aspect_ratio=:equal
    )

    plot!(p, u[:, 1], u[:, 2], linewidth=1, linestyle=:solid, label="upper", legend=legend)
    plot!(p, l[:, 1], l[:, 2], linewidth=1, linestyle=:solid, label="lower", legend=legend)
    plot!(p, c[:, 1], c[:, 2], linewidth=1, linestyle=:dash, label="camber", legend=legend)
    scatter!(p, [center[1]], [center[2]], color=:black, label="centroid", legend=legend, ms=4, marker=:cross)

    xlims!(p, minimum(airfoil.x) - 0.01, maximum(airfoil.x) + 0.01)

    if fname !== nothing
        savefig(p, fname)
    end

    return p
end

function plot(airfoils::Vector{Airfoil}; fname=nothing, dpi=300, legend=false)
    width = 0.0
    height = 0.0
    for airfoil in airfoils
        width_new, height_new = _figure_sizing(airfoil)
        width = max(width, width_new)
        height = max(height, height_new)
    end
    
    p = Plots.plot(
        layout=(1, 1),
        size= (width, height) .* 80,
        dpi=dpi,
        titlefontsize=10,
        aspect_ratio=:equal
    )

    for af in airfoils  
        plot!(p, af.x, af.y, linewidth=1, linestyle=:solid, label=af.name, legend=legend)
    end

    xmax = maximum([maximum(af.x) for af in airfoils])
    xmin = minimum([minimum(af.x) for af in airfoils])
    xlims!(p, xmin - 0.01, xmax + 0.01)

    if fname !== nothing
        savefig(p, fname)
    end

    return p
end