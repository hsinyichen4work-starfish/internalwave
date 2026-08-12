function [dist_moor, mismatch, idx_moor] = match_points_to_section(lon_sec, lat_sec, dist, lon_pts, lat_pts)
    %
    %  match_points_to_section  Map a set of lon/lat points (e.g. mooring,
    %                            CPIES) onto the along-track distance axis
    %                            of a bathymetry section, using nearest-point
    %                            matching.
    %
    %  Inputs:
    %    lon_sec, lat_sec : 1D vectors, the section's lon/lat (same as used
    %                        to build 'dist' in extract_section.m)
    %    dist             : 1D vector, along-track distance (km) from
    %                        extract_section.m, same length as lon_sec/lat_sec
    %    lon_pts, lat_pts : vectors of mooring/CPIES lon/lat to match
    %
    %  Outputs:
    %    dist_moor : along-track distance (km) of each point's closest match
    %    mismatch  : actual distance (km, great-circle) between each point and
    %                its closest section point -- use this to flag points that
    %                aren't really "on" the section line
    %    idx_moor  : index into lon_sec/lat_sec of each closest match
    
       n = numel(lon_pts);
       dist_moor = zeros(n,1);
       mismatch  = zeros(n,1);
       idx_moor  = zeros(n,1);
    
       for k = 1:n
          [xc, yc, idx] = cloest_point(lon_sec, lat_sec, lon_pts(k), lat_pts(k));
    
          dist_moor(k) = dist(idx);
          idx_moor(k)  = idx;
    
          % actual great-circle mismatch distance (km), NOT the raw lon/lat
          % Euclidean distance cloest_point used internally -- that's fine for
          % *finding* the nearest index, but not meaningful as a real distance
          % since degrees of lon/lat aren't equal-area
          mismatch(k) = gc_dist(lon_pts(k), lat_pts(k), xc, yc)/1000;   % km
       end
    
       %% flag any points that are suspiciously far from the section line
       tol_km = 2;   % adjust based on your grid resolution / expectations
       bad = find(mismatch > tol_km);
       if ~isempty(bad)
          fprintf('Warning: %d point(s) are >%.1f km from the section line:\n', numel(bad), tol_km)
          for k = bad(:)'
             fprintf('  point %d: lon=%.4f lat=%.4f -> mismatch = %.2f km\n', ...
                 k, lon_pts(k), lat_pts(k), mismatch(k))
          end
       end
    
    end