clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
%%
balance = cmocean('balance');
thermal = cmocean('thermal');

%%
dx = 900;
parent_grid = '/home/mbui/ModelOutput/NCOM/grid/ohgrd_2.nc';
nc_path_ini_bry = '/home/hsinyi/roms_data/NCOM_DATA_NC/';
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path = '/home/hsinyi/roms_data/bry_63/';
figure_path = '/home/hsinyi/figure/20260821_debug_fix';
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];

dating = datenum("20220822","yyyymmdd") : datenum("20220901","yyyymmdd");
t1 = datenum(1900,12,31,0,0,0); t2 = datenum(1994,1,1,0,0,0);
pgrid = read_nc_fun(parent_grid);
cgrid = read_nc_fun([child_grid_path,cgrid_name]);
cgrid.lon_rho(cgrid.lon_rho>180) = cgrid.lon_rho(cgrid.lon_rho>180) -360;
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
cbry_name = ['roms_bry_',num2str(dx),'m_',datestr(dating(1),"yyyymmddHH"),'.nc'];
cbry = read_nc_fun([child_bry_path,cbry_name]);
theta_s = cbry.theta_s; theta_b = cbry.theta_b; 
hc = cbry.hc; N = size(cbry.temp_south,2); pN = size(z_grid,3);
%% extract path
[ny, nx] = size(lon);
south.bnd_lon = cgrid.lon_rho(:,1); south.bnd_lat = cgrid.lat_rho(:,1); %south
[south.iy_path, south.ix_path, south.lon_path, south.lat_path] ...
    = trace_line_on_grid(lon,lat,south.bnd_lon, south.bnd_lat);
south.lin_idx = sub2ind([ny, nx], south.iy_path, south.ix_path);

north.bnd_lon = cgrid.lon_rho(:,end); north.bnd_lat = cgrid.lat_rho(:,end); %north
[north.iy_path, north.ix_path, north.lon_path, north.lat_path] ...
    = trace_line_on_grid(lon,lat,north.bnd_lon, north.bnd_lat);
north.lin_idx = sub2ind([ny, nx], north.iy_path, north.ix_path);

west.bnd_lon = cgrid.lon_rho(1,:); west.bnd_lat = cgrid.lat_rho(1,:); %west
[west.iy_path, west.ix_path, west.lon_path, west.lat_path] ...
    = trace_line_on_grid(lon,lat,west.bnd_lon, west.bnd_lat);
west.lin_idx = sub2ind([ny, nx], west.iy_path, west.ix_path);

east.bnd_lon = cgrid.lon_rho(end,:); east.bnd_lat = cgrid.lat_rho(end,:); %east
[east.iy_path, east.ix_path, east.lon_path, east.lat_path] ...
    = trace_line_on_grid(lon,lat,east.bnd_lon, east.bnd_lat);
east.lin_idx = sub2ind([ny, nx], east.iy_path, east.ix_path);
    
%%
south.bath = pgrid.h(south.lin_idx); south.bathc = cgrid.h(:,1); south.angc = cgrid.angle(:,1);
north.bath = pgrid.h(north.lin_idx); north.bathc = cgrid.h(:,end); north.angc = cgrid.angle(:,end);
east.bath = pgrid.h(east.lin_idx); east.bathc = cgrid.h(end,:); west.angc = cgrid.angle(end,:);
west.bath = pgrid.h(west.lin_idx); west.bathc = cgrid.h(1,:); east.angc = cgrid.angle(1,:);
for k = 1 : size(z_grid,3)
    dum = squeeze(z_grid(:,:,k));
    south.parent_z(:,k) =  dum(south.lin_idx);
    north.parent_z(:,k) =  dum(north.lin_idx);
    west.parent_z(:,k) =  dum(west.lin_idx);
    east.parent_z(:,k) =  dum(east.lin_idx);
end
east.parent_z = fliplr(east.parent_z);
west.parent_z = fliplr(west.parent_z);
north.parent_z = fliplr(north.parent_z);
south.parent_z = fliplr(south.parent_z);

