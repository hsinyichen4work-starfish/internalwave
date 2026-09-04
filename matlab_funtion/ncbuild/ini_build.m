
par_N    = size(pgrid.zm3, 3);   % number of parent vertical levels
par_tind = 1;                          % frame number in parent file
remake = false;
[par_grd,parinie,parinit,pariniu] = make_bry_need_nc(par_name,nc_path_ini_bry,remake);

%% ------------------------------------------------------------------
%  Pack s-coordinate params
%  ------------------------------------------------------------------
chdscd.N       = chd_N;
chdscd.theta_s = chd_thetas;
chdscd.theta_b = chd_thetab;
chdscd.hc      = chd_hc;
par.N          = par_N;

%% ------------------------------------------------------------------
%  Full file paths
%  ------------------------------------------------------------------
parent_UV = [nc_path_ini_bry, pariniu];
parent_TS = [nc_path_ini_bry, parinit];
parent_E  = [nc_path_ini_bry, parinie];
parent_G  = [nc_path_ini_bry, par_grd];

chdgrd = [grid_path, grd_name,'.nc'];
chdini = [initial_path, ini_name];
%% ------------------------------------------------------------------
%  Create and fill initial file
%  ------------------------------------------------------------------
disp(['>>> Creating initial file: ' chdini]);
h2r_create_ini(chdini, chdgrd, chd_N, chdscd, 'clobber')
h2r_make_ini(parent_G, par_tind, parent_UV, parent_UV, parent_TS, parent_TS, ...
    parent_E, chdgrd, chdini, chdscd, chdscoord, ndomx, ndomy, chd_ang, par.N)
