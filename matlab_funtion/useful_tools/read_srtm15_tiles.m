function [topo_lon, topo_lat, Z] = read_srtm15_tiles(filelist)
    %
    %  read_srtm15_tiles  Merge multiple SRTM15+ XYZ tiles (e.g. NE/NW/SE/SW
    %                     quadrants from the Scripps CGI tool) into a single
    %                     regular lon/lat grid + Z (bathymetry/elevation) matrix.
    %
    %  Input:
    %    filelist : cell array of filenames, e.g.
    %               {'get_srtm15_NW.txt','get_srtm15_NE.txt', ...
    %                'get_srtm15_SW.txt','get_srtm15_SE.txt'}
    %
    %  Output:
    %    topo_lon : 1 x nlon vector, sorted ascending
    %    topo_lat : 1 x nlat vector, sorted ascending
    %    Z        : nlat x nlon matrix, Z(j,i) = depth/elevation at
    %               (topo_lon(i), topo_lat(j))  -- ready for interp2(topo_lon,topo_lat,Z,...)
    %
    %  Convention: negative = ocean depth, positive = land (SRTM15+ native).
    
       %% 1. Read and concatenate all tiles
       all_lon = [];
       all_lat = [];
       all_z   = [];
    
       for k = 1:numel(filelist)
          disp(['Reading ' filelist{k} ' ...'])
          data = readmatrix(filelist{k});   % 3 columns: lon, lat, z
          if size(data,2) ~= 3
             error('%s does not have 3 columns -- check file format', filelist{k})
          end
          all_lon = [all_lon; data(:,1)];
          all_lat = [all_lat; data(:,2)];
          all_z   = [all_z;   data(:,3)];
          fprintf('  %d points, lon [%.4f %.4f], lat [%.4f %.4f]\n', ...
              size(data,1), min(data(:,1)), max(data(:,1)), min(data(:,2)), max(data(:,2)))
       end
    
       fprintf('Total points read: %d\n', numel(all_lon))
    
       %% 2. Snap to a common grid to avoid floating-point mismatch at tile edges
       %  SRTM15+ spacing is 15 arc-sec = 1/240 deg
       res = 1/240;
       lon_r = round(all_lon/res)*res;
       lat_r = round(all_lat/res)*res;
    
       %% 3. Build unique, sorted coordinate vectors
       topo_lon = unique(lon_r);
       topo_lat = unique(lat_r);
       topo_lon = topo_lon(:)';   % row vector
       topo_lat = topo_lat(:)';
    
       nlon = numel(topo_lon);
       nlat = numel(topo_lat);
       fprintf('Merged grid size: %d (lon) x %d (lat)\n', nlon, nlat)
    
       %% 4. Map each point to its (i,j) index and fill Z
       Z = nan(nlat, nlon);
    
       [~, i_idx] = ismember(lon_r, topo_lon);   % column index for each point
       [~, j_idx] = ismember(lat_r, topo_lat);   % row index for each point
    
       lin_idx = sub2ind([nlat nlon], j_idx, i_idx);
    
       %% Handle any duplicate points at tile-overlap edges by averaging
       [uniq_idx, ~, ic] = unique(lin_idx);
       z_avg = accumarray(ic, all_z, [], @mean);
       Z(uniq_idx) = z_avg;
    
       %% 5. Check for holes (gaps between tiles that weren't covered)
       n_missing = sum(isnan(Z(:)));
       if n_missing > 0
          fprintf('Warning: %d / %d grid points are NaN (gaps between tiles)\n', ...
              n_missing, numel(Z))
       else
          disp('No gaps -- full grid filled.')
       end
    
    end