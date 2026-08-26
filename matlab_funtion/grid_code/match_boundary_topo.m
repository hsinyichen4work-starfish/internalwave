function [cgrid, diag] = match_boundary_topo(pgrid, cgrid, obcflag, ndomx, ndomy, varargin)
    %
    %  match_boundary_topo  Blend child grid bathymetry with parent grid
    %                        bathymetry near open boundaries, processed in
    %                        (ndomx x ndomy) chunks for speed/memory.
    %
    %  Inputs:
    %    pgrid   : struct with fields .lon, .lat, .h, .mask (parent, e.g. NCOM)
    %    cgrid   : struct with fields .lon_rho, .lat_rho, .h, .mask_rho (child)
    %    obcflag : 1x4 [South East North West], 1=open (blend), 0=closed
    %    ndomx, ndomy : number of chunks in x / y direction
    %
    %  Optional name-value pairs: 'width','steep','plot'
    
       p = inputParser;
       addParameter(p,'width',0.06);
       addParameter(p,'steep',50);
       addParameter(p,'plot',true);
       parse(p,varargin{:});
       width = p.Results.width;
       steep = p.Results.steep;
       do_plot = p.Results.plot;
    
       if isempty(obcflag); obcflag = [1 1 1 1]; end
       if nargin < 4; ndomx = 1; end
       if nargin < 5; ndomy = 1; end
    
       [Mc, Lc] = size(cgrid.h);

       % match parent grid 
       pgrid = standardize_name(pgrid);
       pgrid.lon_rho(pgrid.lon_rho < 0) = pgrid.lon_rho(pgrid.lon_rho < 0) + 360;
    
       %% -------- set up chunk index bounds (same pattern as h2r_make_ini) --------
       szx = floor(Lc/ndomx);
       szy = floor(Mc/ndomy);
    
       icmin = (0:ndomx-1)*szx;  icmin(1) = 1;
       jcmin = (0:ndomy-1)*szy;  jcmin(1) = 1;
       icmax = (1:ndomx)*szx;    icmax(end) = Lc;
       jcmax = (1:ndomy)*szy;    jcmax(end) = Mc;
    
       hcn   = zeros(Mc, Lc);
       hpi_f = zeros(Mc, Lc);
       alpha_f = zeros(Mc, Lc);
    
       %% -------- global distance-to-boundary field (cheap, do once, not per chunk) --------
       [I, J] = meshgrid(1:Lc, 1:Mc);
       dist = zeros(Mc, Lc, 4);
       dist(:,:,1) =        J /Mc + (1-obcflag(1))*1e6;   % South
       dist(:,:,2) = (Lc - I)/Lc + (1-obcflag(2))*1e6;    % East
       dist(:,:,3) = (Mc - J)/Mc + (1-obcflag(3))*1e6;    % North
       dist(:,:,4) =        I /Lc + (1-obcflag(4))*1e6;   % West
       dist  = min(dist, [], 3);
       alpha_full = 0.5*tanh(steep*(dist - width)) + 0.5;
    
       %% -------- process each chunk --------
       for domx = 1:ndomx
          for domy = 1:ndomy
             fprintf('Chunk (%d,%d) of (%d,%d)\n', domx, domy, ndomx, ndomy)
    
             icb = icmin(domx); ice = icmax(domx);
             jcb = jcmin(domy); jce = jcmax(domy);
    
             lonc_chunk  = cgrid.lon_rho(jcb:jce, icb:ice);
             latc_chunk  = cgrid.lat_rho(jcb:jce, icb:ice);
             hc_chunk    = cgrid.h(jcb:jce, icb:ice);
             alpha_chunk = alpha_full(jcb:jce, icb:ice);
    
             %% crop parent grid tightly around THIS chunk only
             lon0 = min(lonc_chunk(:)) - 0.05;
             lon1 = max(lonc_chunk(:)) + 0.05;
             lat0 = min(latc_chunk(:)) - 0.05;
             lat1 = max(latc_chunk(:)) + 0.05;
    
             g = pgrid.lon_rho >= lon0 & pgrid.lon_rho <= lon1 & ...
                 pgrid.lat_rho >= lat0 & pgrid.lat_rho <= lat1;
    
             jidx = find(any(g,2));
             iidx = find(any(g,1));
             if isempty(jidx) || isempty(iidx)
                error('No parent overlap found for chunk (%d,%d) -- check coordinate conventions.', domx, domy)
             end
             jmin = min(jidx); jmax = max(jidx);
             imin = min(iidx); imax = max(iidx);
    
             hp    = pgrid.h  (jmin:jmax, imin:imax);
             lonp  = pgrid.lon_rho(jmin:jmax, imin:imax);
             latp  = pgrid.lat_rho(jmin:jmax, imin:imax);
             if isfield(pgrid,'mask')
                maskp = pgrid.mask(jmin:jmax, imin:imax);
             else
                maskp = ones(size(hp));
             end
    
             %% interpolate parent topo onto this chunk's child points
             [elem, coef] = get_tri_coef(lonp, latp, lonc_chunk, latc_chunk, maskp);
             hpi_chunk = sum(coef .* hp(elem), 3);
    
             %% blend
             hcn_chunk = alpha_chunk.*hc_chunk + (1-alpha_chunk).*hpi_chunk;
    
             %% place back into full arrays
             hcn(jcb:jce, icb:ice)     = hcn_chunk;
             hpi_f(jcb:jce, icb:ice)   = hpi_chunk;
             alpha_f(jcb:jce, icb:ice) = alpha_chunk;
          end
       end
    
       %% -------- package outputs --------
       diag.hpi   = hpi_f;
       diag.alpha = alpha_f;
    
       cgrid.h_orig = cgrid.h;
       cgrid.h      = hcn;
    
       %% -------- diagnostic plot --------
       if do_plot
          sc0 = min(hcn(:)); sc1 = max(hcn(:));
          figure;
          subplot(2,2,1); pcolor(cgrid.lon_rho, cgrid.lat_rho, hpi_f); caxis([sc0 sc1]); colorbar; shading flat
          title('Interpolated Parent Topo')
          subplot(2,2,2); pcolor(cgrid.lon_rho, cgrid.lat_rho, hcn); caxis([sc0 sc1]); colorbar; shading flat
          title('Boundary-Matched Child Topo')
          subplot(2,2,3); pcolor(cgrid.lon_rho, cgrid.lat_rho, hcn - hpi_f); colorbar; shading flat
          title('Difference (Child - Parent)')
          subplot(2,2,4); pcolor(cgrid.lon_rho, cgrid.lat_rho, alpha_f); colorbar; shading flat
          title('Parent/Child Transition Weight (\alpha)')
       end
    
    end