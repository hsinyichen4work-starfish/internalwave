function [par_grd] = make_bry_need_grid(hgrd2,vgrd2,par_name,boundary_path)

    [jgrd, igrd]  = size(hgrd2.lon);
    lo            = size(vgrd2, 3) - 1;          % number of layers (interfaces - 1)

    %% Compute layer thickness (positive-valued) from interface depths
    dz = -diff(vgrd2, 1, 3);                     % (jgrd, igrd, lo), positive down-to-up diff

    % Sanity check: thickness should be positive everywhere in the ocean
    if any(dz(:) < 0)
        warning('Negative layer thickness found -- check vgrd2 sign convention/masking before proceeding.');
    end

    %% Transpose everything to (igrd, jgrd, ...) -- the order h2r_bry_hv.m expects
    lon_xy = hgrd2.lon';                          % (igrd, jgrd)
    lat_xy = hgrd2.lat';                          % (igrd, jgrd)
    dz_xy  = permute(dz, [2 1 3]);                % (igrd, jgrd, lo)

    cd(boundary_path)

    %% Set up the par_grd NetCDF file
    par_grd = [par_name, '_lthick.nc'];
    if isfile(par_grd)
        delete(par_grd);   % nccreate errors if the variable/file already exists
    end

    % NOTE: layer_thickness is read by h2r_bry_hv.m as a 4D field
    % ncread(par_grd,'layer_thickness',[imin jmin 1 tind],[li lj Np 1])
    % so it needs an explicit time dimension, even if you only have one
    % (or a few) time slices right now. Use an unlimited time dim so you
    % can append more forecast hours later without recreating the file.

    nccreate(par_grd, 'Longitude', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd}, ...
        'Datatype', 'double');
    nccreate(par_grd, 'Latitude', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd}, ...
        'Datatype', 'double');
    nccreate(par_grd, 'layer_thickness', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'z', lo, 'time', Inf}, ...
        'Datatype', 'double');

    ncwrite(par_grd, 'Longitude', lon_xy);
    ncwrite(par_grd, 'Latitude',  lat_xy);

    % Write the static layer thickness at the first time index.
    % If your near-surface layers are true sigma (thickness varies with
    % instantaneous SSH), you'll eventually want a per-forecast-hour
    % layer_thickness here instead of reusing this static reference at
    % every time index -- see earlier discussion on the sigma-vs-z caveat.
    ncwrite(par_grd, 'layer_thickness', dz_xy, [1 1 1 1]);

    disp(['Wrote grid file: ' par_grd]);
end