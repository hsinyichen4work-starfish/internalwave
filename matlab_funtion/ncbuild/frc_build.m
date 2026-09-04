%% ------------------------------------------------------------------
%  Paths
%  ------------------------------------------------------------------
data_path =[parent_data_path,par_name,'/'];
par_N    = size(pgrid.zm3, 3);   % number of parent vertical levels
frcname = [forcing_path,frc_filename];
h2r_create_frc(frcname,[grid_path,grd_name,'.nc']);
frc_nc  = read_nc_fun(frcname);

% make data nc file that can be read in forcing file
remake = false;
[par_grd,parinis,pariniw,parinip] = make_frc_need_nc(par_name,nc_path_frc,remake);

parent_FLUX = [nc_path_frc, parinis];
parent_WIND = [nc_path_frc, pariniw];
parent_PRESS  = [nc_path_frc, parinip];
parent_G  = [nc_path_frc, par_grd];

% Once, regardless of how many dates/time steps you process:
chdgrd     = [grid_path,grd_name,'.nc'];
limits = h2r_frc_subgrid(parent_G, chdgrd, ndomx, ndomy);

% Then per date/par_name:
h2r_make_frc(parent_G, parent_FLUX, parent_WIND, parent_PRESS, ...
        chdgrd, frcname, chd_ang, limits);

