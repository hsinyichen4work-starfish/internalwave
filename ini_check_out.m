clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

%% path setting
initial_path = '/home/hsinyi/roms_data/ini/';
initial_pathnc = '/home/hsinyi/roms_data/bry/bry_read_nc/';
grid_path = '/home/hsinyi/roms_data/grid/';
figure_path = '/home/hsinyi/figure/20260812_ini_test/';

gridfile = 'roms_grd_300m.nc';
ini_file = 'roms_ini_300m.nc';

%%
thermal = cmocean('thermal');
balance = cmocean('balance');
speed = cmocean('speed');

ini_test_read = read_nc_fun([initial_path,ini_file]);
grd_test_read = read_nc_fun([grid_path,gridfile]);
NCOM_SSH = read_nc_fun([initial_pathnc,'2022082200_ssh.nc']);
NCOM_GRID = read_nc_fun([initial_pathnc,'2022082200_lthick.nc']);
NCOM_TS = read_nc_fun([initial_pathnc,'2022082200_ts.nc']);
NCOM_UV = read_nc_fun([initial_pathnc,'2022082200_uv.nc']);

NCOM_NC = read_nc_fun(['/home/mbui/ModelOutput/NCOM/grid/ohgrd_2.nc']) 
NCOM_z = NCOM_zgrid(NCOM_GRID);
mask3d    = repmat(NCOM_NC.mask, [1 1 size(NCOM_z,1)]);    % (igrd, jgrd, lo)
for i = 1 : size(NCOM_z,3)
    disp(append("i = ",num2str(i)))
    for j = 1 : size(NCOM_z,2)
        if ~isnan(NCOM_NC.kb(i,j)) & NCOM_NC.kb(i,j) < size(NCOM_z,1)
            mask3d(i,j,NCOM_NC.kb(i,j)+1:end) = 0;
        end
    end
end
mask3d = permute(mask3d,[3 2 1]);

scoord.theta_s = ini_test_read.theta_s;
scoord.theta_b = ini_test_read.theta_b;
scoord.hc = ini_test_read.hc;
scoord.N = size(ini_test_read.u,3);
scoord.scoord = 'new2008';
ROMS_z = ROMS_zgrid(grd_test_read.h,ini_test_read.zeta,scoord,'r');

%%
grd_test_read.lon_rho = grd_test_read.lon_rho-360; % make lon east-west himisphere
ini_time = (ini_test_read.ocean_time)./(24*60*60) + datenum('1994-01-01');
nc_time = NCOM_SSH.MT + datenum('1900-12-31');
nc_callnum = find(nc_time ==ini_time);
% nc_callnum = 1;

%%
cd(figure_path)
figure; clf; hold on
colormap(balance)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_SSH.ssh(:,:,nc_callnum))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,ini_test_read.zeta)
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("ssh (m) for initial time : ",datestr(ini_time)))

