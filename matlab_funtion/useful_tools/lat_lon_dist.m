function [ds] = lat_lon_dist(Mygrid,lat,lon)

    R = 6371000;  % Earth radius in meters
    lat0 = mean(Mygrid.lat_rho(:));   % reference latitude (degrees)
    
    % Convert to radians
    lat_rad = deg2rad(lat);
    lon_rad = deg2rad(lon);
    
    % Metric differentials
    dlat = diff(lat_rad);
    dlon = diff(lon_rad);
    
    dy = R * dlat;
    dx = R * cos(deg2rad(lat0)) .* dlon;
    
    ds = sqrt(dx.^2 + dy.^2);   % distance between consecutive points (m)
end