clear; clc;
addpath(genpath('/home/hchen54/internalwave/matlab_funtion'));

%% 
path = '/expanse/lustre/projects/uso101/hchen54/amazon300m_3day_0824/';
figure_folder = [path,'figure_fold_1st_run'];
grid_name = 'roms_grd_300m.nc';
ini_name = 'roms_ini_300m.nc';
initoread = ['/expanse/lustre/projects/uso101/hchen54/input/',ini_name];
grd_data = read_nc_fun(['/expanse/lustre/projects/uso101/hchen54/input/',grid_name]);

balance = cmocean('balance');
speed = cmocean('speed');

%%
info = ncinfo(initoread); dimNames = {info.Dimensions.Name};
dimLens  = [info.Dimensions.Length];
scoord.theta_s = ncread(initoread,'theta_s');
scoord.theta_b = ncread(initoread,'theta_b');
scoord.hc = ncread(initoread,'hc');
scoord.N = dimLens(strcmp(dimNames, 's_rho'));
scoord.scoord = 'new2008'
[inum,jnum] = size(grd_data.lon_rho); knum = scoord.N;

grd_data.lon_rho(grd_data.lon_rho>180) = grd_data.lon_rho(grd_data.lon_rho>180)-360;

%% 
if ~isfolder(figure_folder); mkdir(figure_folder); end
cd(path);
avg_fil = dir('*avg*nc');

info = ncinfo(avg_fil(1).name); dimNames = {info.Dimensions.Name};
dimLens  = [info.Dimensions.Length];
timenum = dimLens(strcmp(dimNames, 'time'));

for j = 1 : timenum
    cd(path)
    time_subset = ncread(avg_fil(1).name, 'ocean_time', [j], [1]);
    mytime = time_subset./(60*60*24) + datenum('1994/01/01');
    disp(datestr(mytime,"yyyymmmdd_HHMM"))
    ssh_subset = ncread(avg_fil(1).name, 'zeta', [1 1 j], [inum jnum 1]);

    nn = 64;
    cd(figure_folder)
    figure(1); clf; hold on; colormap(balance)
    mypcolor(grd_data.lon_rho,grd_data.lat_rho,ssh_subset); clim([-1 1]*1);
    colorbar; title(datestr(mytime)); shading flat; daspect([1 1 1])
    saveas(gcf,append("ssh_",datestr(mytime,"yyyymmmdd_HHMM"),".jpg"))
end




