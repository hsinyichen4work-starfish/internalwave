clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
mid_iter = 2;
dx_100 = 100; nx_100 = 2304; ny_100 = 6144; % 100 m
dx_300 = 300; nx_300 = 2048; ny_300 = 2560; % 300 m
dx_900 = 900; nx_900 = 684; ny_900 = 854; % 900 m
%%
path_setup='/home/mbui/ModelOutput/NCOM/grid/';
mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring/';
path_figure = '/home/hsinyi/figure/20260803_grid_test/';
%%
cd(mooring_path);
load('Amazon_nopp_mooring_final.mat')
%%
cd(path_setup);
filename = "ohgrd_1.nc";
lon = ncread(filename,'lon'); lat = ncread(filename,'lat');
h = ncread(filename,'h'); 
filename = "ohgrd_2.nc";
lon_nest = ncread(filename,'lon'); lat_nest = ncread(filename,'lat');

filename = "ohgrd_3.nc";
lon_nest_nest = ncread(filename,'lon'); lat_nest_nest = ncread(filename,'lat');

%%
cd(path_figure);

figure(1); clf; hold on
pcolor(lon,lat,h); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
grid_boundary_plot(lon,lat,[1 1 1]*0,0.5)
grid_boundary_plot(lon_nest,lat_nest,[1 1 1]*0.4,1)
grid_boundary_plot(lon_nest_nest,lat_nest_nest,[1 1 1]*0.6,1.5)
plot([mooring_lon(1),cpies_lon(end-2)],[mooring_lat(1),cpies_lat(end-2)],"color","g","linewidth",2)
for j = 1 : mid_iter
    if j == 1
        mid = [midpoints([mooring_lon(1),cpies_lon(end-2)]), midpoints([mooring_lat(1),cpies_lat(end-2)])];
    else
        mid_move = [midpoints([mooring_lon(1),mid(1)]), midpoints([mooring_lat(1),mid(2)])];
        mid = mid_move;
    end
end
[x,y] = lonlat2xy([mooring_lon(1),cpies_lon(end-2)], ...
    [mooring_lat(1),cpies_lat(end-2)],mid(1),mid(2));
vec_moring = [-x(1)+x(2),-y(1)+y(2)]
rot_ang = rad2deg(angle(vec_moring(1) + 1i * vec_moring(2)))-90;
scatter(mid(1),mid(2),[],'k','filled')
saveas(gcf,"bath_test.jpg")
saveas(gcf,"bath_test.fig")
xlim([-49 -40]); ylim([-1 9])
saveas(gcf,"bath_test_zoomin.jpg")

%%
[grd_300m,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx_300,nx_300,ny_300);
disp(append("300m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
    ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)))

[grd_900m,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx_900,nx_900,ny_900);
disp(append("900m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
    ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)));

[grd_100m,actual_dx_APPROX,actual_dy_APPROX] = ...
    grid_setting(mid,rot_ang,dx_100,nx_100,ny_100);
disp(append("100m : actual_dx_APPROX = ",num2str(actual_dx_APPROX),...
    ", actual_dy_APPROX = ",num2str(actual_dy_APPROX)));

%%
lon100 = rad2deg(grd_100m.lon4)-360;
lat100 = rad2deg(grd_100m.lat4);
lon300 = rad2deg(grd_300m.lon4)-360;
lat300 = rad2deg(grd_300m.lat4);
lon900 = rad2deg(grd_900m.lon4)-360;
lat900 = rad2deg(grd_900m.lat4);

%%
cd(path_figure);
figure(1); clf; hold on
pcolor(lon,lat,h); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
grid_boundary_plot(lon,lat,[1 1 1]*0,0.5)
grid_boundary_plot(lon_nest,lat_nest,[1 1 1]*0.4,1)
grid_boundary_plot(lon_nest_nest,lat_nest_nest,[1 1 1]*0.6,1.5)
grid_boundary_plot(lon100,lat100,[1 1 0]*0.1,0.5)
grid_boundary_plot(lon300,lat300,[1 1 0]*0.8,1.5)
grid_boundary_plot(lon900,lat900,[1 1 0]*0.4,1)
xlim([-49 -40]); ylim([-1 9])
saveas(gcf,"bath_test_zoomin_regioncheck.jpg")