%%
cd(figure_path)
figure; clf; hold on
plot(east.bnd_lon,east.bnd_lat)
plot(west.bnd_lon,west.bnd_lat)
plot(north.bnd_lon,north.bnd_lat)
plot(south.bnd_lon,south.bnd_lat)
plot(north.lon_path,north.lat_path,"-o")
plot(lon(north.lin_idx),lat(north.lin_idx),"linewidth",2)
saveas(gcf,"check_rightpath.jpg")
%%
cd(figure_path)
figure; clf; hold on
% plot(east.bnd_lon,east.bnd_lat)
% plot(west.bnd_lon,west.bnd_lat)
% plot(north.bnd_lon,north.bnd_lat)
plot(south.bnd_lon,-south.bathc)
% plot(north.lon_path,north.lat_path,"-o")
plot(south.lon_path,south.bath,"linewidth",2)
saveas(gcf,"check_rightbath.jpg")
saveas(gcf,"check_rightbath.fig")

%%
cd(figure_path)
if ~isfolder('ssh_check'); mkdir('ssh_check'); end
cd ssh_check
for folder_num = 1 : length(fod)
    zeta = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"ssh");
    cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
    cbry = read_nc_fun(append(child_bry_path,cbry_name));

    for t = 1 : length(cbry.bry_time)
        dum = zeta(:,:,t);
        figure; clf;
        ti = tiledlayout(2,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
        nexttile; hold on
        plot(east.bnd_lat,cbry.zeta_east(:,t),"LineWidth",2);
        plot(east.lat_path,dum(east.lin_idx),"LineWidth",1,"LineStyle","--");
        title("east ssh")

        nexttile; hold on
        plot(west.bnd_lat,cbry.zeta_west(:,t),"LineWidth",2);
        plot(west.lat_path,dum(west.lin_idx),"LineWidth",1,"LineStyle","--");
        title("west ssh")

        nexttile; hold on
        plot(north.bnd_lon,cbry.zeta_north(:,t),"LineWidth",2);
        plot(north.lon_path,dum(north.lin_idx),"LineWidth",1,"LineStyle","--");
        title("north ssh")

        nexttile; hold on
        plot(south.bnd_lon,cbry.zeta_south(:,t),"LineWidth",2);
        plot(south.lon_path,dum(south.lin_idx),"LineWidth",1,"LineStyle","--");
        title("south ssh")

        saveas(gcf,append("check_zeta_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg")) 
        disp(append("save check_zeta_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg"))
    end
end

%%
cd(figure_path)
if ~isfolder('temp_check'); mkdir('temp_check'); end
cd temp_check
for folder_num = 1 : length(fod)
    
    temp = ncread(append(nc_path_ini_bry,fod(folder_num),'_ts.nc'),"layer_temperature");
    cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
    cbry = read_nc_fun(append(child_bry_path,cbry_name));

    south.child_z = zlevs3(repmat(south.bathc,1,length(cbry.bry_time)), ...
        cbry.zeta_south, theta_s, theta_b, hc, N, 'r', 'new2008');
    north.child_z = zlevs3(repmat(north.bathc,1,length(cbry.bry_time)), ...
        cbry.zeta_north, theta_s, theta_b, hc, N, 'r', 'new2008');
    west.child_z = zlevs3(repmat(west.bathc',1,length(cbry.bry_time)), ...
        cbry.zeta_west, theta_s, theta_b, hc, N, 'r', 'new2008');
    east.child_z = zlevs3(repmat(east.bathc',1,length(cbry.bry_time)), ...
        cbry.zeta_east, theta_s, theta_b, hc, N, 'r', 'new2008');

    for t = 1 : length(cbry.bry_time)
        for k = 1 : pN
            dum = squeeze(temp(:,:,k,t));
            south.temp_z(:,k) =  dum(south.lin_idx);
            north.temp_z(:,k) =  dum(north.lin_idx);
            west.temp_z(:,k) =  dum(west.lin_idx);
            east.temp_z(:,k) =  dum(east.lin_idx);
        end

        figure; clf; colormap(thermal)
        ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
        axe(1) = nexttile; hold on
        mypcolor(repmat(east.lat_path,1,pN),east.parent_z,east.temp_z)
        shading flat; 
        title("east temp (parent)")
        axe(2) = nexttile; hold on
        mypcolor(repmat(east.bnd_lat',1,N),squeeze(east.child_z(:,:,t))',squeeze(cbry.temp_east(:,:,t)))
        shading flat; colorbar
        title("east temp (child)")
        linkaxes(axe,'xy');
        

        axw(1) = nexttile; hold on
        mypcolor(repmat(west.lat_path,1,pN),west.parent_z,west.temp_z)
        shading flat; 
        title("west temp (parent)")
        axw(2) = nexttile; hold on
        mypcolor(repmat(west.bnd_lat',1,N),squeeze(west.child_z(:,:,t))',squeeze(cbry.temp_west(:,:,t)))
        shading flat; colorbar
        title("west temp (child)")
        linkaxes(axw,'xy');

        axn(1) = nexttile; hold on
        mypcolor(repmat(north.lon_path,1,pN),north.parent_z,north.temp_z)
        shading flat; 
        title("north temp (parent)")
        axn(2) = nexttile; hold on
        mypcolor(repmat(north.bnd_lon,1,N),squeeze(north.child_z(:,:,t))',squeeze(cbry.temp_north(:,:,t)))
        shading flat; colorbar
        title("north temp (child)")
        linkaxes(axn,'xy');

        axs(1) = nexttile; hold on
        mypcolor(repmat(south.lon_path,1,pN),south.parent_z,south.temp_z)
        shading flat; 
        title("south temp (parent)")
        axs(2) = nexttile; hold on
        mypcolor(repmat(south.bnd_lon,1,N),squeeze(south.child_z(:,:,t))',squeeze(cbry.temp_south(:,:,t)))
        shading flat; colorbar
        title("south temp (child)")
        linkaxes(axs,'xy');

        clim([axe axw axn],[0 30])
        clim(axs,[25 30])
        saveas(gcf,append("check_temp_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg")) 

        ylim([axe axw axn axs],[-100 0]); clim([axe axw axn axs],[25 30])
        saveas(gcf,append("check_zoomtemp_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg")) 
        disp(append("save check_temp_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg"))
    end

end

%%
cd(figure_path)
if ~isfolder('vel_check'); mkdir('vel_check'); end
cd vel_check
for folder_num = 1 : length(fod)
    
    u = ncread(append(nc_path_ini_bry,fod(folder_num),'_uv.nc'),"u_velocity");
    v = ncread(append(nc_path_ini_bry,fod(folder_num),'_uv.nc'),"v_velocity");
    cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
    cbry = read_nc_fun(append(child_bry_path,cbry_name));

    south.child_z = zlevs3(repmat(south.bathc,1,length(cbry.bry_time)), ...
        cbry.zeta_south, theta_s, theta_b, hc, N, 'r', 'new2008');
    north.child_z = zlevs3(repmat(north.bathc,1,length(cbry.bry_time)), ...
        cbry.zeta_north, theta_s, theta_b, hc, N, 'r', 'new2008');
    west.child_z = zlevs3(repmat(west.bathc',1,length(cbry.bry_time)), ...
        cbry.zeta_west, theta_s, theta_b, hc, N, 'r', 'new2008');
    east.child_z = zlevs3(repmat(east.bathc',1,length(cbry.bry_time)), ...
        cbry.zeta_east, theta_s, theta_b, hc, N, 'r', 'new2008');

    for t = 1 : length(cbry.bry_time)
        for k = 1 : pN
            dum = squeeze(u(:,:,k,t));
            south.u_z(:,k) =  dum(south.lin_idx);
            north.u_z(:,k) =  dum(north.lin_idx);
            west.u_z(:,k) =  dum(west.lin_idx);
            east.u_z(:,k) =  dum(east.lin_idx);
            dum = squeeze(v(:,:,k,t));
            south.v_z(:,k) =  dum(south.lin_idx);
            north.v_z(:,k) =  dum(north.lin_idx);
            west.v_z(:,k) =  dum(west.lin_idx);
            east.v_z(:,k) =  dum(east.lin_idx);
        end
        [east.u_rot, east.v_rot] = vel_rot(cbry.u_east(:,:,t), center2face(cbry.v_east(:,:,t), 1),...
             repmat(rad2deg(east.angc)',1,N),'grid2geo');
        [west.u_rot, west.v_rot] = vel_rot(cbry.u_west(:,:,t), center2face(cbry.v_west(:,:,t), 1),...
            repmat(rad2deg(west.angc)',1,N),'grid2geo');
        [north.u_rot, north.v_rot] = vel_rot(center2face(cbry.u_north(:,:,t),1), cbry.v_north(:,:,t),...
            repmat(rad2deg(north.angc),1,N),'grid2geo');
        [south.u_rot, south.v_rot] = vel_rot(center2face(cbry.u_south(:,:,t),1),cbry.v_south(:,:,t),...
            repmat(rad2deg(south.angc),1,N),'grid2geo');

        figure; clf; colormap(balance)
        ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
        axe(1) = nexttile; hold on
        mypcolor(repmat(east.lat_path,1,pN),east.parent_z,east.u_z)
        shading flat; 
        title("east u (parent)")
        axe(2) = nexttile; hold on
        mypcolor(repmat(east.bnd_lat',1,N),squeeze(east.child_z(:,:,t))',east.u_rot)
        shading flat; colorbar
        title("east u (child)")
        linkaxes(axe,'xy');
        
        axw(1) = nexttile; hold on
        mypcolor(repmat(west.lat_path,1,pN),west.parent_z,west.u_z)
        shading flat; 
        title("west u (parent)")
        axw(2) = nexttile; hold on
        mypcolor(repmat(west.bnd_lat',1,N),squeeze(west.child_z(:,:,t))',west.u_rot)
        shading flat; colorbar
        title("west u (child)")
        linkaxes(axw,'xy');

        axn(1) = nexttile; hold on
        mypcolor(repmat(north.lon_path,1,pN),north.parent_z,north.u_z)
        shading flat; 
        title("north u (parent)")
        axn(2) = nexttile; hold on
        mypcolor(repmat(north.bnd_lon,1,N),squeeze(north.child_z(:,:,t))',north.u_rot)
        shading flat; colorbar
        title("north u (child)")
        linkaxes(axn,'xy');

        axs(1) = nexttile; hold on
        mypcolor(repmat(south.lon_path,1,pN),south.parent_z,south.u_z)
        shading flat; 
        title("south u (parent)")
        axs(2) = nexttile; hold on
        mypcolor(repmat(south.bnd_lon,1,N),squeeze(south.child_z(:,:,t))',south.u_rot)
        shading flat; colorbar
        title("south u (child)")
        linkaxes(axs,'xy');

        clim([axe axw axn axs],[-1 1])
        saveas(gcf,append("check_u_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg")) 

        ylim([axe axw axn axs],[-100 0]); 
        saveas(gcf,append("check_zoomu_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg")) 
        disp(append("save check_u_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg"))


        figure; clf; colormap(balance)
        ti = tiledlayout(4,2); ti.Padding = "compact"; ti.TileSpacing = "tight";
        axe(1) = nexttile; hold on
        mypcolor(repmat(east.lat_path,1,pN),east.parent_z,east.v_z)
        shading flat; 
        title("east v (parent)")
        axe(2) = nexttile; hold on
        mypcolor(repmat(east.bnd_lat',1,N),squeeze(east.child_z(:,:,t))',east.v_rot)
        shading flat; colorbar
        title("east v (child)")
        linkaxes(axe,'xy');
        
        axw(1) = nexttile; hold on
        mypcolor(repmat(west.lat_path,1,pN),west.parent_z,west.v_z)
        shading flat; 
        title("west v (parent)")
        axw(2) = nexttile; hold on
        mypcolor(repmat(west.bnd_lat',1,N),squeeze(west.child_z(:,:,t))',west.v_rot)
        shading flat; colorbar
        title("west v (child)")
        linkaxes(axw,'xy');

        axn(1) = nexttile; hold on
        mypcolor(repmat(north.lon_path,1,pN),north.parent_z,north.v_z)
        shading flat; 
        title("north v (parent)")
        axn(2) = nexttile; hold on
        mypcolor(repmat(north.bnd_lon,1,N),squeeze(north.child_z(:,:,t))',north.v_rot)
        shading flat; colorbar
        title("north v (child)")
        linkaxes(axn,'xy');

        axs(1) = nexttile; hold on
        mypcolor(repmat(south.lon_path,1,pN),south.parent_z,south.v_z)
        shading flat; 
        title("south v (parent)")
        axs(2) = nexttile; hold on
        mypcolor(repmat(south.bnd_lon,1,N),squeeze(south.child_z(:,:,t))',south.v_rot)
        shading flat; colorbar
        title("south v (child)")
        linkaxes(axs,'xy');

        clim([axe axw axn axs],[-1 1])
        saveas(gcf,append("check_v_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg")) 

        ylim([axe axw axn axs],[-100 0]); 
        saveas(gcf,append("check_zoomv_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg")) 
        disp(append("save check_v_",datestr(cbry.bry_time(t) + t2,"yyyymmddHH"),".jpg"))
    end

end