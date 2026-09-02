clear; clc;
addpath(genpath('/home/hchen54/internalwave/matlab_funtion'));

title = "Amazon shelf internal wave simulation - 900m & 3month stretch 6//250 "
fold_name = 'amazon_3mon900m_6_6';

NP_XI=8; NP_ETA=8; node = 1; cpn = 64; do_dia = true;
if ~(NP_XI*NP_ETA == node*cpn)
    error("tiled and node mismatch!!!")
end

time_stepping.NTIMES = 129600;
time_stepping.dt = 20; time_stepping.NDTFAST = 13;
time_stepping.rst = 86400;
time_stepping.his = 3600;
time_stepping.avg = 3600;
time_stepping.dia = time_stepping.his;
Scoord.THETA_S = 6;
Scoord.THETA_B = 6;
Scoord.hc = 250;
grid.LLm=684; grid.MMm=854; grid.N=128; %% 900m grid

walltime = '02:00:00';
input_filenames.grd = 'roms_grd_900m';
input_filenames.ini = 'roms_ini_900m';
input_filenames.bry = 'roms_bry_900m';
input_filenames.frc = 'roms_frc_900m';
filename = 'amazon_3mon.in';

%%
example_folder = '/home/hchen54/myrun/example/';
myrun = '/home/hchen54/myrun/';
new_folder = [myrun,fold_name,'/'];
fold_tile = [num2str(NP_XI),'x',num2str(NP_ETA)];

if ~exist(new_folder); cd (myrun); mkdir(fold_name);end
cd(new_folder)
copyfile([example_folder,'amazon_3day.in'],new_folder)
infile_make

copyfile([example_folder,'cppdefs.opt'],new_folder)
cppdef_make

copyfile([example_folder,'do_joint.sh'],new_folder)
copyfile([example_folder,'joint_output'],new_folder)
do_joint_make

copyfile([example_folder,'do_partition.sh'],new_folder)
copyfile([example_folder,'partition_input'],new_folder)
do_partition_make

copyfile([example_folder,'do_roms_expanse.sh'],new_folder)
do_roms_make

copyfile([example_folder,'flux_frc.opt'],new_folder)
copyfile([example_folder,'Makefile'],new_folder)
copyfile([example_folder,'ocean_vars.opt'],new_folder)
oceanvar_make

copyfile([example_folder,'param.opt'],new_folder)
param_make

disp("new folder make")