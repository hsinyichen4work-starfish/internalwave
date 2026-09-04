clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');

%%
dx = 300;
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path = '/home/hsinyi/roms_data/bry_63/';
figure_path = '/home/hsinyi/figure/20260904dynamic_bry';
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];

dating = datenum("20220822","yyyymmdd") : datenum("20220901","yyyymmdd");
t1 = datenum(1900,12,31,0,0,0); t2 = datenum(1994,1,1,0,0,0);
cgrid = read_nc_fun([child_grid_path,cgrid_name]);
cgrid.lon_rho(cgrid.lon_rho>180) = cgrid.lon_rho(cgrid.lon_rho>180) -360;
%%
fod = string(datestr(dating,"yyyymmddHH"));
dirstr = ["north";"south";"east";"west"];
for j = 1 : length(dirstr)
    bry_dir = dirstr(j);
    bry.time = []; bry.(bry_dir).ssh = [];
    bry.(bry_dir).temp = []; bry.(bry_dir).salt = [];
    bry.(bry_dir).u = []; bry.(bry_dir).v = [];
    for folder_num = 1 : length(fod)
        disp(fod(folder_num))
        cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
        cbry = read_nc_fun(append(child_bry_path,cbry_name));
        bry.time = cat(1,bry.time,cbry.bry_time);
        eval(append("bry.(bry_dir).ssh = cat(2,bry.(bry_dir).ssh,cbry.zeta_",bry_dir,");"))
        eval(append("bry.(bry_dir).temp = cat(3,bry.(bry_dir).temp,cbry.temp_",bry_dir,");"))
        eval(append("bry.(bry_dir).salt = cat(3,bry.(bry_dir).salt,cbry.salt_",bry_dir,");"))
        eval(append("bry.(bry_dir).u = cat(3,bry.(bry_dir).u,cbry.u_",bry_dir,");"))
        eval(append("bry.(bry_dir).v = cat(3,bry.(bry_dir).v,cbry.v_",bry_dir,");"))
    end
end
bry.north.u = center2face(bry.north.u, 1);
bry.south.u = center2face(bry.south.u, 1);
bry.east.v = center2face(bry.east.v, 1);
bry.west.v = center2face(bry.west.v, 1);

%%
bry.south.bathc = cgrid.h(:,1); bry.south.angc = cgrid.angle(:,1);
bry.north.bathc = cgrid.h(:,end); bry.north.angc = cgrid.angle(:,end);
bry.east.bathc = cgrid.h(end,:); bry.west.angc = cgrid.angle(end,:);
bry.west.bathc = cgrid.h(1,:); bry.east.angc = cgrid.angle(1,:);

bry.south.lon = cgrid.lon_rho(:,1); bry.south.lat = cgrid.lat_rho(:,1);
bry.north.lon = cgrid.lon_rho(:,end); bry.north.lat = cgrid.lat_rho(:,end);
bry.east.lon = cgrid.lon_rho(end,:); bry.west.lat = cgrid.lat_rho(end,:);
bry.west.lon = cgrid.lon_rho(1,:); bry.east.lat = cgrid.lat_rho(1,:);
%%
for j = 1 : length(dirstr)
    bry_dir = dirstr(j);
    bry.(bry_dir).child_z = zlevs3(repmat(bry.(bry_dir).bathc(:),1,size(bry.(bry_dir).ssh,2)), ...
        bry.(bry_dir).ssh, cbry.theta_s, cbry.theta_b, cbry.hc, size(cbry.u_west,2), 'r', 'new2008');
    bry.(bry_dir).child_z = permute(bry.(bry_dir).child_z,[2 1 3]);

    zw = zlevs3(repmat(bry.(bry_dir).bathc(:),1,size(bry.(bry_dir).ssh,2)), ...
        bry.(bry_dir).ssh, cbry.theta_s, cbry.theta_b, cbry.hc, size(cbry.u_west,2), 'w', 'new2008');
    bry.(bry_dir).lthick = diff(permute(zw,[2 1 3]),1,2);

%%
    % calcuated density and mean/anomaly
    bry.(bry_dir).rho = density_calcuation(bry.(bry_dir).child_z, ...
        bry.(bry_dir).lon(:),bry.(bry_dir).lat(:),bry.(bry_dir).temp,bry.(bry_dir).salt,2);
    [bry.(bry_dir).rho_bar, bry.(bry_dir).rho_prime] = ...
        depth_mean_bar_cal(bry.(bry_dir).rho, bry.(bry_dir).lthick, 2);
    bry.(bry_dir).p = density_pressure_cal(bry.(bry_dir).rho_prime,bry.(bry_dir).lthick, 2);
    [bry.(bry_dir).p_bar, bry.(bry_dir).p_prime] = ...
        depth_mean_bar_cal(bry.(bry_dir).p, bry.(bry_dir).lthick, 2);
    [bry.(bry_dir).u_bar, bry.(bry_dir).u_prime] = ...
        depth_mean_bar_cal(bry.(bry_dir).u, bry.(bry_dir).lthick, 2);
    [bry.(bry_dir).v_bar, bry.(bry_dir).v_prime] = ...
        depth_mean_bar_cal(bry.(bry_dir).v, bry.(bry_dir).lthick, 2);
end
%%
cutoff_days = 28/24;   % ~29 hours, per your PI's 28-30 hr suggestion
N = 5;
for j = 1 : length(dirstr)
    bry_dir = dirstr(j);
    %% --- high-pass filter p', u', v' along the time dimension (dim 3) ---
    bry.(bry_dir).p_fast = highpass_time_cal(bry.(bry_dir).p_prime, bry.time, cutoff_days, N, 3);
    bry.(bry_dir).u_fast = highpass_time_cal(bry.(bry_dir).u_prime, bry.time, cutoff_days, N, 3);
    bry.(bry_dir).v_fast = highpass_time_cal(bry.(bry_dir).v_prime, bry.time, cutoff_days, N, 3);
    %% --- final depth-integrated HF baroclinic energy flux ---
    % zdim=2 (depth), so sum collapses that dimension -> (nalong, nt)
    bry.(bry_dir).Fx = squeeze(sum(bry.(bry_dir).p_fast .* bry.(bry_dir).u_fast .* bry.(bry_dir).lthick, 2));
    bry.(bry_dir).Fy = squeeze(sum(bry.(bry_dir).p_fast .* bry.(bry_dir).v_fast .* bry.(bry_dir).lthick, 2));
end
%%
% cd(figure_path)
% figure; clf; 
% ti = tiledlayout(2,1); ti.Padding = "compact"; ti.TileSpacing = "tight";
% ax(1) = nexttile; hold on
% pcolor(squeeze(bry.(bry_dir).p_fast(1050,:,:))); shading flat
% colorbar;clim([-1 1]*1000)
% ax(2) = nexttile; hold on
% pcolor(squeeze(bry.(bry_dir).p_prime(1050,:,:))- mean(squeeze(bry.(bry_dir).p_prime(1050,:,:)),2)); shading flat
% colorbar;clim([-1 1]*1000)
% saveas(gcf,"check_filter.jpg")
% %%
% cd(figure_path)
% close all;
% figure; clf; hold on
% plot(bry.time,squeeze(bry.(bry_dir).p_prime(1050,50,:))- mean(squeeze(bry.(bry_dir).p_prime(1050,50,:)),"all"))
% plot(bry.time,squeeze(bry.(bry_dir).p_fast(1050,50,:)))
% saveas(gcf,"check_filter2.jpg")
% saveas(gcf,"check_filter2.fig")

%%
save("bryfile_dynamic","bry", '-v7.3')
