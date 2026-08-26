clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
mid_iter = 2; dx = 900; nx = 684; ny = 854; % 900 m
smooth_var.rmax = 0.2; smooth_var.hmin = 2; smooth_var.offset = 2.2;
parent_datatype = "NCOM"; % "NCOM" OR "ROMS"

chd_thetas = 6; chd_thetab = 0.75; chd_hc = 10; chd_N = 128;
chd_ang   = 'rad'; chdscoord = 'new2008';     % child 'new' or 'old' type scoord
ndomx = 2; ndomy = 2; %-> chunking needed to avoid OOM.

dating = datenum("20220822","yyyymmdd") : datenum("20220823","yyyymmdd");
%% path settings
parent_grid = '/home/mbui/ModelOutput/NCOM/grid/ohgrd_2.nc';
parent_data_path = '/home/mbui/ModelOutput/NCOM/data/';
par_name = '2022082200'; ini_par_path  = [parent_data_path,par_name]; 
nc_path_ini_bry = '/home/hsinyi/roms_data/bry/bry_read_nc/';
nc_path_frc = '/home/hsinyi/roms_data/frc/frc_read_nc/';

path_figure='/home/hsinyi/figure/20260826_900_test/'; 
grid_path = '/home/hsinyi/roms_data/grid/';
initial_path  = '/home/hsinyi/roms_data/ini/';
boundary_path = '/home/hsinyi/roms_data/bry/';
forcing_path = '/home/hsinyi/roms_data/frc/';

bath_path='/home/hsinyi/data_notm/'; 

%% name settings
grd_name = ['roms_grd_',num2str(dx),'m'];
ini_name = ['roms_ini_',num2str(dx),'m.nc'];
%% grid build
pgrid = read_nc_fun(parent_grid);
pgrid = standardize_name(pgrid);
grd_build
child_grid  = read_nc_fun([grid_path, grd_name,'.nc']);
%% initial build
ini_build
child_ini = read_nc_fun([initial_path, ini_name]);

%% boundary build
fod = string(datestr(dating,"yyyymmddHH"));
bry_build
child_bry = read_nc_fun([boundary_path, bry_filename]);

%% forcing build
frc_build
child_frc = read_nc_fun([forcing_path, frc_filename]);