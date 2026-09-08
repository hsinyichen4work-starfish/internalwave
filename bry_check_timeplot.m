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

dating = datenum("20220822","yyyymmdd") : datenum("20221126","yyyymmdd");
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
Np = size(z_grid,3);
%%
cbry_name = ['roms_bry_',num2str(dx),'m_',datestr(dating(1),"yyyymmddHH"),'.nc'];
cbry = read_nc_fun([child_bry_path,cbry_name]);
theta_s = cbry.theta_s; theta_b = cbry.theta_b; 
hc = cbry.hc; N = size(cbry.temp_south,2); pN = size(z_grid,3);

%% extract point (one check point per boundary)
[ny, nx] = size(lon);
nchose = 400;
sides = ["south","north","west","east"];
[nxi_c, neta_c] = size(cgrid.lon_rho);   % dim1=xi_rho, dim2=eta_rho (ncread reverses file dim order)

% (row,col) into cgrid.lon_rho/h/angle for each side's check point
side_rc = struct('south',[nchose,1], 'north',[nchose,neta_c], ...
                  'west',[1,nchose],  'east',[nxi_c,nchose]);
% which velocity component is on the staggered grid (needs center2face) for
% each side: south/north vary along xi -> u_<side> is on xi_u (1 pt short);
% east/west vary along eta -> v_<side> is on eta_v (1 pt short)
side_stagger = struct('south','u', 'north','u', 'west','v', 'east','v');

bnd = struct();
for si = 1:numel(sides)
    s = sides(si); rc = side_rc.(s);
    bnd.(s).bnd_lon_pt = cgrid.lon_rho(rc(1),rc(2));
    bnd.(s).bnd_lat_pt = cgrid.lat_rho(rc(1),rc(2));
    [bnd.(s).iy_pt, bnd.(s).ix_pt, bnd.(s).dist_km] = ...
        find_nearest_indices(lon,lat,bnd.(s).bnd_lon_pt,bnd.(s).bnd_lat_pt);
    bnd.(s).lin_idx = sub2ind([ny, nx], bnd.(s).iy_pt, bnd.(s).ix_pt);
    bnd.(s).bath    = pgrid.h(bnd.(s).lin_idx);
    bnd.(s).bathc   = cgrid.h(rc(1),rc(2));
    bnd.(s).angc    = cgrid.angle(rc(1),rc(2));
end
%%
cd(figure_path)
figure; clf; hold on
grid_boundary_plot(cgrid.lon_rho,cgrid.lat_rho,[1 0 0],2)
for si = 1:numel(sides)
    s = sides(si);
    scatter(bnd.(s).bnd_lon_pt,bnd.(s).bnd_lat_pt,80,'filled')
    scatter(lon(bnd.(s).iy_pt,bnd.(s).ix_pt),lat(bnd.(s).iy_pt,bnd.(s).ix_pt))
    text(bnd.(s).bnd_lon_pt,bnd.(s).bnd_lat_pt,"  "+s)
end
saveas(gcf,"check_rightpt.jpg")
saveas(gcf,"check_rightpt.fig")
%%
cd(figure_path)
if ~isfolder('ssh_check'); mkdir('ssh_check'); end
cd ssh_check
fi = figure(1); clf; hold on; fi.Position = [1 1 1207 700];
tiledlayout(2,2);
axz = struct();
for si = 1:numel(sides)
    s = sides(si);
    axz.(s) = nexttile; hold on; title(s)
end
for folder_num = 1 : length(fod)
    disp(fod(folder_num))
    zeta = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"ssh");
    nctime = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"MT");
    cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
    cbry = read_nc_fun(append(child_bry_path,cbry_name));

    nctime_dn  = nctime + t1;          % NCOM MT (days since 1900-12-31) -> absolute datenum
    brytime_dn = cbry.bry_time + t2;   % ROMS bry_time (days since 1994-01-01) -> absolute datenum

    for si = 1:numel(sides)
        s = sides(si);
        zeta_child = cbry.(sprintf('zeta_%s',s))(nchose,:);
        axes(axz.(s)); %#ok<LAXES>
        plot(brytime_dn,zeta_child,...
            "color","r","LineWidth",1,"Marker","o","MarkerSize",8);
        plot(nctime_dn,squeeze(zeta(bnd.(s).iy_pt,bnd.(s).ix_pt,:)), ...
                "color","b","LineWidth",2,"LineStyle","--",...
                "Marker","o","MarkerSize",4);
    end
