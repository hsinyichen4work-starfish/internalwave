function h2r_make_ini(pargrd, par_tind, pariniu, pariniv, parinit, ...
    parinis, parinie, chd_grd, chd_data, chdscd, chdscoord, ...
    ndomx, ndomy,chd_ang,par_N)

% Get S-coordinate params for child grid
N_c       = chdscd.N;
theta_b_c = chdscd.theta_b;
theta_s_c = chdscd.theta_s;
hc_c      = chdscd.hc;

Np        = par_N;
% Get S-coordinate params for parent data file
tind = par_tind;

% Set correct time in ini file
t0 = double(ncread(pariniu, 'MT', tind,  1));
t1 = datenum(1900,12,31,0,0,0);
t2 = datenum(1994,1,1,0,0,0);

ocean_time = (t0 + t1 - t2)*24*60*60; % time in seconds

ncwrite(chd_data, 'ocean_time', ocean_time, 1);

% Get full parent grid and do triangulation
lonp = double(ncread(pargrd, 'Longitude'))';
latp = double(ncread(pargrd, 'Latitude'))';
[Mpp,Lpp]    = size(latp);
lonp(lonp<0) = lonp(lonp<0) + 360;

display('    Going delaunay');
tri_fullpar = delaunay(lonp,latp);
display('    Return delaunay');

% Get child grid and chunk size
h        = ncread(chd_grd, 'h')'; % bathymetry at RHO-points
[Mp,Lp]  = size(h);
szx      = floor(Lp/ndomx);
szy      = floor(Mp/ndomy);

icmin    = [0:ndomx-1]*szx;
jcmin    = [0:ndomy-1]*szy;
icmax    = [1:ndomx]*szx;
jcmax    = [1:ndomy]*szy;
icmin(1) = 1;
jcmin(1) = 1;
icmax(end) = Lp;
jcmax(end) = Mp;

