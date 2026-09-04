clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
parent_grid = '/home/mbui/ModelOutput/NCOM/grid/ohgrd_2.nc';
nc_path_ini_bry = '/home/hsinyi/roms_data/bry/bry_read_nc/';
dating = datenum("20220822","yyyymmdd") : datenum("20220822","yyyymmdd");
t1 = datenum(1900,12,31,0,0,0);
t2 = datenum(1994,1,1,0,0,0);
pgrid = read_nc_fun(parent_grid);
%%
cd(nc_path_ini_bry)
fod = string(datestr(dating,"yyyymmddHH"));
lthick = ncread(append(nc_path_ini_bry,fod(1),'_lthick.nc'),"layer_thickness");
lat = ncread(append(nc_path_ini_bry,fod(1),'_lthick.nc'),"Latitude");
lon = ncread(append(nc_path_ini_bry,fod(1),'_lthick.nc'),"Longitude");
NCOM_nc.layer_thickness = lthick;
[zs] = NCOM_zgrid(NCOM_nc);
z_grid = permute(zs,[3 2 1]);
if min(diff(mean(z_grid,[1,2]))) < 0
    error("z should be NEGATIVE down, INCREASING with index (z(1)=deepest ... z(end)=~0)")
end
%%
for folder_num = 1 : length(fod)
    clear rho* p* u* v* 
    time = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"MT") + t1;
    zeta = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"ssh");
    temp = ncread(append(nc_path_ini_bry,fod(folder_num),'_ts.nc'),"layer_temperature");
    salt = ncread(append(nc_path_ini_bry,fod(folder_num),'_ts.nc'),"layer_salinity");
    u = ncread(append(nc_path_ini_bry,fod(folder_num),'_uv.nc'),"u_velocity");
    v = ncread(append(nc_path_ini_bry,fod(folder_num),'_uv.nc'),"v_velocity");

    for t = 1 : length(time)
        % calcuated density and mean/anomaly
        rho(:,:,:,t) = density_calcuation(z_grid,lon,lat,temp(:,:,:,t),salt(:,:,:,t));
        [rho_bar(:,:,:,t),rho_prime(:,:,:,t)] = depth_mean_bar_cal(rho(:,:,:,t),lthick,pgrid.kb);

        % baroclinic pressure p'
        p(:,:,:,t) = density_pressure_cal(rho_prime(:,:,:,t),lthick);
        [p_bar(:,:,:,t),p_prime(:,:,:,t)] = depth_mean_bar_cal(p(:,:,:,t),lthick,pgrid.kb);

        % baroclinic velocity 
        [u_bar(:,:,:,t),u_prime(:,:,:,t)] = depth_mean_bar_cal(u(:,:,:,t),lthick,pgrid.kb);
        [v_bar(:,:,:,t),v_prime(:,:,:,t)] = depth_mean_bar_cal(v(:,:,:,t),lthick,pgrid.kb);
    end
end



