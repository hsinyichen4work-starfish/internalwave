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

%%
cd(path_setup);
filename = "ohgrd_1.nc"
ncdisp(filename)
lon = ncread(filename,'lon'); lat = ncread(filename,'lat');
ang = ncread(filename,'ang'); hu = ncread(filename,'hu');
h = ncread(filename,'h'); mask =  ncread(filename,'mask'); 
zw_1 = ncread(filename,'zw1'); zm3 = ncread(filename,'zm3');
zw3 = ncread(filename,'zw3');

filename = "ohgrd_2.nc"
ncdisp(filename)
lon_nest = ncread(filename,'lon'); lat_nest = ncread(filename,'lat');
ang_nest = ncread(filename,'ang'); hu_nest = ncread(filename,'hu');
h_nest = ncread(filename,'h'); mask_nest =  ncread(filename,'mask'); 
zw_1_nest = ncread(filename,'zw1'); zm3_nest = ncread(filename,'zm3');
zw3_nest = ncread(filename,'zw3');

filename = "ohgrd_3.nc"
ncdisp(filename)
lon_nest_nest = ncread(filename,'lon'); lat_nest_nest = ncread(filename,'lat');
ang_nest_nest = ncread(filename,'ang'); hu_nest_nest = ncread(filename,'hu');
h_nest_nest = ncread(filename,'h'); mask_nest_nest =  ncread(filename,'mask'); 
zw_1_nest_nest = ncread(filename,'zw1'); zm3_nest_nest = ncread(filename,'zm3');
zw3_nest_nest = ncread(filename,'zw3');

%%
cd(path_figure);

figure(1); clf; hold on
pcolor(lon,lat,h); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; legend("bathymetry","cpies","mooring","AutoUpdate","off")
plot(lon(1,:),lat(1,:),"color","k")
plot(lon(end,:),lat(end,:),"color","k")
plot(lon(:,1),lat(:,1),"color","k")
plot(lon(:,end),lat(:,end),"color","k")

plot(lon_nest(1,:),lat_nest(1,:),"color",[1 1 1]*0.4,"linewidth",1)
plot(lon_nest(end,:),lat_nest(end,:),"color",[1 1 1]*0.4,"linewidth",1)
plot(lon_nest(:,1),lat_nest(:,1),"color",[1 1 1]*0.4,"linewidth",1)
plot(lon_nest(:,end),lat_nest(:,end),"color",[1 1 1]*0.4,"linewidth",1)

plot(lon_nest_nest(1,:),lat_nest_nest(1,:),"color",[1 1 1]*0.6,"linewidth",1.5)
plot(lon_nest_nest(end,:),lat_nest_nest(end,:),"color",[1 1 1]*0.6,"linewidth",1.5)
plot(lon_nest_nest(:,1),lat_nest_nest(:,1),"color",[1 1 1]*0.6,"linewidth",1.5)
plot(lon_nest_nest(:,end),lat_nest_nest(:,end),"color",[1 1 1]*0.6,"linewidth",1.5)

plot([mooring_lon(1),cpies_lon(end-2)],[mooring_lat(1),cpies_lat(end-2)],"color","g","linewidth",2)
mid = [midpoints([mooring_lon(1),cpies_lon(end-2)]), midpoints([mooring_lat(1),cpies_lat(end-2)])];
mid_move = [midpoints([mooring_lon(1),mid(1)]), midpoints([mooring_lat(1),mid(2)])];
mid = mid_move;

[x,y] = lonlat2xy([mooring_lon(1),cpies_lon(end-2)],[mooring_lat(1),cpies_lat(end-2)],mid(1),mid(2))

vec_moring = [-x(1)+x(2),-y(1)+y(2)]; 
rot_ang = rad2deg(angle(vec_moring(1) + 1i * vec_moring(2)))-90;

scatter(mid(1),mid(2),[],'k','filled')
saveas(gcf,"bath_test.jpg")
saveas(gcf,"bath_test.fig")

xlim([-49 -40]); ylim([-1 9])
saveas(gcf,"bath_test_zoomin.jpg")

%% making new grid ny easy grid

dx_100 = 100;  % grid spacing in meters
nx_100 = 2304; ny_100 = 6144;

size_x_100 = nx_100*dx_100;   % = 230,400 m  (230.4 km)
size_y_100 = ny_100*dx_100;   % = 614,400 m  (614.4 km)
[nest100m.lon4,nest100m.lat4,nest100m.pm,nest100m.pn, ...
    nest100m.ang,nest100m.lone,nest100m.late] = ...
    easy_grid(nx_100, ny_100, size_x_100, size_y_100,mid(1),mid(2),rot_ang);

dx_300 = 300;  % grid spacing in meters
nx_300 = 2048; ny_300 = 2560;

size_x_300 = nx_300*dx_300;   % = 614.400 m  (614.4 km)
size_y_300 = ny_300*dx_300;   % = 768,000 m  (768.4 km)
[nest300m.lon4,nest300m.lat4,nest300m.pm,nest300m.pn, ...
    nest300m.ang,nest300m.lone,nest300m.late] = ...
    easy_grid(nx_300, ny_300, size_x_300, size_y_300,mid(1),mid(2),rot_ang);

actual_dx = 1./nest100m.pm;
actual_dy = 1./nest100m.pn;
mean(actual_dx(:))   % should be ≈ 100 m
mean(actual_dy(:))   % should be ≈ 100 m

actual_dx = 1./nest300m.pm;
actual_dy = 1./nest300m.pn;
mean(actual_dx(:))   % should be ≈ 300 m
mean(actual_dy(:))   % should be ≈ 300 m

%% the easygrid goes in radian--> make it to degeree
[nest300m.lon4_deg,nest300m.lat4_deg] = lonlat_rad2deg(nest300m.lon4,nest300m.lat4)
[nest300m.lone_deg,nest300m.late_deg] = lonlat_rad2deg(nest300m.lone,nest300m.late)

[nest100m.lon4_deg,nest100m.lat4_deg] = lonlat_rad2deg(nest100m.lon4,nest100m.lat4)
[nest100m.lone_deg,nest100m.late_deg] = lonlat_rad2deg(nest100m.lone,nest100m.late)


%%
cd(path_figure);
fi = figure(2); clf; hold on
fi.Position = [256   87   1104   777];
pcolor(lon,lat,h); shading flat; colorbar
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
axis equal; 
grid_boundary_plot(lon,lat,[1 1 1]*0,0.5)
grid_boundary_plot(lon_nest,lat_nest,[1 1 1]*0.4,1)
grid_boundary_plot(lon_nest_nest,lat_nest_nest,[1 1 1]*0.6,1.5)
grid_boundary_plot(nest300m.lon4_deg,nest300m.lat4_deg,[0.5 1 0.5],1)
grid_boundary_plot(nest100m.lon4_deg,nest100m.lat4_deg,[0.5 1 0.5]*0.5,1)

legend("bathymetry","cpies","mooring",...
    "2700m NCOM grid","","","","900m NCOM grid","","","","300m NCOM grid","","","",...
    "300 ROMS grid","","","","100 ROMS nested grid","","","")
saveas(gcf,"bath_test_newgrid.jpg")
saveas(gcf,"bath_test_newgrid.fig")

%% 
cd(file_save_path);
save("roms_grid_lonlat","nest100m","nest300m");

