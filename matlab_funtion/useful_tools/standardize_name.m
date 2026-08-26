function s = standardize_name(s)
    % STANDARDIZE_LONLAT  Rename lon/lat fields to lon_rho/lat_rho for consistency.
    %
    %   s = standardize_lonlat(s)
    %
    %   Works on a struct that has either:
    %       s.lon, s.lat            (e.g. parent grid "pgrid")
    %   or
    %       s.lon_rho, s.lat_rho    (e.g. child_grid, already correct)
    %
    %   After running, the struct is guaranteed to have s.lon_rho and s.lat_rho.
    %   The original lon/lat fields (if present) are removed to avoid duplicates.
    
        % --- Longitude ---
        if isfield(s, 'lon') && ~isfield(s, 'lon_rho')
            s.lon_rho = s.lon;
            s = rmfield(s, 'lon');
        elseif isfield(s, 'lon') && isfield(s, 'lon_rho')
            % both exist already - drop the redundant one, keep lon_rho
            s = rmfield(s, 'lon');
        end
    
        % --- Latitude ---
        if isfield(s, 'lat') && ~isfield(s, 'lat_rho')
            s.lat_rho = s.lat;
            s = rmfield(s, 'lat');
        elseif isfield(s, 'lat') && isfield(s, 'lat_rho')
            s = rmfield(s, 'lat');
        end
    
    end