clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

%% ------------------------------------------------------------------
%  Run identifiers
%  ------------------------------------------------------------------
par_name  = '2022082200';
grid_reso = 300;                   % child grid resolution (m) -- 300 or 100

chd_grd_name = ['roms_grd_', num2str(grid_reso), 'm.nc'];

%% ------------------------------------------------------------------
%  Paths
%  ------------------------------------------------------------------
data_path            = ['/home/mbui/ModelOutput/NCOM/data/', par_name, '/'];
parent_grid_path     = '/home/mbui/ModelOutput/NCOM/grid/';
child_grid_path      = '/home/hsinyi/roms_data/grid/';
initial_output_path  = '/home/hsinyi/roms_data/ini/';
initial_file_read    = '/home/hsinyi/roms_data/bry/bry_read_nc/';

%% ------------------------------------------------------------------
%  Read grids
%  ------------------------------------------------------------------
parent_grid = read_nc_fun([parent_grid_path, 'ohgrd_2.nc']);
child_grid  = read_nc_fun([child_grid_path, chd_grd_name]);
% NOTE: child_grid is loaded but not referenced again below.
% If read_nc_fun loads full 3D fields, this is an expensive read for a
% 2050x2562x268 grid with no downstream use in THIS script.
% Confirm whether it's needed, otherwise consider removing this line.

par_N    = size(parent_grid.zm3, 3);   % number of parent vertical levels
par_tind = 1;                          % frame number in parent file

%% ------------------------------------------------------------------
%  Parent data filenames (built from par_name)
%  ------------------------------------------------------------------
par_grd = [par_name, '_lthick.nc'];
parinie = [par_name, '_ssh.nc'];
parinit = [par_name, '_ts.nc'];
pariniu = [par_name, '_uv.nc'];

%% ------------------------------------------------------------------
%  Child grid / vertical coordinate parameters
%  ------------------------------------------------------------------
% REMOVED (duplicate + bug): this line re-derived chd_grd_name using
% grid_reso(grid_num), but grid_reso is a scalar and grid_num is
% undefined -- leftover from a multi-resolution loop version.
% chd_grd_name = ['roms_grd_', num2str(grid_reso(grid_num)), 'm.nc'];

chd_thetas = 6;
chd_thetab = 0.75;
chd_hc     = 10;

if grid_reso == 300
    chd_N = 128;   % 128 levels for 300 m grid
elseif grid_reso == 100
    chd_N = 192;   % 192 levels for 100 m grid
else
    error('bry_make.m : not known vertical grid layer number')
end

chd_ang   = 'rad';
chdscoord = 'new2008';     % child 'new' or 'old' type scoord

%% ------------------------------------------------------------------
%  Pack s-coordinate params
%  ------------------------------------------------------------------
chdscd.N       = chd_N;
chdscd.theta_s = chd_thetas;
chdscd.theta_b = chd_thetab;
chdscd.hc      = chd_hc;
par.N          = par_N;

%% ------------------------------------------------------------------
%  Number of chunks (domain decomposition for memory management)
%  Child grid ~2050x2562x268 -> chunking needed to avoid OOM.
%  ------------------------------------------------------------------
ndomx = 4;
ndomy = 3;

%% ------------------------------------------------------------------
%  Full file paths
%  ------------------------------------------------------------------
ini_filename = ['roms_ini_', num2str(grid_reso), 'm.nc'];

parent_UV = [initial_file_read, pariniu];
parent_TS = [initial_file_read, parinit];
parent_E  = [initial_file_read, parinie];
parent_G  = [initial_file_read, par_grd];

chdgrd = [child_grid_path, chd_grd_name];
chdini = [initial_output_path, ini_filename];
% REMOVED (duplicate): chdgrd was assigned a second time here with the
% identical expression -- harmless but redundant, kept once above.
% chdgrd  = [child_grid_path ,chd_grd_name];

%% ------------------------------------------------------------------
%  Create and fill initial file
%  ------------------------------------------------------------------
disp(['>>> Creating initial file: ' chdini]);
h2r_create_ini(chdini, chdgrd, chd_N, chdscd, 'clobber')

h2r_make_ini(parent_G, par_tind, parent_UV, parent_UV, parent_TS, parent_TS, ...
    parent_E, chdgrd, chdini, chdscd, chdscoord, ndomx, ndomy, chd_ang, par.N)

ini_check = read_nc_fun(chdini);