end
axz_all = struct2cell(axz); axz_all = [axz_all{:}];
for a = axz_all; datetick(a,'x','mm/dd'); end
linkaxes(axz_all,"xy");
saveas(gcf,"zeta_checktime.jpg")
saveas(gcf,"zeta_checktime.fig")
%%
cd(figure_path)
if ~isfolder('temp_check'); mkdir('temp_check'); end
cd temp_check
figt = struct(); axt = struct(); axt2 = struct();
for si = 1:numel(sides)
    s = sides(si);
    figt.(s) = figure(10+si); clf; hold on; figt.(s).Position = [1 1 1207 602];
    tiledlayout(2,2);
    axt.(s) = [nexttile, nexttile]; hold(axt.(s)(1),'on'); hold(axt.(s)(2),'on')
    axt2.(s) = nexttile([1,2]); hold on
    title(axt.(s)(1), s+" temp (child)"); title(axt.(s)(2), s+" temp (parent)")
end
for folder_num = 1 : length(fod)
    disp(fod(folder_num))
    temp = ncread(append(nc_path_ini_bry,fod(folder_num),'_ts.nc'),"layer_temperature");
    nctime = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"MT");
    cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
    cbry = read_nc_fun(append(child_bry_path,cbry_name));

    nctime_dn  = nctime + t1;          % NCOM MT (days since 1900-12-31) -> absolute datenum
    brytime_dn = cbry.bry_time + t2;   % ROMS bry_time (days since 1994-01-01) -> absolute datenum
    ntime = length(brytime_dn);

    for si = 1:numel(sides)
        s = sides(si);
        zeta_child  = cbry.(sprintf('zeta_%s',s))(nchose,:);
        temp_child  = squeeze(cbry.(sprintf('temp_%s',s))(nchose,:,:));   % [N x ntime]
        child_z     = squeeze(zlevs3(repmat(bnd.(s).bathc,1,ntime), ...
            zeta_child, theta_s, theta_b, hc, N, 'r', 'new2008'));

        parent_z_pt = flip(squeeze(z_grid(bnd.(s).iy_pt,bnd.(s).ix_pt,:)));
        temp_parent = squeeze(temp(bnd.(s).iy_pt,bnd.(s).ix_pt,:,:));     % [pN x ntime]

        temp_10dep = nan(1,ntime); temp_10depnc = nan(1,ntime);
        for tt = 1:ntime
            temp_10dep(tt)   = interp1(child_z(:,tt), temp_child(:,tt), -10);
            temp_10depnc(tt) = interp1(parent_z_pt, temp_parent(:,tt), -10);
        end

        axes(axt.(s)(1)); %#ok<LAXES>
        mypcolor(repmat(brytime_dn(:)',N,1),child_z,temp_child);
        axes(axt.(s)(2)); %#ok<LAXES>
        mypcolor(repmat(nctime_dn(:)',Np,1),repmat(parent_z_pt,1,ntime),temp_parent);
        axes(axt2.(s)); %#ok<LAXES>
        plot(brytime_dn,temp_10dep,"color","r","LineWidth",1,"Marker","o","MarkerSize",8)
        plot(nctime_dn,temp_10depnc,"color","b","LineWidth",2,"LineStyle","--","Marker","o","MarkerSize",4);
    end
end
for si = 1:numel(sides)
    s = sides(si);
    for a = [axt.(s), axt2.(s)]; datetick(a,'x','mm/dd'); end
    linkaxes(axt.(s),"xy");
    saveas(figt.(s),"temp_checktime_"+s+".jpg")
    saveas(figt.(s),"temp_checktime_"+s+".fig")
end
%%
cd(figure_path)
if ~isfolder('vel_check'); mkdir('vel_check'); end
cd vel_check

figu = struct(); axu = struct(); axu2 = struct();
figv = struct(); axv = struct(); axv2 = struct();
for si = 1:numel(sides)
    s = sides(si);
    figu.(s) = figure(20+si); clf; hold on; figu.(s).Position = [1 1 1207 602];
    tiledlayout(2,2);
    axu.(s) = [nexttile, nexttile]; hold(axu.(s)(1),'on'); hold(axu.(s)(2),'on')
    axu2.(s) = nexttile([1,2]); hold on
    title(axu.(s)(1), s+" u (child)"); title(axu.(s)(2), s+" u (parent)")

    figv.(s) = figure(30+si); clf; hold on; figv.(s).Position = [1 1 1207 602];
    tiledlayout(2,2);
    axv.(s) = [nexttile, nexttile]; hold(axv.(s)(1),'on'); hold(axv.(s)(2),'on')
    axv2.(s) = nexttile([1,2]); hold on
    title(axv.(s)(1), s+" v (child)"); title(axv.(s)(2), s+" v (parent)")
end

for folder_num = 1 : length(fod)
    disp(fod(folder_num))
    u = ncread(append(nc_path_ini_bry,fod(folder_num),'_uv.nc'),"u_velocity");
    v = ncread(append(nc_path_ini_bry,fod(folder_num),'_uv.nc'),"v_velocity");
    nctime = ncread(append(nc_path_ini_bry,fod(folder_num),'_ssh.nc'),"MT");
    cbry_name = append('roms_bry_',num2str(dx),'m_',fod(folder_num),'.nc');
    cbry = read_nc_fun(append(child_bry_path,cbry_name));

    nctime_dn  = nctime + t1;          % NCOM MT (days since 1900-12-31) -> absolute datenum
    brytime_dn = cbry.bry_time + t2;   % ROMS bry_time (days since 1994-01-01) -> absolute datenum
    ntime = length(brytime_dn);

    for si = 1:numel(sides)
        s = sides(si);
        zeta_child = cbry.(sprintf('zeta_%s',s))(nchose,:);
        child_z = squeeze(zlevs3(repmat(bnd.(s).bathc,1,ntime), ...
            zeta_child, theta_s, theta_b, hc, N, 'r', 'new2008'));

        u_raw = cbry.(sprintf('u_%s',s));
        v_raw = cbry.(sprintf('v_%s',s));
        % pad whichever component is staggered for this side onto the rho
        % grid, then rotate the ROMS grid-relative (xi,eta) components into
        % true east/north with the child grid angle -- parent NCOM u/v are
        % already true east/north, so they need no rotation.
        if side_stagger.(s) == 'u'
            u_raw = center2face(u_raw, 1);
        else
            v_raw = center2face(v_raw, 1);
        end
        u_pt = squeeze(u_raw(nchose,:,:));   % [N x ntime]
        v_pt = squeeze(v_raw(nchose,:,:));
        [u_rot, v_rot] = vel_rot(u_pt, v_pt, rad2deg(bnd.(s).angc), 'grid2geo');

        parent_z_pt = flip(squeeze(z_grid(bnd.(s).iy_pt,bnd.(s).ix_pt,:)));
        u_parent = squeeze(u(bnd.(s).iy_pt,bnd.(s).ix_pt,:,:));
        v_parent = squeeze(v(bnd.(s).iy_pt,bnd.(s).ix_pt,:,:));

        u_10dep = nan(1,ntime); u_10depnc = nan(1,ntime);
        v_10dep = nan(1,ntime); v_10depnc = nan(1,ntime);
        for tt = 1:ntime
            u_10dep(tt)   = interp1(child_z(:,tt), u_rot(:,tt), -10);
            v_10dep(tt)   = interp1(child_z(:,tt), v_rot(:,tt), -10);
            u_10depnc(tt) = interp1(parent_z_pt, u_parent(:,tt), -10);
            v_10depnc(tt) = interp1(parent_z_pt, v_parent(:,tt), -10);
        end

        axes(axu.(s)(1)); %#ok<LAXES>
        mypcolor(repmat(brytime_dn(:)',N,1),child_z,u_rot);
        axes(axu.(s)(2)); %#ok<LAXES>
        mypcolor(repmat(nctime_dn(:)',Np,1),repmat(parent_z_pt,1,ntime),u_parent);
        axes(axu2.(s)); %#ok<LAXES>
        plot(brytime_dn,u_10dep,"color","r","LineWidth",1,"Marker","o","MarkerSize",8)
        plot(nctime_dn,u_10depnc,"color","b","LineWidth",2,"LineStyle","--","Marker","o","MarkerSize",4);

        axes(axv.(s)(1)); %#ok<LAXES>
        mypcolor(repmat(brytime_dn(:)',N,1),child_z,v_rot);
        axes(axv.(s)(2)); %#ok<LAXES>
        mypcolor(repmat(nctime_dn(:)',Np,1),repmat(parent_z_pt,1,ntime),v_parent);
        axes(axv2.(s)); %#ok<LAXES>
        plot(brytime_dn,v_10dep,"color","r","LineWidth",1,"Marker","o","MarkerSize",8)
        plot(nctime_dn,v_10depnc,"color","b","LineWidth",2,"LineStyle","--","Marker","o","MarkerSize",4);
    end
end
for si = 1:numel(sides)
    s = sides(si);
    for a = [axu.(s), axu2.(s)]; datetick(a,'x','mm/dd'); end
    linkaxes(axu.(s),"xy");
    saveas(figu.(s),"u_checktime_"+s+".jpg")
    saveas(figu.(s),"u_checktime_"+s+".fig")

    for a = [axv.(s), axv2.(s)]; datetick(a,'x','mm/dd'); end
    linkaxes(axv.(s),"xy");
    saveas(figv.(s),"v_checktime_"+s+".jpg")
    saveas(figv.(s),"v_checktime_"+s+".fig")
end
%%