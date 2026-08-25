clear; clc;

addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

path_setup='/home/mbui/ModelOutput/NCOM/grid/'; 
path_figure='/home/hsinyi/figure/20260803_grid_test/'; 
mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring/';
file_save_path = '/home/hsinyi/matlab_file/grid_saving/';
grid_path = "/home/hsinyi/roms_data/grid/";
bath_path='/home/hsinyi/data_notm/'; 
binary_setup = '/home/mbui/ModelOutput/NCOM/data/2022082200/'

%% setting vars
mid_iter = 2; 

dx_100 = 100; nx_100 = 2304; ny_100 = 6144; % 100 m
dx_300 = 300; nx_300 = 2048; ny_300 = 2560; % 300 m

smooth_var.rmax = 0.2; smooth_var.hmin = 2; smooth_var.offset = 2.2;

%% bathymetry for interpolation
gebco = read_nc_fun('/home/hsinyi/data_notm/GEBCO_2025I2021.nc');
lon_dum = gebco.Longitude >= -52 & gebco.Longitude <= -38;
lat_dum = gebco.Latitude >= -4 & gebco.Latitude <= 12;
[topo.lon, topo.lat] = meshgrid(gebco.Longitude(lon_dum), ...
     gebco.Latitude(lat_dum));
topo.Z = gebco.elevation(lon_dum,lat_dum)';

%% parent grid bath
pgrid = read_nc_fun([path_setup,'ohgrd_2.nc']);
if mean(pgrid.h(pgrid.mask == 1),"omitmissing") < 0
    pgrid.h = -pgrid.h;
end
%%
[mid,rot_ang] = NCOM_grid_plot(mid_iter,path_figure);

%% 
[grd_300m,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx_300,nx_300,ny_300);
disp(append("300m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
    ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)))
[grd_300m] = bathy_interp(topo,grd_300m,path_figure);
grd_300m_nc = make_roms_ncgrid(grd_300m,'roms_grd_300m',...
    mid,rot_ang,dx_300,nx_300,ny_300,smooth_var,grid_path);
cd(path_figure)
[grd_300m_nc, diag] = match_boundary_topo(pgrid, grd_300m_nc, [1 1 1 1], 4,5);
saveas(gcf,"match_topo_check_300.fig")
saveas(gcf,"match_topo_check_300.jpg")
cd(grid_path)
ncwrite('roms_grd_300m.nc', 'h',grd_300m_nc.h);

cd(path_figure)
balance = cmocean('balance');
figure(1); clf; hold on
ti = tiledlayout(1,3); ti.Padding = "compact"; ti.TileSpacing = "tight";
colormap(parula)
ax(1) = nexttile; hold on
mypcolor(grd_300m_nc.lon_rho,grd_300m_nc.lat_rho,grd_300m_nc.h_orig);
contour(grd_300m_nc.lon_rho,grd_300m_nc.lat_rho,grd_300m_nc.h_orig,...
    [0 100 500 : 500 : 5000],"color","k");
colorbar; clim([0 5000])
title('original')

ax(2) = nexttile; hold on
mypcolor(grd_300m_nc.lon_rho,grd_300m_nc.lat_rho,grd_300m_nc.h);
contour(grd_300m_nc.lon_rho,grd_300m_nc.lat_rho,grd_300m_nc.h,...
    [0 100 500 : 500 : 5000],"color","k");
colorbar; clim([0 5000])
title('after match')

ax(3) = nexttile; hold on
mypcolor(grd_300m_nc.lon_rho,grd_300m_nc.lat_rho,grd_300m_nc.h - grd_300m_nc.h_orig);
colorbar; clim([-1 1])
title('after match - original')
colormap(ax(3), balance);
linkaxes(ax,'xy')
saveas(gcf,"match_topo_check_300_2.fig")
saveas(gcf,"match_topo_check_300_2.jpg")

[grd_100m,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx_100,nx_100,ny_100);
disp(append("100m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
                ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)))
[grd_100m] = bathy_interp(topo,grd_100m,path_figure);
grd_100m_nc = make_roms_ncgrid(grd_100m,'roms_grd_100m',...
    mid,rot_ang,dx_100,nx_100,ny_100,smooth_var,grid_path);
cd(path_figure)
grd_300m_nc.lon = grd_300m_nc.lon_rho; grd_300m_nc.lat = grd_300m_nc.lat_rho;
[grd_100m_nc, diag] = match_boundary_topo(grd_300m_nc, grd_100m_nc, [1 1 1 1], 4,5);
saveas("match_topo_check_100.fig")
saveas("match_topo_check_100.jpg")
cd(grid_path)
ncwrite('roms_grd_100m.nc', 'h',grd_100m_nc.h);

cd(path_figure)
balance = cmocean('balance');
figure(1); clf; hold on
ti = tiledlayout(1,3); ti.Padding = "compact"; ti.TileSpacing = "tight";
colormap(parula)
ax(1) = nexttile; hold on
mypcolor(grd_100m_nc.lon_rho,grd_100m_nc.lat_rho,grd_100m_nc.h_orig);
contour(grd_100m_nc.lon_rho,grd_100m_nc.lat_rho,grd_100m_nc.h_orig,...
    [0 100 500 : 500 : 5000],"color","k");
colorbar; clim([0 5000])
title('original')

ax(2) = nexttile; hold on
mypcolor(grd_100m_nc.lon_rho,grd_100m_nc.lat_rho,grd_100m_nc.h);
contour(grd_100m_nc.lon_rho,grd_100m_nc.lat_rho,grd_100m_nc.h,...
    [0 100 500 : 500 : 5000],"color","k");
colorbar; clim([0 5000])
title('after match')

ax(3) = nexttile; hold on
mypcolor(grd_100m_nc.lon_rho,grd_100m_nc.lat_rho,grd_100m_nc.h - grd_100m_nc.h_orig);
colorbar; clim([-1 1]*mean(abs(grd_100m_nc.h - grd_100m_nc.h_orig),"all"))
title('after match - original')
colormap(ax(3), balance);
linkaxes(ax,'xy')
saveas(gcf,"match_topo_check_100_2.fig")
saveas(gcf,"match_topo_check_100_2.jpg")


cd(file_save_path);
save("roms_grid_bath_interp","grd_100m","grd_300m");

parent_roms_region_plot(path_figure,grd_100m,grd_300m,"different_grid_region")
bathy_interp_figure(grd_300m,grd_100m,path_figure,"check_romsgrid_bath_intrep")
bathy_intep_figure_section(grd_300m,grd_100m,path_figure)
    