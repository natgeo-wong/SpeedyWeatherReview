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
# Test 03: Gravity Waves on a Sphere
"

# ╔═╡ 8bf707c4-9831-4adf-8892-02ca7433b893
spectral_grid = SpectralGrid(trunc=127,nlev=1)

# ╔═╡ db20adf7-76f8-4620-9477-da1dca6e03f4
time_stepping = SpeedyWeather.Leapfrog(spectral_grid,Δt_at_T31=Minute(30))

# ╔═╡ 438d672d-9afe-4454-bd06-ea994528bf8f
implicit = SpeedyWeather.ImplicitShallowWater(spectral_grid,α=0.5)

# ╔═╡ f1aa3ffc-d245-41ce-8674-12c4a3e8ab74
orography = EarthOrography(spectral_grid,smoothing=false)

# ╔═╡ 6424403f-d325-4b45-bb79-2d0574214d3e
initial_conditions = SpeedyWeather.RandomWaves()

# ╔═╡ f813e750-2ebb-47ff-a4f8-c8906d338fa0
output = OutputWriter(
	spectral_grid, ShallowWaterModel, path=datadir("gravitywavessphere"), 
	output_dt=Minute(15), output_vars=[:u,:pres,:div,:orography]
)

# ╔═╡ 825b69c9-b60a-4da6-ac08-4065e6f7e2d7
model = ShallowWaterModel(;spectral_grid,orography,output,initial_conditions,implicit,time_stepping)

# ╔═╡ 569d0dc0-c1a2-4eea-8856-d00531aaa0d4
simulation = initialize!(model)

# ╔═╡ 97461d5c-3a66-4244-a257-3ed9ad57ca11
md"Run Model and Make Animation: $(@bind makeanim Slider(0:1, default=0))"

# ╔═╡ fbf01408-a12d-4a43-b3ee-37cc0a65978e
# ╠═╡ show_logs = false
begin
	if isone(makeanim)
		rm(datadir("gravitywavessphere","run_0001"),recursive=true,force=true)
		run!(simulation,period=Day(5),output=true);
		md"Running model ..."
		
		ds = NCDataset(datadir("gravitywavessphere","run_0001","output.nc"))
		lon = ds["lon"][:]
		lat = ds["lat"][:]
		dt  = ds["time"][:]; nt = length(dt)
		∇   = nomissing(ds["div"][:,:,1,:],NaN) * 86400
		close(ds)
		
		mkpath(plotsdir("gravitywavessphere"))
		for it = 1 : nt
			pplt.close()
			fig_1 = pplt.figure()
	        gsp_1 = pplt.GridSpec(ncols=2)
	        axs_1 = fig_1.subplot(gsp_1[1],proj="ortho",proj_kw=Dict("lon_0"=>90))
	        axs_2 = fig_1.subplot(gsp_1[2],proj="ortho",proj_kw=Dict("lon_0"=>280))
			
			c = axs_1.pcolormesh(lon,lat,∇[:,:,it]',levels=vcat(-5:-1,-0.5,0.5,1:5)*2,extend="both")
			axs_2.pcolormesh(lon,lat,∇[:,:,it]',levels=vcat(-5:-1,-0.5,0.5,1:5)*2,extend="both")

			for ax in [axs_1,axs_2]
				ax.format(coast=true)
			end
			
			fig_1.colorbar(c,label=L"$\nabla$ / day$^{-1}$",length=0.8)
			fig_1.savefig(plotsdir("gravitywavessphere","$it.png"),transparent=false,dpi=200)
		end
	else
		ds = NCDataset(datadir("gravitywavessphere","run_0001","output.nc"))
		nt = length(ds["time"][:])
		close(ds)
	end
end

# ╔═╡ ef263226-7b87-4229-abe7-fdcd205ba98b
md"Step: $(@bind tt Slider(1:nt, default=1,show_value=true))"

# ╔═╡ 8673e928-bdd2-4bfc-aeae-071e5f00afd6
PNGFiles.load(plotsdir("gravitywavessphere","$tt.png"))

# ╔═╡ Cell order:
# ╟─aeae15f9-8c01-468f-aae4-85461d144818
# ╟─897697a8-ca9b-11ee-0151-f9f673adc96a
# ╟─e138ca5e-2b9b-4cca-af1c-a7d7da7d8ee9
# ╟─8bf707c4-9831-4adf-8892-02ca7433b893
# ╟─db20adf7-76f8-4620-9477-da1dca6e03f4
# ╟─438d672d-9afe-4454-bd06-ea994528bf8f
# ╟─f1aa3ffc-d245-41ce-8674-12c4a3e8ab74
# ╟─6424403f-d325-4b45-bb79-2d0574214d3e
# ╟─f813e750-2ebb-47ff-a4f8-c8906d338fa0
# ╟─825b69c9-b60a-4da6-ac08-4065e6f7e2d7
# ╟─569d0dc0-c1a2-4eea-8856-d00531aaa0d4
# ╟─97461d5c-3a66-4244-a257-3ed9ad57ca11
# ╟─fbf01408-a12d-4a43-b3ee-37cc0a65978e
# ╟─ef263226-7b87-4229-abe7-fdcd205ba98b
# ╟─8673e928-bdd2-4bfc-aeae-071e5f00afd6
