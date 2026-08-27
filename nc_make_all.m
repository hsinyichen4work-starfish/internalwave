clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
mid_iter = 2; dx = 900; nx = 684; ny = 854; % 900 m
smooth_var.rmax = 0.2; smooth_var.hmin = 2; smooth_var.offset = 2.2;
parent_datatype = "NCOM"; % "NCOM" OR "ROMS"

chd_thetas = 6; chd_thetab = 0.75; chd_hc = 10; chd_N = 128;
chd_ang   = 'rad'; chdscoord = 'new2008';     % child 'new' or 'old' type scoord
ndomx = 2; ndomy = 2; %-> chunking needed to avoid OOM.

dating = datenum("20220825","yyyymmdd") : datenum("20221127","yyyymmdd");
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
if ~isfile([grid_path, grd_name,'.nc'])
    grd_build
end
child_grid  = read_nc_fun([grid_path, grd_name,'.nc']);
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