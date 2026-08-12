function [dist, lon_sec, lat_sec, h_sec] = extract_section(lon, lat, h, pm, pn, dim, idx)
    %
    %  extract_section  Extract a cross-section (transect) along a grid-index
    %                    line from a curvilinear ROMS grid.
    %
    %  Inputs:
    %    lon, lat : 2D grid arrays (degrees) -- e.g. lon_rho, lat_rho
    %    h        : 2D bathymetry array, same size as lon/lat
    %    pm, pn   : 2D grid metrics (1/dx, 1/dy), same size as lon/lat
    %    dim      : 'row' (constant j, varies along i / xi-direction)
    %               or 'col' (constant i, varies along j / eta-direction)
    %    idx      : the index of the row/column to extract
    %
    %  Outputs:
    %    dist     : along-track distance (km) from the start of the section
    %    lon_sec, lat_sec : lon/lat along the section
    %    h_sec    : bathymetry along the section
    
       if strcmpi(dim,'row')
          lon_sec = lon(idx,:);
          lat_sec = lat(idx,:);
          h_sec   = h(idx,:);
          dx_sec  = 1./pn(idx,:);   % note: moving along i means using pn's counterpart --
                                     % double check which metric corresponds to
                                     % this direction in your grid convention (see note below)
       elseif strcmpi(dim,'col')
          lon_sec = lon(:,idx);
          lat_sec = lat(:,idx);
          h_sec   = h(:,idx);
          dx_sec  = 1./pm(:,idx);
       else
          error('dim must be ''row'' or ''col''')
       end
    
       %% compute cumulative along-track distance directly from lon/lat
       %% (more robust than relying on pm/pn, since it uses actual geometry)
       n = numel(lon_sec);
       seg_dist = zeros(n-1,1);
       for k = 1:n-1
          seg_dist(k) = gc_dist(lon_sec(k), lat_sec(k), lon_sec(k+1), lat_sec(k+1));
          % gc_dist from easy_grid.m -- returns meters; if lon/lat are in
          % degrees, check gc_dist's expected units and convert if needed
       end
       dist = [0; cumsum(seg_dist)]/1000;   % km
    
    end