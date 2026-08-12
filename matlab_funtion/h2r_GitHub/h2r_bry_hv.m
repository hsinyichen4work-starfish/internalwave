function h2r_bry_hv(pargrd, chdgrd,parinie, parinit, pariniu, Np,  ...
    bry_filename,chdscd, ...
    obcflag, limits,ii)
%--------------------------------------------------------------
%  Extract arbitrary variables from parent-HYCOM history file
%  to save in boundary perimeter files on child-ROMS grid.
%
%--------------------------------------------------------------
%

% Get S-coordinate params for child grid
theta_b_c = chdscd.theta_b;
theta_s_c = chdscd.theta_s;
hc_c      = chdscd.hc;
N_c       = chdscd.N;
scoord_c  = chdscd.scoord;

[mpc,npc] = size(ncread(chdgrd, 'h')');

% Set bry_time

t0 = ncread(pariniu,'MT', 1 , 1);
t1 = datenum(1900,12,31,0,0,0);
t2 = datenum(1994,1,1,0,0,0);

ocean_time = t0 + t1 - t2;
tind = 1;
tout = ii;

ncwrite(bry_filename, 'bry_time', ocean_time, tout);

for bnd = 1:4
    disp('-------------------------------------------------------------')
    if ~obcflag(bnd)
        disp('Closed boundary')
        continue
    end
    if bnd==1
        disp('South boundary')
        i0 =  1;
        i1 = npc;
        j0 = 1;
        j1 = 2;
    end
    if bnd==2
        disp('East boundary')
        i0 = npc-1;
        i1 = npc;
        j0 = 1;
        j1 = mpc;
    end
    if bnd==3
        disp('North boundary')
        i0 = 1;
        i1 = npc;
        j0 = mpc-1;
        j1 = mpc;
    end
    if bnd==4
        disp('West boundary')
        i0 = 1;
        i1 = 2;
        j0 = 1;
        j1 = mpc;
    end
    
    % Compute minimal subgrid extracted from parent grid
    imin = limits(bnd,1); imax = limits(bnd,2);
    jmin = limits(bnd,3); jmax = limits(bnd,4);
    
    lj = length(jmin:jmax);
    li = length(imin:imax);
    ljc = length(j0:j1);
    lic = length(i0:i1);
    
    % Get topography data from childgrid
    
    hc    = ncread(chdgrd, 'h', [i0 j0], [lic ljc])';
    maskc = ncread(chdgrd, 'mask_rho', [i0 j0], [lic ljc])';
    angc  = ncread(chdgrd, 'angle', [i0 j0], [lic ljc])';
    lonc  = ncread(chdgrd, 'lon_rho', [i0 j0], [lic ljc])';
    latc  = ncread(chdgrd, 'lat_rho', [i0 j0], [lic ljc])';
    lonc(lonc<0) = lonc(lonc<0) + 360;
    cosc  = cos(angc);         sinc  = sin(angc);
    
    [Mc,Lc] = size(maskc);
    maskc3d = zeros(N_c,Mc,Lc);
    for k = 1:N_c
        maskc3d(k,:,:) = maskc;
    end
    umask = maskc3d(:,:,2:end).*maskc3d(:,:,1:end-1);
    vmask = maskc3d(:,2:end,:).*maskc3d(:,1:end-1,:);
    
    % Get parent grid and squeeze minimal subgrid
    
    etas  = double(ncread(parinie, 'ssh', [imin jmin tind], [li lj 1]))';
    size(etas)
    masks = ones(size(etas));
    masks(isnan(etas))= 0;
    lons  = double(ncread(pargrd, 'Longitude', [imin jmin], [li lj]))';
    lats  = double(ncread(pargrd, 'Latitude', [imin jmin], [li lj]))';
    lons(lons<0) = lons(lons<0) + 360;
    
    % Z-coordinate (3D) on minimal subgrid and child grid
    % Sasha recommends the 0 multiplication
    
    zstt = double(ncread(pargrd,'layer_thickness', [imin jmin 1 tind], [li lj Np 1]));
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
    
    zs = flipud(zs);
    
    zc = zlevs3(hc, hc*0, theta_s_c, theta_b_c, hc_c, N_c, 'r', scoord_c);
    zw = zlevs3(hc, hc*0, theta_s_c, theta_b_c, hc_c, N_c, 'w', scoord_c);
    
    [Np,Mp,Lp] = size(zs);
    [Nc,Mc,Lc] = size(zc);
    
    
    disp('Computing interpolation coefficients');
    [elem2d,coef2d,nnel] = get_tri_coef(lons,lats,lonc,latc,masks);
    A = get_hv_coef(zs, zc, coef2d, elem2d, lons, lats, lonc, latc);
    
    %   Surface elevation on minimal subgrid and child grid
    zetas = (ncread(parinie, 'ssh', [imin jmin tind], [li lj 1]))';
    zetas = fillmask(zetas, 1, masks, nnel);
    zetac = sum(coef2d.*zetas(elem2d), 3);
    zetac = zetac.*maskc;
    
    
    %   Prepare for estimating barotropic velocity
    dz  = zw(2:end,:,:)-zw(1:end-1,:,:);
    dzu = 0.5*(dz(:,:,1:end-1)+dz(:,:,2:end));
    dzv = 0.5*(dz(:,1:end-1,:)+dz(:,2:end,:));
    
    %   Process scalar 3D variables
    for vint = 1:2 % Loop on the tracers
        if (vint==1)
            svar='layer_temperature';
            svarh = 'temp';
        elseif (vint==2)
            svar='layer_salinity';
            svarh = 'salt';
        end
        
        lj = length(jmin:jmax);
        li = length(imin:imax);
        
        disp(['--- ' svar])
        var = ncread(parinit, svar, [imin, jmin,1, tind], [li,lj,Np,1]);
        var = flipud(permute(var, [3 2 1]));
        var = fillmask(var,1,masks,nnel);
        var = inpaint_nans(var,4);
        [Np,Mp,Lp] = size(var);
        var = reshape(A*reshape(double(var),Np*Mp*Lp,1),Nc,Mc,Lc);
        var = fillmissing(var,'linear',2,'EndValues','nearest');
        var = var.*maskc3d;   % zero-ing out masked areas
        
        if (bnd ==1 )
            ncwrite(bry_filename, [svarh, '_south'],  squeeze(var(:, 1, :))',[1 1 tout]);
        end
        if (bnd ==2 )
            ncwrite(bry_filename, [svarh, '_east'],  squeeze(var(:, :, end))',[1 1 tout]);
        end
        if (bnd == 3 )
            ncwrite(bry_filename, [svarh, '_north'],  squeeze(var(:, end, :))',[1 1 tout]);
        end
        if (bnd == 4 )
            ncwrite(bry_filename, [svarh, '_west'],  squeeze(var(:, :, 1))',[1 1 tout]);
        end
    end  % End loop on vint
    
    %  Read in staggered velocities and move to rho-points
    
    ud = ncread(pariniu, 'u_velocity', [imin-1, jmin,1, tind], [length(imin-1:imax),lj,Np,1]);
    ud = flipud(permute(ud,[3 2 1]));
    ur = 0.5*(ud(:,:,1:end-1) + ud(:,:,2:end));
    
    vd = ncread(pariniu, 'v_velocity', [imin, jmin-1,1, tind], [li,length(jmin-1:jmax),Np,1]);
    vd = flipud(permute(vd,[3 2 1]));
    vr = 0.5*(vd(:,1:end-1,:) + vd(:,2:end,:));
    
    % 3d interpolation of us and vs to child grid
    us = ur;
    vs = vr;
    us(isnan(us))=0;
    vs(isnan(vs))=0;
    us = fillmask(us, 0, masks, nnel);
    vs = fillmask(vs, 0, masks, nnel);
    ud = reshape(A*reshape(us, Np*Mp*Lp,1), Nc,Mc,Lc);
    vd = reshape(A*reshape(vs, Np*Mp*Lp,1), Nc,Mc,Lc);
    
    % Rotate to child orientation
    us = zeros(Nc, Mc, Lc);
    vs = zeros(Nc, Mc, Lc);
    for k=1:Nc
        us(k,:,:) = squeeze(ud(k,:,:)).*cosc + squeeze(vd(k,:,:)).*sinc;
        vs(k,:,:) = squeeze(vd(k,:,:)).*cosc - squeeze(ud(k,:,:)).*sinc;
    end
    
    %% back to staggered u and v points
    u = 0.5*(us(:,:,1:Lc-1) + us(:,:,2:Lc));
    v = 0.5*(vs(:,1:Mc-1,:) + vs(:,2:Mc,:));
    
    u = u.*umask;
    v = v.*vmask;
    
    % Get barotropic velocity
    if sum(isnan(u)) > 0
        error('nans in u velocity!')
    end
    if sum(isnan(v)) > 0
        error('nans in v velocity!')
    end
    
    hu   = sum(dzu.*u); hv   = sum(dzv.*v);
    D_u  = sum(dzu);    D_v  = sum(dzv);
    [dum,Mu,Lu] = size(hu);
    [dum,Mv,Lv] = size(hv);
    ubar = reshape(hu./D_u,Mu, Lu);
    vbar = reshape(hv./D_v,Mv, Lv);
    
    % Save perimeter zeta, ubar, vbar, u and v data to bryfile
    
    if (bnd ==1)
        ncwrite(bry_filename, 'ubar_south',  squeeze(ubar(1, :))',[1 tout]);
        ncwrite(bry_filename, 'vbar_south',  squeeze(vbar(1, :))',[1 tout]);
        ncwrite(bry_filename, 'zeta_south',  squeeze(zetac(1, :))',[1 tout]);
        ncwrite(bry_filename, 'u_south',  squeeze(u(:, 1, :))',[1 1 tout]);
        ncwrite(bry_filename, 'v_south',  squeeze(v(:, 1, :))',[1 1 tout]);
    end
    if (bnd == 2)
        ncwrite(bry_filename, 'ubar_east',  squeeze(ubar(:, Lu)),[1 tout]);
        ncwrite(bry_filename, 'vbar_east',  squeeze(vbar(:, Lv)),[1 tout]);
        ncwrite(bry_filename, 'zeta_east',  squeeze(zetac(:, Lc)),[1 tout]);
        ncwrite(bry_filename, 'u_east',  squeeze(u(:, : , Lu))',[1 1 tout]);
        ncwrite(bry_filename, 'v_east',  squeeze(v(:, :, Lv ))',[1 1 tout]);
    end
    if (bnd == 3)
        ncwrite(bry_filename, 'ubar_north',  squeeze(ubar(Mu, :))',[1 tout]);
        ncwrite(bry_filename, 'vbar_north',  squeeze(vbar(Mv, :))',[1 tout]);
        ncwrite(bry_filename, 'zeta_north',  squeeze(zetac(Mc, :))',[1 tout]);
        ncwrite(bry_filename, 'u_north',  squeeze(u(:, Mu, :))',[1 1 tout]);
        ncwrite(bry_filename, 'v_north',  squeeze(v(:, Mv, :))',[1 1 tout]);
    end
    if (bnd == 4)
        ncwrite(bry_filename, 'ubar_west',  squeeze(ubar(:, 1)),[1 tout]);
        ncwrite(bry_filename, 'vbar_west',  squeeze(vbar(:, 1)),[1 tout]);
        ncwrite(bry_filename, 'zeta_west',  squeeze(zetac(:, 1)),[1 tout]);
        ncwrite(bry_filename, 'u_west',  squeeze(u(:, :, 1))',[1 1 tout]);
        ncwrite(bry_filename, 'v_west',  squeeze(v(:, :, 1))',[1 1 tout]);
    end
    
end    %  End loop bnd