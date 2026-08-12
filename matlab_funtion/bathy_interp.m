function grd_struct = bathy_interp(topo, grd_struct, path_figure)

    %% 1. Flatten source into scattered points -- works regardless of
    %%    whether topo.lon/lat are regular, curvilinear, or rotated
    lon_src = topo.lon(:);
    lat_src = topo.lat(:);
    z_src   = topo.Z(:);
 
    %% 2. Drop any NaNs (scatteredInterpolant doesn't like them in input)
    good = ~isnan(lon_src) & ~isnan(lat_src) & ~isnan(z_src);
    lon_src = lon_src(good);
    lat_src = lat_src(good);
    z_src   = z_src(good);
 
    %% 3. (Optional but recommended for speed) crop source to a bounding
    %%    box around your target grid, with margin -- avoids triangulating
    %%    far more points than necessary
    margin = 0.5;   % degrees
    lon_range = [min(grd_struct.lone_deg(:))-margin, max(grd_struct.lone_deg(:))+margin];
    lat_range = [min(grd_struct.late_deg(:))-margin, max(grd_struct.late_deg(:))+margin];
 
    keep = lon_src >= lon_range(1) & lon_src <= lon_range(2) & ...
           lat_src >= lat_range(1) & lat_src <= lat_range(2);
    lon_src = lon_src(keep);
    lat_src = lat_src(keep);
    z_src   = z_src(keep);
 
    fprintf('Building interpolant from %d source points...\n', numel(lon_src))
 
    %% 4. Build scattered interpolant (triangulation-based, handles
    %%    arbitrary/rotated source point layout)
    F = scatteredInterpolant(lon_src, lat_src, z_src, 'linear', 'none');
 
    %% 5. Query at your target grid points (any shape -- rotated, 2D, etc.)
    grd_struct.bath4 = F(grd_struct.lon4_deg, grd_struct.lat4_deg);
    grd_struct.bathe = F(grd_struct.lone_deg, grd_struct.late_deg);
 
    %% quick sanity check
    n_nan = sum(isnan(grd_struct.bath4(:)));
    if n_nan > 0
       fprintf('Warning: %d NaN points after interpolation (out of source coverage?)\n', n_nan)
    else
       disp('No NaNs -- interpolation covers full target grid.')
    end
 
 end