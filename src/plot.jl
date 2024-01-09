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

    center = centroid(af)
    ax[1].plot(center[1], center[2], "x", c="k")

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