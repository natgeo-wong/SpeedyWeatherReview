### A Pluto.jl notebook ###
# v0.19.38

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 897697a8-ca9b-11ee-0151-f9f673adc96a
begin
	using Pkg; Pkg.activate()
	using DrWatson
	md"Using DrWatson to keep all packages consistent"
end

# ╔═╡ e138ca5e-2b9b-4cca-af1c-a7d7da7d8ee9
begin
	@quickactivate "SpeedyWeatherReview"
	using SpeedyWeather
	using NCDatasets
	using PlutoUI
	
	using PNGFiles, ImageShow

	using PyCall, LaTeXStrings
	pplt = pyimport("proplot")
	md"Loading packages from the SpeedyWeatherReview project"
end

# ╔═╡ aeae15f9-8c01-468f-aae4-85461d144818
md"
# Test 04: Jablonowski-Williamson
"

# ╔═╡ 8bf707c4-9831-4adf-8892-02ca7433b893
spectral_grid = SpectralGrid(trunc=31,nlev=8,Grid=FullGaussianGrid,dealiasing=3)

# ╔═╡ f1aa3ffc-d245-41ce-8674-12c4a3e8ab74
orography = ZonalRidge(spectral_grid)

# ╔═╡ 6424403f-d325-4b45-bb79-2d0574214d3e
initial_conditions = ZonalWind()

# ╔═╡ f813e750-2ebb-47ff-a4f8-c8906d338fa0
output = OutputWriter(
	spectral_grid, PrimitiveDryModel, path=datadir("baroclinicwave"), 
	output_dt=Hour(1)
)

# ╔═╡ 825b69c9-b60a-4da6-ac08-4065e6f7e2d7
model = PrimitiveDryModel(;spectral_grid,orography,output,initial_conditions,physics=false)

# ╔═╡ 569d0dc0-c1a2-4eea-8856-d00531aaa0d4
simulation = initialize!(model)

# ╔═╡ 97461d5c-3a66-4244-a257-3ed9ad57ca11
md"Run Model and Make Animation: $(@bind makeanim Slider(0:1, default=0))"

# ╔═╡ fbf01408-a12d-4a43-b3ee-37cc0a65978e
# ╠═╡ show_logs = false
begin
	if isone(makeanim)
		rm(datadir("baroclinicwave","run_0001"),recursive=true,force=true)
		run!(simulation,period=Day(30),output=true);
		md"Running model ..."
		
		ds = NCDataset(datadir("baroclinicwave","run_0001","output.nc"))
		lon = ds["lon"][:]
		lat = ds["lat"][:]
		dt  = ds["time"][:]; nt = length(dt)
		η   = nomissing(ds["vor"][:,:,end,:],NaN) * 86400
		close(ds)
		
		mkpath(plotsdir("baroclinicwave"))
		for it = 1 : nt
			pplt.close()
			fig,axs = pplt.subplots(aspect=1,proj="ortho",proj_kw=Dict("lon_0"=>120,"lat_0"=>45))
			
			c = axs[1].pcolormesh(lon,lat,η[:,:,it]',levels=vcat(-5:-1,-0.5,0.5,1:5),extend="both")
			
			fig.colorbar(c,label=L"$\eta_s$ / day$^{-1}$",length=0.8)
			fig.savefig(plotsdir("baroclinicwave","$it.png"),transparent=false,dpi=200)
		end
	else
		ds = NCDataset(datadir("baroclinicwave","run_0001","output.nc"))
		nt = length(ds["time"][:])
		close(ds)
	end
end

# ╔═╡ ef263226-7b87-4229-abe7-fdcd205ba98b
md"Step: $(@bind tt Slider(1:nt, default=1,show_value=true))"

# ╔═╡ 8673e928-bdd2-4bfc-aeae-071e5f00afd6
PNGFiles.load(plotsdir("baroclinicwave","$tt.png"))

# ╔═╡ Cell order:
# ╟─aeae15f9-8c01-468f-aae4-85461d144818
# ╟─897697a8-ca9b-11ee-0151-f9f673adc96a
# ╟─e138ca5e-2b9b-4cca-af1c-a7d7da7d8ee9
# ╠═8bf707c4-9831-4adf-8892-02ca7433b893
# ╠═f1aa3ffc-d245-41ce-8674-12c4a3e8ab74
# ╠═6424403f-d325-4b45-bb79-2d0574214d3e
# ╠═f813e750-2ebb-47ff-a4f8-c8906d338fa0
# ╠═825b69c9-b60a-4da6-ac08-4065e6f7e2d7
# ╟─569d0dc0-c1a2-4eea-8856-d00531aaa0d4
# ╟─97461d5c-3a66-4244-a257-3ed9ad57ca11
# ╟─fbf01408-a12d-4a43-b3ee-37cc0a65978e
# ╟─ef263226-7b87-4229-abe7-fdcd205ba98b
# ╟─8673e928-bdd2-4bfc-aeae-071e5f00afd6
