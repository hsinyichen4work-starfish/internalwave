clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');

mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring';
load([mooring_path '/Amazon_nopp_mooring_final.mat'])   % mooring_names/lon/lat, cpies_names/lon/lat
%%
dx = 900;
% -- START USER INPUT ----------
% Parent grid directory and file name
pdir    = '/home/hsinyi/roms_data/grid/';
pname   = ['roms_grd_',num2str(dx),'m.nc'];
ename   = ['roms_grd_',num2str(dx),'m_mor_edata.nc'];

% Extraction locations: French mooring + 2026 NOPP moorings + CPIES
% (add_object uses the text before the first '_' as the dimension name,
%  so keep each name unique before the '_')
names = [{'french'}, reshape(cellstr(mooring_names),1,[]), reshape(cellstr(cpies_names),1,[])];
names = strcat(names, '_mor');
lons  = [-45.13, mooring_lon(:)', cpies_lon(:)'];
lats  = [  3.95, mooring_lat(:)', cpies_lat(:)'];

period =  360;
mooring_vars = 'zeta, temp, salt, u, v' ;
%% -- END USER INPUT ------------

grd_ang = ncread([pdir,pname],"angle");
grd_lon = ncread([pdir,pname],"lon_rho");
grd_lon(grd_lon>180) = grd_lon(grd_lon>180)-360;
grd_lat = ncread([pdir,pname],"lat_rho");

% start from a fresh edata file (nccreate fails if an object already exists)
if exist([pdir ename],'file'), delete([pdir ename]); end

for k = 1:numel(names)
    gname = names{k};
    lon = lons(k); lat = lats(k);
    info  = ['indices for ' gname ' in ' pname ' , location:(' num2str(lon) ';' num2str(lat) ')'];
    ang = interp2_smellre(grd_lon, grd_lat, grd_ang, lon, lat);

    obj_name = gname;
    obj_lon = lon; % + 360;
    obj_lat = lat;
    obj_ang = ang;
    obj_msk =   1;
    add_object([pdir ename],obj_name,grd_lon,grd_lat,period,obj_lon,obj_lat,obj_msk,obj_ang);
    ncwriteatt([pdir ename],obj_name,'output_vars',mooring_vars);

    ncwriteatt([pdir ename], '/', [gname '_info'],  info);           % info on parent and child grid
end
%%
ncdisp([pdir ename])
