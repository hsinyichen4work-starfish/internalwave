%% Diagnostic: isolate west boundary (bnd=4) write behavior, one time step only

% -- 1. Check what h2r_create_bry.m actually declared for temp_west --
info = ncinfo(bry_filename, 'temp_west');
disp('temp_west as DECLARED in the boundary file:')
disp(info.Size)          % compare this against what h2r_bry_hv.m will try to write
disp({info.Dimensions.Name})
disp({info.Dimensions.Length})

% For comparison, check a working boundary (e.g. south) the same way:
info_s = ncinfo(bry_filename, 'temp_south');
disp('temp_south as DECLARED (for comparison):')
disp(info_s.Size)

%% -- 2. Run west's own setup code standalone, with full error reporting --
bnd = 4;
imin = limits(bnd,1); imax = limits(bnd,2);
jmin = limits(bnd,3); jmax = limits(bnd,4);
lj = length(jmin:jmax);
li = length(imin:imax);
i0 = 1; i1 = 2; j0 = 1; j1 = mpc;   % mpc must exist -- from size(ncread(chdgrd,'h')')
ljc = length(j0:j1);
lic = length(i0:i1);

try
    hc    = ncread(chdgrd, 'h', [i0 j0], [lic ljc])';
    maskc = ncread(chdgrd, 'mask_rho', [i0 j0], [lic ljc])';
    lonc  = ncread(chdgrd, 'lon_rho', [i0 j0], [lic ljc])';
    latc  = ncread(chdgrd, 'lat_rho', [i0 j0], [lic ljc])';

    etas  = double(ncread(parinie, 'ssh', [imin jmin 1], [li lj 1]))';
    masks = ones(size(etas)); masks(isnan(etas)) = 0;

    disp(['West window size (li x lj): ' num2str(li) ' x ' num2str(lj)]);
    disp(['Valid (unmasked) parent points in west window: ' num2str(sum(masks(:))) ...
          ' / ' num2str(numel(masks))]);
    disp(['Valid (unmasked) child points in west strip: ' num2str(sum(maskc(:))) ...
          ' / ' num2str(numel(maskc))]);

    lons = double(ncread(pargrd, 'Longitude', [imin jmin], [li lj]))';
    lats = double(ncread(pargrd, 'Latitude',  [imin jmin], [li lj]))';
    lons(lons<0) = lons(lons<0) + 360;
    lonc(lonc<0) = lonc(lonc<0) + 360;

    [elem2d, coef2d, nnel] = get_tri_coef(lons, lats, lonc, latc, masks);
    disp(['get_tri_coef succeeded. size(coef2d): ' mat2str(size(coef2d))]);
    disp(['Any NaN in coef2d: ' num2str(any(isnan(coef2d(:))))]);

catch ME
    disp('--- ERROR CAUGHT ---')
    disp(ME.message)
    for k = 1:numel(ME.stack)
        disp([ME.stack(k).name ' , line ' num2str(ME.stack(k).line)])
    end
end