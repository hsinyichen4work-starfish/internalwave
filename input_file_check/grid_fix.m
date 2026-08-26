clear; clc;

addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

path_figure='/home/hsinyi/figure/20260821_grid_fix/'; 
grid_path = '/home/hsinyi/roms_data/grid/';
initial_path = '/home/hsinyi/roms_data/ini/';
ini_file = 'roms_ini_300m.nc';
smooth_var.rmax = 0.2; smooth_var.hmin = 2; smooth_var.offset = 2.2;
grd_name = 'roms_grd_300m.nc';


%%
cd(grid_path)
grd_300m = read_nc_fun([grid_path,grd_name]);
struct = lsmooth_fun(grd_name, ...
    smooth_var.rmax,smooth_var.hmin,smooth_var.offset);

ini_test_read = read_nc_fun([initial_path,ini_file]);
scoord.theta_s = ini_test_read.theta_s;
scoord.theta_b = ini_test_read.theta_b;
scoord.hc = ini_test_read.hc;
scoord.N = size(ini_test_read.u,3);
scoord.scoord = 'new2008';

grd_300m = grd_test_read;
[rx1_max, rx1_field, loc] = compute_rx1(grd_300m.h, scoord.theta_s, ...
    scoord.theta_b, scoord.hc, scoord.N);

[rx1_max, rx1_field, loc] = compute_rx1(grd_300m.h, scoord.theta_s, ...
    scoord.theta_b, 50, scoord.N);