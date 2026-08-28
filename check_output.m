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
lat_psi = 0.25*(grd_data.lat_rho(1:end-1,1:end-1) + grd_data.lat_rho(2:end,1:end-1) + ...
                grd_data.lat_rho(1:end-1,2:end)   + grd_data.lat_rho(2:end,2:end));
lon_psi = 0.25*(grd_data.lon_rho(1:end-1,1:end-1) + grd_data.lon_rho(2:end,1:end-1) + ...
                grd_data.lon_rho(1:end-1,2:end)   + grd_data.lon_rho(2:end,2:end));

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
    u_subset = ncread(avg_fil(1).name, 'u', [1 1 1 j], [inum-1 jnum knum 1]);
    u_subset = u2rho(u_subset);
    v_subset = ncread(avg_fil(1).name, 'v', [1 1 1 j], [inum jnum-1 knum 1]);
    v_subset = v2rho(v_subset);
    zr = ROMS_zgrid(grd_data.h,ssh_subset,scoord,'r');
    
    z_out = [-1];
    u_surf = roms2z(zr,permute(u_subset,[3 1 2]),z_out, grd_data.mask_rho);
    v_surf = roms2z(zr,permute(v_subset,[3 1 2]),z_out, grd_data.mask_rho);
    vor_psi = vorticity_cal(permute(u_surf,[2 3 1]), ...
        permute(v_surf,[2 3 1]), grd_data.pm, grd_data.pn);
    [u_rot, v_rot] = vel_rot(permute(u_surf,[2 3 1]), permute(v_surf,[2 3 1]),...
         rad2deg(grd_data.angle), 'grid2geo');
    vmag = abs(u_surf + 1i * v_surf);
%    max_min(rad2deg(grd_data.angle))
    nn = 64; s = 0.15;
    cd(figure_folder)
    figure(1); clf; hold on; colormap(balance)
    mypcolor(lon_psi,lat_psi,vor_psi); clim([-1 1]*0.1*10^-3);
    quiver(grd_data.lon_rho(1:nn:end,1:nn:end),grd_data.lat_rho(1:nn:end,1:nn:end), ...
        s*u_rot(1:nn:end,1:nn:end,1),s*v_rot(1:nn:end,1:nn:end,1),0,"color",[1 1 1]*0.5)
    colorbar; title(datestr(mytime)); shading flat; daspect([1 1 1])
    saveas(gcf,append("vorticity_",datestr(mytime,"yyyymmmdd_HHMM"),".jpg"))

    figure(2); clf; hold on; colormap(speed)
    mypcolor(grd_data.lon_rho,grd_data.lat_rho,vmag); clim([0 1]*1.5);
    quiver(grd_data.lon_rho(1:nn:end,1:nn:end),grd_data.lat_rho(1:nn:end,1:nn:end), ...
        s*u_rot(1:nn:end,1:nn:end,1),s*v_rot(1:nn:end,1:nn:end,1),0,"color",[1 1 1]*0.5)
    colorbar; title(datestr(mytime)); shading flat; daspect([1 1 1])
    saveas(gcf,append("speed_",datestr(mytime,"yyyymmmdd_HHMM"),".jpg"))

end




