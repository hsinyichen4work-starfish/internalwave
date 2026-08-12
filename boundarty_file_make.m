clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));

%%
path_setup ='/home/mbui/ModelOutput/NCOM/data/2022082200'; 
grid_process_path = '/home/mbui/ModelOutput/NCOM/grid';

%%
% read the grid 
hgrd2=read_ohgrd(grid_process_path,2); 
vgrd2=read_ovgrdA(grid_process_path,2);

% igrd = 1244; jgrd = 1334; nest = 2; 
% datestr_in = '2022082200'; 
% timetag = '00000000';
% appd = '_datafld'; nlev = 1; isface = true; transpose2d = true ;
% lon = read_ncom_flatfile(path_setup, 'grdlon', igrd, jgrd, nest, ...
%     datestr_in, timetag, appd, nlev, isface, transpose2d);
% lat = read_ncom_flatfile(path_setup, 'grdlat', igrd, jgrd, nest, ...
%     datestr_in, timetag, appd, nlev, isface, transpose2d);
% depth = read_ncom_flatfile(path_setup, 'depthr', igrd, jgrd, nest, ...
%     datestr_in, timetag, appd, nlev, isface, transpose2d);
% ang = read_ncom_flatfile(path_setup, 'grdang', igrd, jgrd, nest, ...
%     datestr_in, timetag, appd, nlev, isface, transpose2d);
% find(~(hgrd2.lon ==lon))
% find(~(hgrd2.lat ==lat))

%% read 2d file
cd(path_setup)

gridfiles = dir('depthr*');
gridfiles_struct = extract_ncom_name(gridfiles.name);

% sea surface height
files = dir('seahgt*');
ssh = NaN(heat_flux.jgrd,heat_flux.igrd,1,length(files));
for j = 1 : length(files)
    string_struct = extract_ncom_name(files(j).name);
    ssh(:,:,1,j) = read_ncom_flatfile(path_setup, string_struct.fldname, ...
        string_struct.igrd, string_struct.jgrd, string_struct.nest, ...
        string_struct.datestr_in, string_struct.timetag, string_struct.appd, ...
        string_struct.nlev, string_struct.isface);
end
