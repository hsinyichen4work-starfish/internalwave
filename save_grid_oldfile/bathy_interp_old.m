clear; clc;

addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
bath_path='/home/hsinyi/data_notm'; 
path_figure='/home/hsinyi/figure/20260803_grid_test'; 
file_save_path = '/home/hsinyi/matlab_file/grid_saving';
mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring';

%%
cd(mooring_path);
load('Amazon_nopp_mooring_final.mat')

%%
cd(bath_path)
filelist = {'get_srtm15_NW.txt','get_srtm15_NE.txt', ...
            'get_srtm15_SW.txt','get_srtm15_SE.txt'};
[topo_lon, topo_lat, Z] = read_srtm15_tiles(filelist);

cd(path_figure);
figure; pcolor(topo_lon, topo_lat, Z); shading interp; colorbar; daspect([1 1 1])
title('Merged SRTM15+ tiles')
saveas(gcf,"check_SRTM15.jpg")
saveas(gcf,"check_SRTM15.fig")

%% 
cd(file_save_path);
load("roms_grid_lonlat.mat");

nest300m.bath4 = interp2(topo_lon, topo_lat, Z,nest300m.lon4_deg,nest300m.lat4_deg);
nest100m.bath4 = interp2(topo_lon, topo_lat, Z,nest100m.lon4_deg,nest100m.lat4_deg);

nest300m.bathe = interp2(topo_lon, topo_lat, Z,nest300m.lone_deg,nest300m.late_deg);
nest100m.bathe = interp2(topo_lon, topo_lat, Z,nest100m.lone_deg,nest100m.late_deg);

cd(path_figure);
figure; clf; hold on
t = tiledlayout(1,2); ti.Padding = 'tight'; ti.TileSpacing = "compact";
nexttile; hold on
pcolor(nest300m.lon4_deg,nest300m.lat4_deg, nest300m.bath4); shading interp; colorbar; daspect([1 1 1])
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
grid_boundary_plot(nest100m.lon4_deg,nest100m.lat4_deg,[0.5 1 0.5]*0.5,1)
xl = xlim; yl = ylim; clim([-5000 0])
title('300m roms grid')

nexttile; hold on
pcolor(nest100m.lon4_deg,nest100m.lat4_deg, nest100m.bath4); shading interp; colorbar; daspect([1 1 1])
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
grid_boundary_plot(nest300m.lon4_deg,nest300m.lat4_deg,[0.5 1 0.5]*0.5,1)
xlim(xl); ylim(yl);clim([-5000 0])
title('100m roms grid')

saveas(gcf,"check_romsgrid_bath_intrep.jpg")
saveas(gcf,"check_romsgrid_bath_intrep.fig")

%% extract the middle of the grid 
[ny, nx] = size(nest300m.lon4);
idx_mid = round(nx/2);   % adjust based on which axis is along-mooring
[dist, lon_sec, lat_sec, h_sec] = extract_section( ...
    nest300m.lon4_deg, nest300m.lat4_deg, nest300m.bath4, ...
    nest300m.pm, nest300m.pn, 'col', idx_mid);

[dist_moor, mismatch, idx_moor] = match_points_to_section( ...
        lon_sec, lat_sec, dist, mooring_lon, mooring_lat);
[dist_cpies, mismatch, idx_cpies] = match_points_to_section( ...
        lon_sec, lat_sec, dist, cpies_lon, cpies_lat);

[ny, nx] = size(nest100m.lon4);
idx_mid = round(nx/2);
[dist_100, lon_sec_100, lat_sec_100, h_sec_100] = extract_section( ...
    nest100m.lon4_deg, nest100m.lat4_deg, nest100m.bath4, ...
    nest100m.pm, nest100m.pn, 'col', idx_mid);

[dist_100start, mismatch, idx_100start] = match_points_to_section( ...
        lon_sec, lat_sec, dist, lon_sec_100(1), lat_sec_100(1));

%%
cd(path_figure);
figure; clf; hold on
%t = tiledlayout(1,2); ti.Padding = 'tight'; ti.TileSpacing = "compact";
%nexttile; hold on
pcolor(nest300m.lon4_deg,nest300m.lat4_deg, nest300m.bath4); shading interp; colorbar; daspect([1 1 1])
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
grid_boundary_plot(nest100m.lon4_deg,nest100m.lat4_deg,[0.5 1 0.5]*0.5,1)
plot(lon_sec, lat_sec,"linewidth",2)
xl = xlim; yl = ylim; clim([-5000 0])
title('300m roms grid')
saveas(gcf,"check_section.jpg")

fi = figure; clf; fi.Position = [1 1 1211 386];
t = tiledlayout(1,3); ti.Padding = 'tight'; ti.TileSpacing = "compact";
nexttile; hold on
pcolor(nest300m.lon4_deg,nest300m.lat4_deg, nest300m.bath4); shading interp; colorbar; daspect([1 1 1])
scatter(cpies_lon,cpies_lat,[],'r','filled')
scatter(mooring_lon,mooring_lat,[],'b','filled')
grid_boundary_plot(nest100m.lon4_deg,nest100m.lat4_deg,[0.5 1 0.5]*0.5,1)
plot(lon_sec, lat_sec,"linewidth",2); clim([-5000 0])
title('300m roms grid')

nexttile([1,2]); hold on
plot(dist, h_sec, 'k', 'LineWidth', 1)
plot(dist_100 + dist_100start, h_sec_100,"color",[0.5 1 0.5], 'LineWidth', 2,"linestyle","--")
yl = ylim;
for j = 1 : length(dist_moor)
    line(dist_moor(j)*[1 1],yl,"color","b");
end
for j = 1 : length(dist_cpies)
    line(dist_cpies(j)*[1 1],yl,"color","r");
end
xlabel('Along-track distance (km)')
ylabel('Depth (m)')
title('Bathymetry cross-section along mooring line')
grid on
saveas(gcf,"check_section_side2.jpg")
saveas(gcf,"check_section_side2.fig")

%%
cd(file_save_path);
save("roms_grid_bath_interp","nest100m","nest300m");