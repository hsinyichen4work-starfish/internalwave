clear; clc;

example_folder = '/home/hchen54/myrun/example/';
fold_name = 'nod2_cpn128_16x16';
myrun = '/home/hchen54/myrun/';
new_folder = [myrun,fold_name,'/'];
title = "Amazon shelf internal wave simulation - 3 day test - node test 1"
time_stepping.NTIMES = 7200;
time_stepping.dt = 5; time_stepping.NDTFAST = 10;

Scoord.THETA_S = 6;
Scoord.THETA_B = 0.75;
Scoord.hc = 10;

NP_XI=16; NP_ETA=32;
fold_tile = ['<',num2str(NP_XI),'>x<',num2str(NP_ETA),'>'];
input_filenames.grd = 'roms_grd_300m';
input_filenames.ini = 'roms_ini_300m';
input_filenames.bry = 'roms_bry_300m';
input_filenames.frc = 'roms_frc_300m';


if ~exist(new_folder); cd (myrun); mkdir(fold_name);end
cd(new_folder)
filename = 'amazon_3day.in'



filename

