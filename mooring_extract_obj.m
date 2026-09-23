clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');
%%
dx = 900;
% -- START USER INPUT ----------
% Parent grid directory and file name
pdir    = '/home/hsinyi/roms_data/grid/';
pname   = ['roms_grd_',num2str(dx),'m.nc'];
ename   = ['roms_grd_',num2str(dx),'m_mor_edata.nc'];

lon = -45.13; lat =  3.95;
gname = 'french_mor';
%% Output file name and info
info  = ['indices for ' gname ' in ' pname ' , location:(' num2str(lon) ';' num2str(lat) ')'];
period =  600;
grd_ang = ncread([pdir,pname],"angle");
grd_lon = ncread([pdir,pname],"lon_rho");
grd_lon(grd_lon>180) = grd_lon(grd_lon>180)-360;
grd_lat = ncread([pdir,pname],"lat_rho");
ang = interp2_smellre(grd_lon, grd_lat, grd_ang, lon, lat);
mooring_vars = 'zeta, temp, salt, u, v' ;

%% -- END USER INPUT ------------

obj_name = gname;
obj_lon = lon; % + 360;
obj_lat = lat;
obj_ang = ang;
obj_msk =   1;
add_object([pdir ename],obj_name,grd_lon,grd_lat,period,obj_lon,obj_lat,obj_msk,obj_ang);
ncwriteatt([pdir ename],obj_name,'output_vars',mooring_vars);

ncwriteatt([pdir ename], '/', [gname '_info'],  info);           % info on parent and child grid
%%
ncdisp([pdir ename])