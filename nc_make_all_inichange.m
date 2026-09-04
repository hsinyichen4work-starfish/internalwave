clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
mid_iter = 2; dx = 900; nx = 684; ny = 854; % 900 m
%mid_iter = 2; dx = 300; nx = 2048; ny = 2560; % 300 m
smooth_var.rmax = 0.15; smooth_var.hmin = 2; smooth_var.offset = 2.2;
parent_datatype = "NCOM"; % "NCOM" OR "ROMS"

chd_thetas = 6; chd_thetab = 3; chd_hc = 250; chd_N = 128;
chd_ang   = 'rad'; chdscoord = 'new2008';     % child 'new' or 'old' type scoord
ndomx = 2; ndomy = 2; %-> chunking needed to avoid OOM.

dating = datenum("20220822","yyyymmdd") : datenum("20221130","yyyymmdd");
%% path settings
parent_grid = '/home/mbui/ModelOutput/NCOM/grid/ohgrd_2.nc';
parent_data_path = '/home/mbui/ModelOutput/NCOM/data/';
par_name = '2022082400'; ini_par_path  = [parent_data_path,par_name]; 
nc_path_ini_bry = '/home/hsinyi/roms_data/NCOM_DATA_NC/';
nc_path_frc = '/home/hsinyi/roms_data/NCOM_DATA_NC/';

path_figure='/home/hsinyi/figure/20260903_300_test/'; 
if ~isfolder(path_figure); mkdir(path_figure); end
grid_path = '/home/hsinyi/roms_data/grid/';
initial_path  = '/home/hsinyi/roms_data/ini_63/';
if ~isfolder(initial_path); mkdir(initial_path); end
boundary_path = '/home/hsinyi/roms_data/bry_63/';
if ~isfolder(boundary_path); mkdir(boundary_path); end
forcing_path = '/home/hsinyi/roms_data/frc/';

bath_path='/home/hsinyi/data_notm/'; 

%% name settings
grd_name = ['roms_grd_',num2str(dx),'m'];
ini_name = ['roms_ini_',num2str(dx),'m',par_name,'.nc'];
%% grid build
pgrid = read_nc_fun(parent_grid);
pgrid = standardize_name(pgrid);
if ~isfile([grid_path, grd_name,'.nc'])
    grd_build
end
child_grid  = read_nc_fun([grid_path, grd_name,'.nc']);
[rx1_max, rx1_field, loc] = compute_rx1(child_grid.h, chd_thetas, chd_thetab, chd_hc, chd_N);
%% initial build
if ~isfile([initial_path, ini_name])
    ini_build
end
child_ini = read_nc_fun([initial_path, ini_name]);
%% boundary  and forcing build
fod = string(datestr(dating,"yyyymmddHH"));
for folder_num = 1 : length(fod)
    par_name = char(fod(folder_num));  
    bry_filename    = ['roms_bry_',num2str(dx),'m_',par_name,'.nc']; % bry filename
    if  ~isfile([boundary_path, bry_filename])
        bry_build
    end
    child_bry = read_nc_fun([boundary_path, bry_filename]);
    frc_filename = ['roms_frc_', num2str(dx), 'm_',par_name,'.nc'];
    if  ~isfile([forcing_path, frc_filename])
        frc_build
    end
    child_frc = read_nc_fun([forcing_path, frc_filename]);
end
