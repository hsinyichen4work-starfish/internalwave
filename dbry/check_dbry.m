clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');
%%
balance = cmocean('balance');
%%
dx = 900;
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];
dbry_path = '/home/hsinyi/matlab_file/bry_saving/';
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path = '/home/hsinyi/roms_data/bry_63/';
flux_out_path = '/home/hsinyi/roms_data/bry_dynamic_flux_63/'; 
figure_path = '/home/hsinyi/figure/20260904dynamic_bry/';

load([dbry_path,'bryfile_dynamic900_imporve.mat'])
cgrid = read_nc_fun([child_grid_path,cgrid_name]);
disp(['read in',cgrid_name ])
cgrid.lon_rho(cgrid.lon_rho>180) = cgrid.lon_rho(cgrid.lon_rho>180) -360;
t1 = datenum('1994/01/01');

%%
dating = datenum("20220822","yyyymmdd") : datenum("20221125","yyyymmdd");
cbry_name = ['roms_bry_',num2str(dx),'m_',datestr(dating(1),"yyyymmddHH"),'.nc'];
cbry = read_nc_fun([child_bry_path,cbry_name]);
disp(['read in',cbry_name ])
%%
% [east_Fx_geo, east_Fy_geo] = vel_rot(east_Fx, east_Fy, ...
%     repmat(rad2deg(east_angc),length(time),1)', 'grid2geo');
% [west_Fx_geo, west_Fy_geo] = vel_rot(west_Fx, west_Fy, ...
%     repmat(rad2deg(west_angc),length(time),1)',  'grid2geo');
% [north_Fx_geo, north_Fy_geo] = vel_rot(north_Fx, north_Fy, ...
%     repmat(rad2deg(north_angc),1,length(time)),  'grid2geo');
% [south_Fx_geo, south_Fy_geo] = vel_rot(south_Fx, south_Fy, ...
%     repmat(rad2deg(south_angc),1,length(time)),  'grid2geo');

% %% 
% cd(figure_path)
% s = 10^-4;
% frame_step = 1;              % plot every Nth time step (raise to speed up / shrink file)
% t_idx = 1:frame_step:length(time);

% figure(1); clf; hold on
% grid_boundary_plot(cgrid.lon_rho,cgrid.lat_rho,[1 1 1]*0,0.5)
% daspect([1 1 1])
% h_east  = quiver(east_lon(:), east_lat(:),  s*east_Fx_geo(:,1),  s*east_Fy_geo(:,1),  "off");
% h_west  = quiver(west_lon(:), west_lat(:),  s*west_Fx_geo(:,1),  s*west_Fy_geo(:,1),  "off");
% h_south = quiver(south_lon(:),south_lat(:), s*south_Fx_geo(:,1), s*south_Fy_geo(:,1), "off");
% h_north = quiver(north_lon(:),north_lat(:), s*north_Fx_geo(:,1), s*north_Fy_geo(:,1), "off");
% quiver(-49,7,s*1*10^4,s*0,"color","k");
% text(-49,7.2,"10kW/m")
% ti = title(datestr(time(1) + t1));

% % 'Motion JPEG AVI' works cross-platform (incl. Linux); switch to 'MPEG-4'
% % if you're on Windows/Mac and want a smaller .mp4 file instead.
% vid = VideoWriter([figure_path,'boundary_flux.avi'],'Motion JPEG AVI');
% vid.FrameRate = 10;
% open(vid);

% for t = t_idx
%     h_east.UData  = s*east_Fx_geo(:,t);  h_east.VData  = s*east_Fy_geo(:,t);
%     h_west.UData  = s*west_Fx_geo(:,t);  h_west.VData  = s*west_Fy_geo(:,t);
%     h_south.UData = s*south_Fx_geo(:,t); h_south.VData = s*south_Fy_geo(:,t);
%     h_north.UData = s*north_Fx_geo(:,t); h_north.VData = s*north_Fy_geo(:,t);
%     ti.String = datestr(time(t) + t1);
%     drawnow
%     disp(ti.String)
%     writeVideo(vid, getframe(gcf));
% end
% close(vid);
% saveas(gcf,"boundary.jpg")
% %%
% north_flux_mag = abs(north_Fx_geo + 1i * north_Fy_geo);
% figure(2);clf; hold on
% mypcolor(repmat(north_lon,1,length(time)),...
%     repmat(time',length(north_lon),1),north_flux_mag)
% datetick('y',"mmmdd")
% clim([0 1]*2.5*10^4); 
% saveas(gcf,[figure_path,'N_boundary_PC.jpg'])
% clim([0 1]*1*10^4); 
% saveas(gcf,[figure_path,'N_boundary_PC2.jpg'])
% %%
% figure(21);clf; hold on; colormap(balance)
% mypcolor(repmat(north_lon,1,length(time)),...
%     repmat(time',length(north_lon),1),north_Fy)
% datetick('y',"mmmdd")
% clim([-1 1]*2.5*10^4); 
% saveas(gcf,[figure_path,'N_boundary_fy_PC.jpg'])
% clim([-1 1]*1*10^4); 
% saveas(gcf,[figure_path,'N_boundary_fy_PC2.jpg'])

% %%

% [maxval, idx] = max(abs(north_Fx_geo(:) + 1i*north_Fy_geo(:)));
% [i_along, i_time] = ind2sub(size(north_Fx_geo), idx);
% fprintf('max |F| = %.1f kW/m at along-index %d, time-index %d\n', maxval/1000, i_along, i_time);
% fprintf('time: %s\n', datestr(time(i_time) + t1));

%%
write_dynamic_bry_flux