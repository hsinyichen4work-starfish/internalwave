clear; clc;

addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

path_setup='/home/mbui/ModelOutput/NCOM/grid'; 
path_figure='/home/hsinyi/figure/20260803_grid_test'; 
mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring';
file_save_path = '/home/hsinyi/matlab_file/grid_saving';
grid_path = "/home/hsinyi/roms_data/grid";

%%
cd(mooring_path);
load('Amazon_nopp_mooring_final.mat')

plot([mooring_lon(1),cpies_lon(end-2)],[mooring_lat(1),cpies_lat(end-2)],"color","g","linewidth",2)
mid = [midpoints([mooring_lon(1),cpies_lon(end-2)]), midpoints([mooring_lat(1),cpies_lat(end-2)])];
[x,y] = lonlat2xy([mooring_lon(1),cpies_lon(end-2)],[mooring_lat(1),cpies_lat(end-2)],mid(1),mid(2))
vec_moring = [-x(1)+x(2),-y(1)+y(2)]; 
rot_ang = rad2deg(angle(vec_moring(1) + 1i * vec_moring(2)))-90;

%% 
cd(file_save_path);
load("roms_grid_bath_interp");

%%
dx_100 = 100;  % grid spacing in meters
nx_100 = 2304; ny_100 = 6144;
size_x_100 = nx_100*dx_100;   % = 230,400 m  (230.4 km)
size_y_100 = ny_100*dx_100;   % = 614,400 m  (614.4 km)

dx_300 = 300;  % grid spacing in meters
nx_300 = 2048; ny_300 = 2560;
size_x_300 = nx_300*dx_300;   % = 230,400 m  (230.4 km)
size_y_300 = ny_300*dx_300;   % = 614,400 m  (614.4 km)

%
cd(grid_path);
rmax = 0.2; hmin = 2; offset = 2.2;
make_grid(nx_100,ny_100,nest100m.lon4, nest100m.lat4, nest100m.pn,nest300m.pm,...
    nest100m.bath4,nest100m.ang,size_x_100,size_y_100,...
    rot_ang,mid(1), mid(2), nest100m.lone, nest100m.late);
movefile('roms_grd.nc', 'roms_grd_100m.nc');
lsmooth_fun('roms_grd_100m.nc',rmax,hmin,offset);

make_grid(nx_300,ny_300,nest300m.lon4, nest300m.lat4, nest300m.pn,nest300m.pm,...
    nest300m.bath4,nest300m.ang,size_x_300,size_y_300,...
    rot_ang,mid(1), mid(2), nest300m.lone, nest300m.late);
movefile('roms_grd.nc', 'roms_grd_300m.nc');
lsmooth_fun('roms_grd_300m.nc',rmax,hmin,offset);

