clear;clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));
figure_path = '/home/hsinyi/figure/20260803_grid_test';
grid_path = '/home/hsinyi/roms_data/grid/';
cd ('/home/hsinyi/data_notm')

gebco = read_nc_fun('/home/hsinyi/data_notm/GEBCO_2025I2021.nc');
lon_call = gebco.Longitude >= -60 & gebco.Longitude <= -25;
lat_call = gebco.Latitude >= -10 & gebco.Latitude <= -20;