% Do the interpolation for all child chunks
for domx = 1:ndomx
    for domy = 1:ndomy
        [domx domy]
        icb = icmin(domx);
        ice = icmax(domx);
        jcb = jcmin(domy);
        jce = jcmax(domy);
        
        li = length(icb:ice);
        lj = length(jcb:jce);
        liu = length(icb:ice-1);
        ljv = length(jcb:jce-1);
        
        % Get topography data from childgrid
        hc    = ncread(chd_grd, 'h', [icb jcb], [li lj])';
        maskc = ncread(chd_grd, 'mask_rho', [icb jcb], [li lj])';
        lonc  = ncread(chd_grd, 'lon_rho', [icb jcb], [li lj])';
        latc  = ncread(chd_grd, 'lat_rho', [icb jcb], [li lj])';
        angc  = ncread(chd_grd, 'angle', [icb jcb], [li lj])';
        if chd_ang=='deg'
            angc = pi/180.0*angc;
        end
        umask = maskc(:,1:end-1).*maskc(:,2:end);
        vmask = maskc(1:end-1,:).*maskc(2:end,:);
        cosc  = cos(angc);
        sinc  = sin(angc);
        lonc(lonc<0) = lonc(lonc<0) + 360;
        
        % Compute minimal subgrid extracted from full parent grid
        t = squeeze(tsearch(lonp,latp,tri_fullpar,lonc,latc));
        
        % Deal with child points that are outside parent grid (those points should be masked!)
        if (length(t(~isfinite(t)))>0);
            disp('    Warning in new_bry_subgrid: outside point(s) detected.');
            [lonc,latc] = fix_outside_child(lonc,latc,t);
            t  = squeeze(tsearch(lonp,latp,tri_fullpar,lonc,latc));
        end;
        %figure; plot(lonp,latp,'r.',lonc,latc,'b.')
        %pause
        index       = tri_fullpar(t,:);
        [idxj,idxi] = ind2sub([Mpp Lpp], index);
        
        imin = min(min(idxi)) ; imin = max(1, imin-1) ;
        imax = max(max(idxi)) ; imax = min(imax+1, Lpp) ;
        jmin = min(min(idxj)) ; jmin = max(1, jmin-1);
        jmax = max(max(idxj)) ; jmax = min(jmax+1, Mpp);
        lpi = length(imin:imax);
        lpj = length(jmin:jmax);
        lpiu = length(imin:imax-1);
        lpjv = length(jmin:jmax-1);
        
        % Get parent grid and squeeze minimal subgrid
        
        etas  = double(ncread(parinie, 'ssh', [imin jmin tind], [lpi lpj 1]))';
        size(etas)
        masks = ones(size(etas));
        masks(isnan(etas))=0;
        lons  = double(ncread(pargrd, 'Longitude', [imin jmin], [lpi lpj]))';
        lats  = double(ncread(pargrd, 'Latitude', [imin jmin], [lpi lpj]))';
        lons(lons<0) = lons(lons<0) + 360;
        
        
        % Z-coordinate (3D) on minimal subgrid and child grid
        zstt = double(ncread(pargrd,'layer_thickness', [imin jmin 1 tind], [lpi lpj Np 1]));
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
        
        [zc, Cs_r]  = zlevs3(hc, hc*0, theta_s_c, theta_b_c, hc_c, N_c, ...
            'r', chdscoord);
        
        size(zc)
        zc(50,300,300)
        zs(41,30,30)
        
        [zw, Cs_w] = zlevs3(hc, hc*0, theta_s_c, theta_b_c, hc_c, N_c, ...
            'w', chdscoord);
        [Np, Mp, Lp] = size(zs);
        [Nc, Mc, Lc] = size(zc);
        
        disp('    Computing interpolation coefficients');
        [elem2d,coef2d,nnel] = get_tri_coef(lons,lats,lonc,latc,masks);
        A = get_hv_coef(zs, zc, coef2d, elem2d, lons, lats, lonc, latc);
        
        % Open parent data file
        
        disp('    => zeta')
        zetas = squeeze(ncread(parinie, 'ssh', [imin jmin tind], [lpi lpj 1]))';
        zetas = fillmask(zetas, 1, masks, nnel);
        zetac = sum(coef2d.*zetas(elem2d), 3);
        zetac     = zetac.*maskc;
        
        disp('    => temp')
        var = squeeze(ncread(parinit, 'layer_temperature', [imin jmin 1 tind], [lpi lpj Np 1]));
        var = flipud(permute(var, [3 2 1]));
        var = double(fillmask(var,1,masks,nnel));
        var = inpaint_nans(var,4);
        ini_temp = reshape(A*reshape(var,Np*Mp*Lp,1),Nc,Mc,Lc);
        ini_temp = fillmissing(ini_temp,'linear',2,'EndValues','nearest');
        disp('    => salt')
        var = squeeze(ncread(parinis, 'layer_salinity', [imin jmin 1 tind], [lpi lpj Np 1]));
        var = flipud(permute(var, [3 2 1]));
        var = double(fillmask(var,1,masks,nnel));
        var = inpaint_nans(var,4);
        ini_salt = reshape(A*reshape(var,Np*Mp*Lp,1),Nc,Mc,Lc);
        ini_salt = fillmissing(ini_salt,'linear',2,'EndValues','nearest');
        
        % Read in staggered velocities
        disp('    => total velocity');
        ud = squeeze(ncread(pariniu, 'u_velocity', [imin jmin 1 tind], [lpi lpj Np 1]));
        ud = flipud(permute(ud,[3 2 1]));
        
        vd = squeeze(ncread(pariniv, 'v_velocity', [imin jmin 1 tind], [lpi lpj Np 1]));
        vd = flipud(permute(vd,[3 2 1]));
        
        us = ud;
        vs = vd;
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
        
        
        % Back to staggered locations
        u = 0.5*(us(:,:,1:Lc-1) + us(:,:,2:Lc));
        v = 0.5*(vs(:,1:Mc-1,:) + vs(:,2:Mc,:));
        
        % Get barotropic velocity
        disp('    => barotropic velocity');
        dz  = zw(2:end,:,:)-zw(1:end-1,:,:);
        dzu = 0.5*(dz(:,:,1:end-1)+dz(:,:,2:end));
        dzv = 0.5*(dz(:,1:end-1,:)+dz(:,2:end,:));
        hu   = sum(dzu.*u); hv   = sum(dzv.*v);
        D_u  = sum(dzu);    D_v  = sum(dzv);
        ubar = squeeze(hu./D_u);     vbar = squeeze(hv./D_v);
        ubar      = ubar.*umask;
        vbar      = vbar.*vmask;
        
        % Zero-ing out the mask
        for k = 1:Nc
            ini_temp(k,:,:) = squeeze(ini_temp(k,:,:)).*maskc;
            ini_salt(k,:,:) = squeeze(ini_salt(k,:,:)).*maskc;
            u(k,:,:)        = squeeze(u(k,:,:)).*umask;
            v(k,:,:)        = squeeze(v(k,:,:)).*vmask;
        end
        
        ini_temp = permute(ini_temp, [3 2 1]);
        ini_salt = permute(ini_salt, [3 2 1]);
        u    = permute(u, [3 2 1]);
        v    = permute(v, [3 2 1]);
        zetac= zetac';
        ubar = ubar';
        vbar = vbar';
        
        disp('>>> Writing ini file')
        ncwrite(chd_data, 'Cs_w', Cs_w);
        ncwrite(chd_data, 'Cs_r', Cs_r);
        ncwrite(chd_data, 'temp', ini_temp, [icb jcb 1 1]);
        ncwrite(chd_data, 'salt', ini_salt, [icb jcb 1 1]);
        ncwrite(chd_data, 'u', u, [icb jcb 1 1]);
        ncwrite(chd_data, 'v', v, [icb jcb 1 1]);
        ncwrite(chd_data, 'zeta', zetac, [icb jcb 1]);
        ncwrite(chd_data, 'ubar', ubar, [icb jcb 1]);
        ncwrite(chd_data, 'vbar', vbar, [icb jcb 1]);
    end
end
