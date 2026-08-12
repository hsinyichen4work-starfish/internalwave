clear; clc;

addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

path_setup='/home/mbui/ModelOutput/NCOM/grid/'; 
path_figure='/home/hsinyi/figure/20260803_grid_test/'; 
mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring/';
file_save_path = '/home/hsinyi/matlab_file/grid_saving/';
grid_path = "/home/hsinyi/roms_data/grid/";
bath_path='/home/hsinyi/data_notm/'; 

%% setting vars
mid_iter = 2; 

dx_100 = 100; nx_100 = 2304; ny_100 = 6144; % 100 m
dx_300 = 300; nx_300 = 2048; ny_300 = 2560; % 300 m

smooth_var.rmax = 0.2; smooth_var.hmin = 2; smooth_var.offset = 2.2;

%% bathymetry interpolation
cd(bath_path)
filelist = {'get_srtm15_NW.txt','get_srtm15_NE.txt', ...
            'get_srtm15_SW.txt','get_srtm15_SE.txt'};
[topo.lon, topo.lat, topo.Z] = read_srtm15_tiles(filelist);

%% 
[mid,rot_ang] = NCOM_grid_plot(mid_iter,path_figure);

[grd_100m,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx_100,nx_100,ny_100);
disp(append("100m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
                ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)))
[grd_100m] = bathy_interp(topo,grd_100m,path_figure);
grd_100m_nc = make_roms_ncgrid(grd_100m,'roms_grd_100m',...
    mid,rot_ang,dx_100,nx_100,ny_100,smooth_var,grid_path);

[grd_300m,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx_300,nx_300,ny_300);
disp(append("300m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
    ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)))
[grd_300m] = bathy_interp(topo,grd_300m,path_figure);
grd_300m_nc = make_roms_ncgrid(grd_300m,'roms_grd_300m',...
    mid,rot_ang,dx_300,nx_300,ny_300,smooth_var,grid_path);

cd(file_save_path);
save("roms_grid_bath_interp","grd_100m","grd_300m");

% parent_roms_region_plot(path_figure,grd_100m,grd_300m,"different_grid_region")
% bathy_interp_figure(grd_300m,grd_100m,path_figure,"check_romsgrid_bath_intrep")
% bathy_intep_figure_section(grd_300m,grd_100m,path_figure)
    