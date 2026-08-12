clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

%% path setting
initial_path = '/home/hsinyi/roms_data/ini/';
initial_pathnc = '/home/hsinyi/roms_data/bry/bry_read_nc/';
grid_path = '/home/hsinyi/roms_data/grid/';
figure_path = '/home/hsinyi/figure/20260812_ini_test/';

gridfile = 'roms_grd_300m.nc';
ini_file = 'roms_ini_300m.nc';

%%
thermal = cmocean('thermal');
balance = cmocean('balance');
speed = cmocean('speed');

ini_test_read = read_nc_fun([initial_path,ini_file]);
grd_test_read = read_nc_fun([grid_path,gridfile]);
NCOM_SSH = read_nc_fun([initial_pathnc,'2022082200_ssh.nc']);
NCOM_GRID = read_nc_fun([initial_pathnc,'2022082200_lthick.nc']);

%%
grd_test_read.lon_rho = grd_test_read.lon_rho-360; % make lon east-west himisphere
ini_time = (ini_test_read.ocean_time)./(24*60*60) + datenum('1994-01-01');
nc_time = NCOM_SSH.MT + datenum('1900-12-31');
nc_callnum = find(nc_time ==ini_time);

%%
cd(figure_path)
figure; clf; hold on
colormap(balance)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_SSH.ssh(:,:,nc_callnum))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,ini_test_read.zeta)
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("ssh (m) for initial time : ",datestr(ini_time)))

clim(ax,[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_ssh.jpg")


