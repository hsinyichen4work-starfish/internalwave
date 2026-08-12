clear; clc
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion/'));

%%
data_path ='/home/mbui/ModelOutput/NCOM/data/2022082200/'; 
parent_grid_path = '/home/mbui/ModelOutput/NCOM/grid/';
child_grid_path = '/home/hsinyi/roms_data/grid/';
boundary_path = '/home/hsinyi/roms_data/bry/bry_read_nc/';
figure_path = '/home/hsinyi/figure/20260810_bry_test';
grid_process_path = '/home/mbui/ModelOutput/NCOM/grid/';

%
thermal = cmocean('thermal');
balance = cmocean('balance');
speed = cmocean('speed');

% [par_grd,parinie,parinit,pariniu] = make_bry_need_nc(boundary_path);
cd(boundary_path)
par_grd = '2022082200_lthick.nc';
parent_grid = read_nc_fun([grid_process_path ,'ohgrd_2.nc']);

grid_nc = read_nc_fun('2022082200_lthick.nc');
zstt = grid_nc.layer_thickness;
zst  = permute(zstt,[3 2 1]);
[nn,ll,mm]=size(zst);
zst(isnan(zst)) = 0;
zs = zst;
for i = 1:mm
    for j = 1:ll
        for k = 1:nn
            zs(k,j,i) = -nansum_ca(zst(1:k,j,i)) + 0.5*zst(k,j,i);
        end
    end
end
z_grid = permute(zs,[3 2 1]);

ssh_nc = read_nc_fun('2022082200_ssh.nc');
DATE_START = datenum('1900-12-31');

