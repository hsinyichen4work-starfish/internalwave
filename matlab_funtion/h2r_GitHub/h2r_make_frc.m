function h2r_make_frc(parent_G, parent_FLUX, parent_WIND, parent_PRESS, ...
    chdgrd, frcname, chd_ang, limits)
%--------------------------------------------------------------
%  Extract surface forcing fields from parent-NCOM files
%  (heaflx/salflx/solflx, stresu/stresv, slpres) and interpolate
%  horizontally onto the child-ROMS grid, writing every available
%  parent time step into frcname.
%
%  Unlike h2r_make_ini.m / h2r_bry_hv.m, this is a purely 2D
%  (horizontal-only) interpolation -- no zlevs3/get_hv_coef/A matrix,
%  since none of these fields have vertical structure.
%--------------------------------------------------------------

if nargin < 7
    chd_ang = 'rad';
end
[ndomx,ndomy] = size(limits);

%% --- Child grid ---
maskc_full = ncread(chdgrd, 'mask_rho')';
lonc_full  = ncread(chdgrd, 'lon_rho')';   %#ok<NASGU> -- kept for reference/debugging
latc_full  = ncread(chdgrd, 'lat_rho')';   %#ok<NASGU>
angc_full  = ncread(chdgrd, 'angle')';
if strcmp(chd_ang,'deg')
    angc_full = pi/180.0*angc_full;
end

%% --- Time base ---
MT = ncread(parent_WIND, 'MT');
nt = length(MT);
t1 = datenum(1900,12,31,0,0,0);
t2 = datenum(1994,1,1,0,0,0);

for tind = 1:nt
    ocean_time = double(MT(tind)) + t1 - t2;   % days, matches h2r_create_frc.m units
    ncwrite(frcname, 'sms_time',  ocean_time, tind);
    ncwrite(frcname, 'shf_time',  ocean_time, tind);
    ncwrite(frcname, 'swf_time',  ocean_time, tind);
    ncwrite(frcname, 'srf_time',  ocean_time, tind);
    ncwrite(frcname, 'pair_time', ocean_time, tind);
end

for domx = 1:ndomx
    for domy = 1:ndomy
        disp('-------------------------------------------------------------');
        disp(['  chunk domx=' num2str(domx) ' domy=' num2str(domy)]);

        L = limits(domx,domy);
        icb = L.icb; ice = L.ice;
        jcb = L.jcb; jce = L.jce;
        imin = L.imin; imax = L.imax;
        jmin = L.jmin; jmax = L.jmax;
        li = length(imin:imax);
        lj = length(jmin:jmax);

        maskc = maskc_full(jcb:jce, icb:ice);
        angc  = angc_full(jcb:jce, icb:ice);
        cosc  = cos(angc);
        sinc  = sin(angc);
        umask = maskc(:,1:end-1).*maskc(:,2:end);
        vmask = maskc(1:end-1,:).*maskc(2:end,:);

        lonc = ncread(chdgrd, 'lon_rho', [icb jcb], [length(icb:ice) length(jcb:jce)])';
        lonc(lonc<0) = lonc(lonc<0) + 360;
        latc = ncread(chdgrd, 'lat_rho', [icb jcb], [length(icb:ice) length(jcb:jce)])';

        lons = double(ncread(parent_G, 'Longitude', [imin jmin], [li lj]))';
        lats = double(ncread(parent_G, 'Latitude',  [imin jmin], [li lj]))';
        lons(lons<0) = lons(lons<0) + 360;

        %% --- Parent land/sea mask on the subgrid (from first flux time step) ---
        heaflx1 = double(ncread(parent_FLUX, 'heaflx', [imin jmin 1], [li lj 1]))';
        masks = ones(size(heaflx1));
        masks(isnan(heaflx1)) = 0;

        disp(['    parent subgrid: ' num2str(li) ' x ' num2str(lj)]);
        disp('    Computing interpolation coefficients');
        [elem2d,coef2d,nnel] = get_tri_coef(lons,lats,lonc,latc,masks);

        for tind = 1:nt

            disp(['    time step ' num2str(tind) ' of ' num2str(nt)]);

            %% --- Scalar fields: heaflx/salflx/solflx/slpres -> shflux/swflux/swrad/Pair ---
            scalars_in  = {'heaflx','salflx','solflx'};
            scalars_out = {'shflux','swflux','swrad'};

            for k = 1:numel(scalars_in)
                var = double(ncread(parent_FLUX, scalars_in{k}, [imin jmin tind], [li lj 1]))';
                var = fillmask(var,1,masks,nnel);
                varc = sum(coef2d.*var(elem2d), 3);
                varc = varc.*maskc;
                ncwrite(frcname, scalars_out{k}, varc', [icb jcb tind]);
            end

            pres = double(ncread(parent_PRESS, 'slpres', [imin jmin tind], [li lj 1]))';
            pres = fillmask(pres,1,masks,nnel);
            presc = sum(coef2d.*pres(elem2d), 3);
            presc = presc.*maskc;
            ncwrite(frcname, 'Pair', presc', [icb jcb tind]);

            %% --- Vector field: stresu/stresv -> sustr/svstr ---
            us = double(ncread(parent_WIND, 'stresu', [imin jmin tind], [li lj 1]))';
            vs = double(ncread(parent_WIND, 'stresv', [imin jmin tind], [li lj 1]))';
            us(isnan(us)) = 0;
            vs(isnan(vs)) = 0;
            us = fillmask(us, 0, masks, nnel);
            vs = fillmask(vs, 0, masks, nnel);

            ud = sum(coef2d.*us(elem2d), 3);
            vd = sum(coef2d.*vs(elem2d), 3);

            % Rotate from earth-relative (true east/north) to child grid orientation
            u_rho = ud.*cosc + vd.*sinc;
            v_rho = vd.*cosc - ud.*sinc;

            % Average from rho-like points to ROMS staggered u/v points
            sustr = 0.5*(u_rho(:,1:end-1) + u_rho(:,2:end));
            svstr = 0.5*(v_rho(1:end-1,:) + v_rho(2:end,:));

            sustr = sustr.*umask;
            svstr = svstr.*vmask;

            ncwrite(frcname, 'sustr', sustr', [icb jcb tind]);
            ncwrite(frcname, 'svstr', svstr', [icb jcb tind]);

        end   % time loop

    end   % domy
end   % domx

disp('>>> Finished writing frc file')

end