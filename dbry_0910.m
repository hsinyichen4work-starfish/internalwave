clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');

%%
dx = 900;
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path = '/home/hsinyi/roms_data/bry_63/';
figure_path = '/home/hsinyi/figure/20260904dynamic_bry';
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];

dating = datenum("20220822","yyyymmdd") : datenum("20221125","yyyymmdd");
t1 = datenum(1900,12,31,0,0,0); t2 = datenum(1994,1,1,0,0,0);
cgrid = read_nc_fun([child_grid_path,cgrid_name]);
cgrid.lon_rho(cgrid.lon_rho>180) = cgrid.lon_rho(cgrid.lon_rho>180) -360;
%%