% % figure and movie check ssh
% cd(figure_path)
% mv = VideoWriter('ssh_check_20220822', 'Motion JPEG AVI');
% mv.FrameRate = 5;
% open(mv);
% fi.Position = [259 181 951 573];
% colormap(balance)
% for t = 1 : size(ssh_nc.ssh,3)
%     disp(append("time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     mypcolor(grid_nc.Longitude,grid_nc.Latitude,squeeze(ssh_nc.ssh(:,:,t)));
%     shading flat; clim([-1 1]);
%     colorbar; daspect([1 1 1])
%     title(append("ssh (m), time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     saveas(gcf,append("testssh_",datestr(DATE_START + ssh_nc.MT(t)) ,".jpg"))
%     frame = getframe(gcf);
%     writeVideo(mv,frame);
% end
% close(mv)

%% check salt and temp

cd(boundary_path)
ts_nc = read_nc_fun('2022082200_ts.nc');
max_min(z_grid(:,:,1))
max_min(ts_nc.layer_temperature(:,:,1,:))

% % figure and movie check ssh
% cd(figure_path)
% mv = VideoWriter('surf_temp_check_20220822', 'Motion JPEG AVI');
% mv.FrameRate = 5;
% open(mv);
% fi.Position = [259 181 951 573];
% colormap(thermal)
% for t = 1 : size(ssh_nc.ssh,3)
%     disp(append("time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     mypcolor(grid_nc.Longitude,grid_nc.Latitude,squeeze(ts_nc.layer_temperature(:,:,1,t)));
%     shading flat; clim([25 30]);
%     colorbar; daspect([1 1 1])
%     title(append("surface temp (^\circ C), time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     saveas(gcf,append("testsurf_temp_",datestr(DATE_START + ssh_nc.MT(t)) ,".jpg"))
%     frame = getframe(gcf);
%     writeVideo(mv,frame);
% end
% close(mv)

% % figure and movie check surf salt
% cd(figure_path)
% figure
% mv = VideoWriter('surf_salt_check_20220822', 'Motion JPEG AVI');
% mv.FrameRate = 5;
% open(mv);
% colormap(thermal)
% for t = 1 : size(ssh_nc.ssh,3)
%     disp(append("time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     mypcolor(grid_nc.Longitude,grid_nc.Latitude,squeeze(ts_nc.layer_salinity(:,:,1,t)));
%     shading flat; clim([0 36]);
%     colorbar; daspect([1 1 1])
%     title(append("surface salinity (psu), time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     saveas(gcf,append("testsurf_salt_",datestr(DATE_START + ssh_nc.MT(t)) ,".jpg"))
%     frame = getframe(gcf);
%     writeVideo(mv,frame);
% end
% close(mv)

% check the crocesstion near the mooring
load('/home/mbui/ModelOutput/NCOM/NOPP_mooring/Amazon_nopp_mooring_final.mat');
dis = abs((grid_nc.Longitude - mooring_lon(3)) + 1i * (grid_nc.Latitude - mooring_lat(3)));
[min_val, linear_idx] = min(dis, [], 'all');
[row_idx, col_idx] = ind2sub(size(dis), linear_idx);

cd(figure_path)
out = extract_section_data(grid_nc.Longitude, grid_nc.Latitude, ...
    'row', row_idx, 'temp', ts_nc.layer_temperature(:,:,:,1));
Bathy = parent_grid.h;
thick_int =  -z_grid(:,:,end);
out_h = extract_section_data(grid_nc.Longitude, grid_nc.Latitude, ...
    'row', row_idx, 'h', Bathy);
out_zint = extract_section_data(grid_nc.Longitude, grid_nc.Latitude, ...
'row', row_idx, 'zint', thick_int);

fi = figure; fi.Position = [259 181 951 373]; clf; hold on
t = tiledlayout(1,3); t.Padding = "compact"; t.TileSpacing = "tight";
nexttile; hold on
mypcolor(grid_nc.Longitude, grid_nc.Latitude,Bathy) 
clim([-5000 0]);colorbar
title("Bathymetry")
nexttile; hold on
mypcolor(grid_nc.Longitude, grid_nc.Latitude,-thick_int) 
clim([-5000 0])
title("z_{int}")
ax = nexttile; hold on
mypcolor(grid_nc.Longitude, grid_nc.Latitude,Bathy+thick_int) 
clim([-90 90])
title("Bathymetry - z_{int}")
colormap(ax,balance)
saveas(gcf,"check_bathy_and_zint.jpg")

figure; clf; hold on
plot(out.lon, out.lat, 'o-') 
scatter(mooring_lon ,mooring_lat,50,"r","filled")
saveas(gcf,"check_crossection_orientaion.jpg")


fi = figure; fi.Position = [259 181 951 373]; clf; hold on
colormap(thermal)
t = tiledlayout(2,1); t.Padding = "compact"; t.TileSpacing = "tight";
nexttile;hold on
mypcolor(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp);
contour(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp,1 : 2: 31,"color","w")
shading interp; colorbar; clim([2 30])
plot(out.dist,out_h.h,"color","r","linewidth",2)
plot(out.dist,-out_zint.zint,"color","b","linewidth",2,"linestyle","--")
nexttile;hold on
mypcolor(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp);
contour(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp,1 : 2: 31,"color","w")
shading interp; colorbar; clim([2 30]); ylim([-500 0])
plot(out.dist,out_h.h,"color","r","linewidth",2)
plot(out.dist,-out_zint.zint,"color","b","linewidth",2,"linestyle","--")
saveas(gcf,"check_crossection_temp.jpg")
saveas(gcf,"check_crossection_temp.fig")

% cd(figure_path)
% mv = VideoWriter('section_temp_check_20220822', 'Motion JPEG AVI');
% mv.FrameRate = 5;
% open(mv);
% fi = figure; fi.Position = [259 181 951 373];
% colormap(thermal)
% for t = 1 : size(ssh_nc.ssh,3)
%     out = extract_section_data(grid_nc.Longitude, grid_nc.Latitude, ...
%         'row', row_idx, 'temp', ts_nc.layer_temperature(:,:,:,t));
%     disp(append("time : ",datestr(DATE_START + ssh_nc.MT(t))))
    
%     clf; hold on
%     til = tiledlayout(2,1); til.Padding = "compact"; til.TileSpacing = "tight";
%     nexttile;hold on
%     mypcolor(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp);
%     contour(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp,1 : 2: 31,"color","w")
%     shading interp; colorbar; clim([2 30])

%     nexttile;hold on
%     mypcolor(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp);
%     contour(repmat(out.dist,1,100),squeeze(z_grid(row_idx,:,:)),out.temp,1 : 2: 31,"color","w")
%     shading interp; colorbar; clim([2 30]); ylim([-500 0])
%     saveas(gcf,"check_crossection_temp.jpg")

%     title(til,append("surface temp (^\circ C), time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     saveas(gcf,append("testsection_temp_",datestr(DATE_START + ssh_nc.MT(t)) ,".jpg"))
%     frame = getframe(gcf);
%     writeVideo(mv,frame);
% end
% close(mv)

% find(~(squeeze(ts_nc.layer_temperature(:,:,1,1)) ...
%         == squeeze(ts_nc.layer_temperature(:,:,1,end))) ...
%         & ~isnan(squeeze(ts_nc.layer_temperature(:,:,1,1))))
%temp = ncread('2022082200_ts.nc','layer_temperature');

% make u v ploting quiver
cd(boundary_path)
uv_nc = read_nc_fun('2022082200_uv.nc');
nn = 50;
Lon_plot = grid_nc.Longitude(1:nn:end,1:nn:end);
Lat_plot = grid_nc.Latitude(1:nn:end,1:nn:end);

% cd(figure_path)
% mv = VideoWriter('surf_vel_check_20220822', 'Motion JPEG AVI');
% mv.FrameRate = 5;
% open(mv);
% fi = figure;
% fi.Position = [259 181 951 573];
% colormap(speed)
% s = 0.3;
% for t = 1 : size(ssh_nc.ssh,3)
%     disp(append("time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     clf; hold on
%     vmag = abs(uv_nc.u_velocity(:,:,1,t) + 1i * uv_nc.v_velocity(:,:,1,t));
%     mypcolor(grid_nc.Longitude,grid_nc.Latitude,vmag);
%     shading flat; clim([0 2]);
%     colorbar; daspect([1 1 1])
%     quiver(Lon_plot,Lat_plot,s*uv_nc.u_velocity(1:nn:end,1:nn:end,1,t), ...
%         s*uv_nc.v_velocity(1:nn:end,1:nn:end,1,t),0, "Color", "r");

%     daspect([1 1 1])
%     title(append("surface vel (m/s), time : ",datestr(DATE_START + ssh_nc.MT(t))))
%     saveas(gcf,append("testsurf_vel_",datestr(DATE_START + ssh_nc.MT(t)) ,".jpg"))
%     frame = getframe(gcf);
%     writeVideo(mv,frame);
% end
% close(mv)
