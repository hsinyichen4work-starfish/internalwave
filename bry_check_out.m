clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

%% path setting
boundary_path = '/home/hsinyi/roms_data/bry/';
boundary_pathnc = '/home/hsinyi/roms_data/bry/bry_read_nc/';

boundary_ncread_path = '/home/hsinyi/roms_data/bry/bry_read_nc/';
grid_path = '/home/hsinyi/roms_data/grid/';
figure_path = '/home/hsinyi/figure/20260810_bry_test';

bry_file = 'roms_bry_300m_2022082200.nc';
gridfile = 'roms_grd_300m.nc'

%
thermal = cmocean('thermal');
balance = cmocean('balance');
speed = cmocean('speed');

bry_test_read = read_nc_fun('roms_bry_300m_2022082200.nc')

%%
cd(boundary_path)
bry_test_read = read_nc_fun([boundary_path ,bry_file]);
grd_test_read = read_nc_fun([grid_path ,gridfile]);
NCOM_SSH = read_nc_fun([boundary_ncread_path,'2022082200_ssh.nc']);
NCOM_GRID = read_nc_fun([boundary_ncread_path,'2022082200_lthick.nc']);
grd_test_read.lon_rho = grd_test_read.lon_rho-360; % make lon east-west himisphere
Np = size(bry_test_read.temp_south,2);
scoord  = 'new2008'; 

bry_time = bry_test_read.bry_time + datenum('1994-01-01');


out_west = extract_section_data(grd_test_read.lon_rho,grd_test_read.lat_rho, ...
    'row', 1, 'h', grd_test_read.h, "ang", grd_test_read.angle);
out_east = extract_section_data(grd_test_read.lon_rho,grd_test_read.lat_rho, ...
    'row', size(grd_test_read.lon_rho,1), 'h', grd_test_read.h, "ang", grd_test_read.angle);
out_south = extract_section_data(grd_test_read.lon_rho,grd_test_read.lat_rho, ...
    'col', 1, 'h', grd_test_read.h, "ang", grd_test_read.angle);
out_north = extract_section_data(grd_test_read.lon_rho,grd_test_read.lat_rho, ...
    'col', size(grd_test_read.lon_rho,2), 'h', grd_test_read.h, "ang", grd_test_read.angle);

cd(figure_path)
figure; clf; hold on
mypcolor(grd_test_read.lon_rho,grd_test_read.lat_rho,-grd_test_read.h)
shading flat; clim([-5000 0]);colorbar; daspect([1 1 1])
plot(out_west.lon,out_west.lat,"marker","o","color","r","linewidth",2) 
plot(out_east.lon,out_east.lat,"marker","o","color","g","linewidth",2) 
plot(out_north.lon,out_north.lat,"marker","o","color","b","linewidth",2) 
plot(out_south.lon,out_south.lat,"marker","o","color","k","linewidth",2) 
legend("","west","east","north","south")
saveas(gcf,"boundary_test.jpg")

cd(figure_path)
figure; clf; hold on; colormap(balance)
mypcolor(NCOM_GRID.Longitude,NCOM_GRID.Latitude,NCOM_SSH.ssh(:,:,2))
shading flat; clim([-1 1]);colorbar; daspect([1 1 1])
plot(out_west.lon-360,out_west.lat,"marker","o","color","r","linewidth",2) 
plot(out_east.lon-360,out_east.lat,"marker","o","color","g","linewidth",2) 
plot(out_north.lon-360,out_north.lat,"marker","o","color","b","linewidth",2) 
plot(out_south.lon-360,out_south.lat,"marker","o","color","k","linewidth",2) 
legend("","west","east","north","south")
saveas(gcf,"boundary_test_NCOM.jpg")

%%
z_west = zlevs3(out_west.h,out_west.h*0,bry_test_read.theta_s,bry_test_read.theta_b,... 
    bry_test_read.hc,Np,'r',scoord);
z_east = zlevs3(out_east.h,out_east.h*0,bry_test_read.theta_s,bry_test_read.theta_b,... 
    bry_test_read.hc,Np,'r',scoord);
z_north = zlevs3(out_north.h,out_north.h*0,bry_test_read.theta_s,bry_test_read.theta_b,... 
    bry_test_read.hc,Np,'r',scoord);
z_south = zlevs3(out_south.h,out_south.h*0,bry_test_read.theta_s,bry_test_read.theta_b,... 
    bry_test_read.hc,Np,'r',scoord);

cd(figure_path)
figure;clf;hold on
pcolor(squeeze(z_east)); colorbar; shading flat
saveas(gcf,"z_grid_check.jpg")


