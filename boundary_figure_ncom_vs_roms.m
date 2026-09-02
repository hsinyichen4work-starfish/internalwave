clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'));
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
hc = cbry.hc; N = size(cbry.temp_south,2);
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
%for folder_num = 1 : length(fod)
    folder_num = 1;
    zeta = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"ssh");
    cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
    cbry = read_nc_fun(append(child_bry_path,cbry_name));

    for t = 1 : length(cbry.bry_time)
        dum = zeta(:,:,t);
        cd(figure_path)
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
%end