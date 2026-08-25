function limits = h2r_frc_subgrid(parentgrid,childgrid,ndomx,ndomy)
    %
    %   Find lower and upper index in i and j for the minimal parent
    %   grid that contains each (domx,domy) chunk of the child grid.
    %   Mirrors h2r_bry_subgrid.m, but for a chunked 2D domain instead
    %   of the 4 boundary perimeter strips.
    %
    %   Call this ONCE per (parentgrid,childgrid,ndomx,ndomy) combination
    %   and reuse the returned `limits` across every call to h2r_make_frc
    %   -- the geometry doesn't change across time steps or dates, only
    %   the data does, so there's no reason to redo the Delaunay/tsearch
    %   more than once.
    %
    %--------------------------------------------------------------
    
    Lonc = ncread(childgrid, 'lon_rho')';
    Lonc(Lonc<0) = Lonc(Lonc<0) + 360;
    Latc = ncread(childgrid, 'lat_rho')';
    
    lonp = double(ncread(parentgrid, 'Longitude'))';
    lonp(lonp<0) = lonp(lonp<0) + 360;
    latp = double(ncread(parentgrid, 'Latitude'))';
    
    [Mp,Lp] = size(lonp);
    
    disp('    Going delaunay on full parent grid (once)');
    tri_par = delaunay(lonp,latp);
    disp('    Return delaunay');
    
    [Mc,Lc] = size(Lonc);
    szx = floor(Lc/ndomx);
    szy = floor(Mc/ndomy);
    
    icmin = [0:ndomx-1]*szx;
    jcmin = [0:ndomy-1]*szy;
    icmax = [1:ndomx]*szx;
    jcmax = [1:ndomy]*szy;
    icmin(1) = 1;
    jcmin(1) = 1;
    icmax(end) = Lc;
    jcmax(end) = Mc;
    
    limits(ndomx,ndomy) = struct('imin',[],'imax',[],'jmin',[],'jmax',[], ...
                                  'icb',[],'ice',[],'jcb',[],'jce',[]);
    
    for domx = 1:ndomx
        for domy = 1:ndomy
    
            icb = icmin(domx); ice = icmax(domx);
            jcb = jcmin(domy); jce = jcmax(domy);
    
            lonc = Lonc(jcb:jce, icb:ice);
            latc = Latc(jcb:jce, icb:ice);
    
            t = squeeze(tsearch(lonp,latp,tri_par,lonc,latc));
    
            % Fix to deal with child points that are outside parent grid
            if (length(t(~isfinite(t)))>0)
                disp(['Warning in h2r_frc_subgrid: outside point(s) detected ' ...
                      'in chunk domx=' num2str(domx) ' domy=' num2str(domy)]);
                [lonc,latc] = fix_outside_child(lonc,latc,t);
                t = squeeze(tsearch(lonp,latp,tri_par,lonc,latc));
            end
    
            index       = tri_par(t,:);
            [idxj,idxi] = ind2sub([Mp Lp], index);
    
            limits(domx,domy).imin = max(1,  min(min(idxi))-1);
            limits(domx,domy).imax = min(Lp, max(max(idxi))+1);
            limits(domx,domy).jmin = max(1,  min(min(idxj))-1);
            limits(domx,domy).jmax = min(Mp, max(max(idxj))+1);
            limits(domx,domy).icb  = icb;
            limits(domx,domy).ice  = ice;
            limits(domx,domy).jcb  = jcb;
            limits(domx,domy).jce  = jce;
    
        end
    end
    
    end