cd(figure_path)
figure; clf; hold on
ti = tiledlayout(2,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
t = 2;

ax(1) = nexttile; hold on
brymask = ~isnan(out_west.h);
mypcolor(repmat(out_west.dist(brymask),1,Np),squeeze(z_west(:,:,brymask))', ...
    bry_test_read.temp_west(brymask,:,t))
title("west boundary"); colorbar; clim([5 30])

ax(2) = nexttile; hold on
brymask = ~isnan(out_north.h);
mypcolor(repmat(out_north.dist(brymask),1,Np),z_north(:,brymask)', ...
    bry_test_read.temp_north(brymask,:,t))
title("north boundary"); colorbar; clim([5 30])

ax(3) = nexttile; hold on
brymask = ~isnan(out_east.h);
mypcolor(repmat(out_east.dist(brymask),1,Np),squeeze(z_east(:,:,brymask))', ...
    bry_test_read.temp_east(brymask,:,t))
title("east boundary"); colorbar; clim([5 30])

ax(4) = nexttile; hold on
brymask = ~isnan(out_south.h);
mypcolor(repmat(out_south.dist(brymask),1,Np),z_south(:,brymask)', ...
    bry_test_read.temp_south(brymask,:,t))
title("south boundary"); colorbar; clim([5 30])
title(ti,append("boundary temp (^\circ C), time : ",datestr(bry_time(t))))
linkaxes(ax,'xy')
saveas(gcf,"bry_temp_check.jpg")

ylim([-100 0]);clim([28 32])
saveas(gcf,"bry_temp_check_zoomin.jpg")
saveas(gcf,"bry_temp_check_zoomin.fig")

cd(figure_path)
figure; clf; hold on
ti = tiledlayout(1,1); ti.Padding = "compact"; ti.TileSpacing = "tight";
ax(1) = nexttile; hold on
brymask = ~isnan(out_west.h);
mypcolor(repmat(out_west.dist(brymask),1,Np),squeeze(z_west(:,:,brymask))', ...
    bry_test_read.temp_west(brymask,:,t))
title("west boundary"); colorbar;
saveas(gcf,"bry_temp_westcheck_zoomin.jpg")


%% check salinity
cd(figure_path)
figure; clf; hold on
ti = tiledlayout(2,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
t = 2;

ax(1) = nexttile; hold on
brymask = ~isnan(out_west.h);
mypcolor(repmat(out_west.dist(brymask),1,Np),squeeze(z_west(:,:,brymask))', ...
    bry_test_read.salt_west(brymask,:,t))
title("west boundary"); colorbar; clim([34 36])

ax(2) = nexttile; hold on
brymask = ~isnan(out_north.h);
mypcolor(repmat(out_north.dist(brymask),1,Np),z_north(:,brymask)', ...
    bry_test_read.salt_north(brymask,:,t))
title("north boundary"); colorbar; clim([34 36])

ax(3) = nexttile; hold on
brymask = ~isnan(out_east.h);
mypcolor(repmat(out_east.dist(brymask),1,Np),squeeze(z_east(:,:,brymask))', ...
    bry_test_read.salt_east(brymask,:,t))
title("east boundary"); colorbar; clim([34 36])

ax(4) = nexttile; hold on
brymask = ~isnan(out_south.h);
mypcolor(repmat(out_south.dist(brymask),1,Np),z_south(:,brymask)', ...
    bry_test_read.salt_south(brymask,:,t))
title("south boundary"); colorbar; clim([34 36])
title(ti,append("boundary salt (psu), time : ",datestr(bry_time(t))))
linkaxes(ax,'xy')
saveas(gcf,"bry_salt_check.jpg")

ylim([-100 0]);
saveas(gcf,"bry_salt_check_zoomin.jpg")
saveas(gcf,"bry_salt_check_zoomin.fig")


%% check velocity
% rotate vel first 
t = 2;
[u_rot_east, v_rot_east] = coord_trans_boundary(squeeze(bry_test_read.u_east(:,:,t)),...
    squeeze(bry_test_read.v_east(:,:,t)),out_east.ang, 'grid2geo');
[u_rot_south, v_rot_south] = coord_trans_boundary(squeeze(bry_test_read.u_south(:,:,t)),...
        squeeze(bry_test_read.v_south(:,:,t)),out_south.ang, 'grid2geo');
[u_rot_west, v_rot_west] = coord_trans_boundary(squeeze(bry_test_read.u_west(:,:,t)),...
        squeeze(bry_test_read.v_west(:,:,t)),out_west.ang, 'grid2geo');
[u_rot_north, v_rot_north] = coord_trans_boundary(squeeze(bry_test_read.u_north(:,:,t)),...
        squeeze(bry_test_read.v_north(:,:,t)),out_north.ang, 'grid2geo');


cd(figure_path)
figure; clf; hold on; colormap(balance)
ti = tiledlayout(2,4); ti.Padding = "compact"; ti.TileSpacing = "tight";

ax(1) = nexttile; hold on
brymask = ~isnan(out_west.h);
mypcolor(repmat(out_west.dist(brymask),1,Np),squeeze(z_west(:,:,brymask))', ...
    u_rot_west(brymask,:))
title("west boundary : u"); colorbar; clim(1.2*[-1 1])

ax(2) = nexttile; hold on
brymask = ~isnan(out_north.h);
mypcolor(repmat(out_north.dist(brymask),1,Np),z_north(:,brymask)', ...
    u_rot_north(brymask,:))
title("north boundary : u"); colorbar; clim(1.2*[-1 1])

ax(3) = nexttile; hold on
brymask = ~isnan(out_east.h);
mypcolor(repmat(out_east.dist(brymask),1,Np),squeeze(z_east(:,:,brymask))', ...
    u_rot_east(brymask,:))
title("east boundary : u"); colorbar; clim(1.2*[-1 1])

ax(4) = nexttile; hold on
brymask = ~isnan(out_south.h);
mypcolor(repmat(out_south.dist(brymask),1,Np),z_south(:,brymask)', ...
    u_rot_south(brymask,:))
title("south boundary : u"); colorbar; clim(1.2*[-1 1])

ax(5) = nexttile; hold on
brymask = ~isnan(out_west.h);
mypcolor(repmat(out_west.dist(brymask),1,Np),squeeze(z_west(:,:,brymask))', ...
    v_rot_west(brymask,:))
title("west boundary : v"); colorbar; clim(1.2*[-1 1])

ax(6) = nexttile; hold on
brymask = ~isnan(out_north.h);
mypcolor(repmat(out_north.dist(brymask),1,Np),z_north(:,brymask)', ...
    v_rot_north(brymask,:))
title("north boundary : v"); colorbar; clim(1.2*[-1 1])

ax(7) = nexttile; hold on
brymask = ~isnan(out_east.h);
mypcolor(repmat(out_east.dist(brymask),1,Np),squeeze(z_east(:,:,brymask))', ...
    v_rot_east(brymask,:))
title("east boundary : v"); colorbar; clim(1.2*[-1 1])

ax(8) = nexttile; hold on
brymask = ~isnan(out_south.h);
mypcolor(repmat(out_south.dist(brymask),1,Np),z_south(:,brymask)', ...
    v_rot_south(brymask,:))
title("south boundary : v"); colorbar; clim(1.2*[-1 1])

title(ti,append("boundary vel (m/s), time : ",datestr(bry_time(t))))
linkaxes(ax,'xy')
saveas(gcf,"bry_vel_check.jpg")

ylim([-100 0]);
saveas(gcf,"bry_vel_check_zoomin.jpg")
saveas(gcf,"bry_vel_check_zoomin.fig")


% make u v ploting quiver
cd(boundary_pathnc)
uv_nc = read_nc_fun('2022082200_uv.nc');
grid_nc = NCOM_GRID;
nn = 50;
Lon_plot = grid_nc.Longitude(1:nn:end,1:nn:end);
Lat_plot = grid_nc.Latitude(1:nn:end,1:nn:end);

cd(figure_path)
DATE_START = datenum('1900-12-31');
fi = figure;
fi.Position = [259 181 951 573];
colormap(speed)
s = 0.3;
disp(append("time : ",datestr(DATE_START + bry_time(t))))
clf; hold on
vmag = abs(uv_nc.u_velocity(:,:,1,t) + 1i * uv_nc.v_velocity(:,:,1,t));
mypcolor(grid_nc.Longitude,grid_nc.Latitude,vmag);
plot(out_west.lon,out_west.lat,"marker","o","color","r","linewidth",0.5) 
plot(out_east.lon,out_east.lat,"marker","o","color","g","linewidth",0.5) 
plot(out_north.lon,out_north.lat,"marker","o","color","b","linewidth",0.5) 
plot(out_south.lon,out_south.lat,"marker","o","color","k","linewidth",0.5)  
legend("","west","east","north","south","AutoUpdate","off")
shading flat; clim([0 2]); xlim([-50 -40]); ylim([-1.5 8])
colorbar; daspect([1 1 1]); 
quiver(Lon_plot,Lat_plot,s*uv_nc.u_velocity(1:nn:end,1:nn:end,1,t), ...
    s*uv_nc.v_velocity(1:nn:end,1:nn:end,1,t),0, "Color", "c",'LineWidth', 2);
daspect([1 1 1])
title(append("surface vel (m/s), time : ",datestr(DATE_START + bry_time(t))))
saveas(gcf,append("testboundary_vel_",datestr(DATE_START + bry_time(t)) ,".jpg"))