clim(ax,[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_ssh.jpg")


figure; clf; hold on
colormap(balance)
ti = tiledlayout(1,1); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
contour(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_SSH.ssh(:,:,nc_callnum),-1 : 0.1 : 1,"linewidth",2,"color","r")
contour(grd_test_read.lon_rho,grd_test_read.lat_rho,ini_test_read.zeta, ...
        -1 : 0.1 : 1,"linestyle","--","linewidth",2,"color","b")
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
daspect([1 1 1])
legend("NCOM data","ROMS inital nc file")

title(ti,append("ssh (m) for initial time : ",datestr(ini_time)))
clim(ax,[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_contour_ssh.jpg")


%% temp data
cd(figure_path)
figure; clf; hold on
colormap(thermal)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_TS.layer_temperature(:,:,1,nc_callnum))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,ini_test_read.temp(:,:,end))
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("surf temp (^\circ C) for initial time : ",datestr(ini_time)))

clim(ax,[25 30]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_surf_temp.jpg")


figure; clf; hold on
colormap(balance)
ti = tiledlayout(1,1); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
contour(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_TS.layer_temperature(:,:,1,nc_callnum),25:0.2:30,"linewidth",2,"color","r")
contour(grd_test_read.lon_rho,grd_test_read.lat_rho,ini_test_read.temp(:,:,end), ...
            25:0.2:30,"linestyle","--","linewidth",2,"color","b")
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
daspect([1 1 1])
legend("NCOM data","ROMS inital nc file")

title(ti,append("surf temp (^\circ C) for initial time : ",datestr(ini_time)))
clim(ax,[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_contour_temp.jpg")

%% specific depth temp
[F_temp_ini, z_out_ini] = roms2z(ROMS_z,permute(ini_test_read.temp,[3 1 2]),...
        [-100 -3000], grd_test_read.mask_rho);
T_dum = squeeze(NCOM_TS.layer_temperature(:,:,:,nc_callnum));
var_ncom  = flip(permute(T_dum,[3 2 1]), 1);   % match NCOM_z's deep-first order
mask3d_f  = flip(mask3d, 1);                    % mask3d built in surface-first order too — flip it as well
[F_temp_NCOM, z_out_NCOM] = roms2z(NCOM_z, var_ncom, [-100 -3000], mask3d_f);


%%%% DIFFERENT DEPTH
cd(figure_path)
figure; clf; hold on
colormap(thermal)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_temp_NCOM(1,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_temp_ini(1,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("100m temp (^\circ C) for initial time : ",datestr(ini_time)))

clim(ax,[15 28]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_100_temp.jpg")

figure; clf; hold on
colormap(thermal)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_temp_NCOM(2,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_temp_ini(2,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("3000m temp (^\circ C) for initial time : ",datestr(ini_time)))

clim(ax,[2 3]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_3000_temp.jpg")

% velocity data 
[grd_test_read.lon_u, grd_test_read.lat_u, grd_test_read.lon_v, grd_test_read.lat_v] = ...
        rho2uv_latlon(grd_test_read.lon_rho, grd_test_read.lat_rho)

NCOM_u_out = NCOM_UV.u_velocity(:,:,:,nc_callnum);
NCOM_v_out = NCOM_UV.v_velocity(:,:,:,nc_callnum);

u_rho = u2rho(ini_test_read.u);   % [2050,2562,128], now matches temp's grid
v_rho = v2rho(ini_test_read.v);   % [2050,2562,128], now matches temp's grid
[ROMS_u_out, ROMS_v_out] = vel_rot(u_rho,v_rho, ...
        rad2deg(grd_test_read.angle), 'grid2geo');

[F_u_ini, z_out_ini] = roms2z(ROMS_z,permute(ROMS_u_out,[3 1 2]),...
    [-1 -100 -3000], grd_test_read.mask_rho);
[F_v_ini, z_out_ini] = roms2z(ROMS_z,permute(ROMS_v_out,[3 1 2]),...
    [-1 -100 -3000], grd_test_read.mask_rho);
var_ncom  = flip(permute(NCOM_u_out,[3 2 1]), 1);   % match NCOM_z's deep-first order
mask3d_f  = flip(mask3d, 1);                    % mask3d built in surface-first order too — flip it as well
[F_u_NCOM, z_out_NCOM] = roms2z(NCOM_z, var_ncom, [-1 -100 -3000], mask3d_f);
var_ncom  = flip(permute(NCOM_v_out,[3 2 1]), 1);   % match NCOM_z's deep-first order
mask3d_f  = flip(mask3d, 1);                    % mask3d built in surface-first order too — flip it as well
[F_v_NCOM, z_out_NCOM] = roms2z(NCOM_z, var_ncom, [-1 -100 -3000], mask3d_f);
    

NCOM_VEL_MAG = abs(F_u_NCOM + 1i * F_v_NCOM);
ROMS_VEL_MAG = abs(F_u_ini + 1i * F_v_ini);

figure; clf; hold on
colormap(speed)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(NCOM_VEL_MAG(1,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(ROMS_VEL_MAG(1,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("surf vel mag (m/s) for initial time : ",datestr(ini_time)))

clim(ax,1.5*[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_surf_vel_mag.jpg")

figure; clf; hold on
colormap(speed)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(NCOM_VEL_MAG(2,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(ROMS_VEL_MAG(2,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("100m vel mag (m/s) for initial time : ",datestr(ini_time)))

clim(ax,1.5*[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_100_vel_mag.jpg")

figure; clf; hold on
colormap(speed)
ti = tiledlayout(1,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(NCOM_VEL_MAG(3,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(ROMS_VEL_MAG(3,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file")
title(ti,append("3000m vel mag (m/s) for initial time : ",datestr(ini_time)))

clim(ax,1.5*[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_3000_vel_mag.jpg")

cd(figure_path)
figure; clf; hold on
colormap(balance)
ti = tiledlayout(2,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_u_NCOM(2,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data : u")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_u_ini(2,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file : u")

ax(3) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_v_NCOM(2,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data : v")

ax(4) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_v_ini(2,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file : v")
title(ti,append("100m vel (m/s) for initial time : ",datestr(ini_time)))

clim(ax,[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_100_vel.jpg")

cd(figure_path)
figure; clf; hold on
colormap(balance)
ti = tiledlayout(2,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_u_NCOM(1,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data : u")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_u_ini(1,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file : u")

ax(3) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_v_NCOM(1,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data : v")

ax(4) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_v_ini(1,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file : v")
title(ti,append("surf vel (m/s) for initial time : ",datestr(ini_time)))

clim(ax,[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_surf_vel.jpg")

cd(figure_path)
figure; clf; hold on
colormap(balance)
ti = tiledlayout(2,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_u_NCOM(3,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data : u")

ax(2) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_u_ini(3,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file : u")

ax(3) = nexttile; hold on
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,permute(F_v_NCOM(3,:,:),[3,2,1]))
grid_boundary_plot(grd_test_read.lon_rho,grd_test_read.lat_rho,"k",2)
colorbar; daspect([1 1 1])
title("NCOM data : v")

ax(4) = nexttile; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,permute(F_v_ini(3,:,:),[2 3 1]))
colorbar; daspect([1 1 1])
title("ROMS inital nc file : v")
title(ti,append("3000m vel (m/s) for initial time : ",datestr(ini_time)))

clim(ax,[-1 1]); linkaxes(ax,'xy'); 
xlim(max_min(grd_test_read.lon_rho))
ylim(max_min(grd_test_read.lat_rho))
saveas(gcf,"initial_test_3000_vel.jpg")