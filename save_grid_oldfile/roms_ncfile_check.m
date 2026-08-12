clear; clc;

addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

grid_path = "/home/hsinyi/roms_data/grid";
path_figure='/home/hsinyi/figure/20260803_grid_test'; 
mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring';

file_300 = "roms_grd_300m.nc"; file_100 = "roms_grd_100m.nc";

%%
cd(mooring_path);
load('Amazon_nopp_mooring_final.mat')

%%
cd(grid_path);
grid_300 = read_nc_fun(file_300);
grid_100 = read_nc_fun(file_100);

grid_300.lon_rho(grid_300.lon_rho > 180) = ...
    grid_300.lon_rho(grid_300.lon_rho > 180) - 360;
grid_100.lon_rho(grid_100.lon_rho > 180) = ...
    grid_100.lon_rho(grid_100.lon_rho > 180) - 360;

%%
cd(path_figure);
h_plot = grid_300.hraw; h_plot(h_plot>0) = NaN;
figure(1); clf; hold on
pcolor(grid_300.lon_rho,grid_300.lat_rho,h_plot); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
grid_boundary_plot(grid_100.lon_rho,grid_100.lat_rho,[1 1 1]*0,0.5)
clim([-5000 0])
saveas(gcf,"text_ncfile.jpg")

h_plot = grid_100.hraw; h_plot(h_plot>0) = NaN;
figure(1); clf; hold on
pcolor(grid_100.lon_rho,grid_100.lat_rho,h_plot); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
grid_boundary_plot(grid_300.lon_rho,grid_300.lat_rho,[1 1 1]*0,0.5)
clim([-5000 0])
saveas(gcf,"text_ncfile_100.jpg")

%%
cd(grid_path);
rmax = 0.2; hmin = 2; offset = 2.2;
grid_300_smooth = lsmooth_fun(file_300,rmax,hmin,offset);
grid_100_smooth = lsmooth_fun(file_100,rmax,hmin,offset);

cd(path_figure);
figure(1); clf; hold on
pcolor(grid_300.lon_rho,grid_300.lat_rho,-grid_300_smooth.h); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
grid_boundary_plot(grid_100.lon_rho,grid_100.lat_rho,[1 1 1]*0,0.5)
title("300m bath smoothed")
clim([-5000 0])
saveas(gcf,"test_ncfile_smooth.jpg")

cd(path_figure);
figure(1); clf; hold on
pcolor(grid_100.lon_rho,grid_100.lat_rho,-grid_100_smooth.h); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
grid_boundary_plot(grid_300.lon_rho,grid_300.lat_rho,[1 1 1]*0,0.5)
title("100m bath smoothed")
clim([-5000 0])
saveas(gcf,"test_ncfile_smooth_100.jpg")

cd(path_figure);
figure(1); clf; hold on
pcolor(grid_300.lon_rho,grid_300.lat_rho,double(grid_300.mask_rho)); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
grid_boundary_plot(grid_100.lon_rho,grid_100.lat_rho,[1 1 1]*0,0.5)
title("300m check mask")
clim([0 1])
saveas(gcf,"test_ncfile_mask.jpg")