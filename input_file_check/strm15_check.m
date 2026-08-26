clear;clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));
figure_path = '/home/hsinyi/figure/20260803_grid_test';

grid_path = '/home/hsinyi/roms_data/grid/';
gridfile = 'roms_grd_100m.nc';
grd_test_read = read_nc_fun([grid_path,gridfile]);
grd_test_read.lon_rho(grd_test_read.lon_rho>180) = grd_test_read.lon_rho(grd_test_read.lon_rho>180) -360;


cd ('/home/hsinyi/data_notm')
filelist = {'get_srtm15_NW.txt','get_srtm15_NE.txt', ...
            'get_srtm15_SW.txt','get_srtm15_SE.txt'};
[topo.lon, topo.lat, topo.Z] = read_srtm15_tiles(filelist);

topo_SRTM = topo;

binary_setup = '/home/mbui/ModelOutput/NCOM/data/2022082200/';
cd(binary_setup)
fil = dir('grdlon_sfc_000000_000000_2o1244x1334_2022082200_00000000_datafld')
s = extract_ncom_name(fil.name);
topo.lon = read_ncom_flatfile(binary_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
fil = dir('grdlat_sfc_000000_000000_2o1244x1334_2022082200_00000000_datafld')
s = extract_ncom_name(fil.name);
topo.lat = read_ncom_flatfile(binary_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
fil = dir('depthr_sfc_000000_000000_2o1244x1334_2022082200_00000000_datafld')
s = extract_ncom_name(fil.name);
topo.Z = read_ncom_flatfile(binary_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);

topo_NCOM = topo;

gebco = read_nc_fun('/home/hsinyi/data_notm/GEBCO_2025I2021.nc');
topo_gebco.lon = gebco.Longitude;
topo_gebco.lat = gebco.Latitude;
topo_gebco.Z = gebco.elevation;

lon_call = gebco.Longitude >= -60 & gebco.Longitude <= -25;
lat_call = gebco.Latitude >= -10 & gebco.Latitude <= 20;

%%
cd(figure_path)
figure(1); clf; hold on
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";

ax(1) = nexttile; hold on
contourf(topo_gebco.lon(lon_call),topo_gebco.lat(lat_call),...
    topo_gebco.Z(lon_call,lat_call)',...
    -[0 10 100 500 : 500 : 5000],"color","k")
colorbar; shading flat
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"w",2)

ax(2) = nexttile; hold on
contourf(topo_NCOM.lon,topo_NCOM.lat,topo_NCOM.Z,...
    -[0 10 100 500 : 500 : 5000],"color","k")
colorbar; shading flat
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"w",2)

clim(ax,[-5000 0]); linkaxes(ax,'xy'); 
xlim(max_min(topo_NCOM.lon)); ylim(max_min(topo_NCOM.lat))
saveas(gcf,"bathy_source_comp2.fig")

