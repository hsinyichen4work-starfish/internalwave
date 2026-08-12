function [lon_deg,lat_deg] = lonlat_rad2deg(lon,lat)
    
    lon_deg = lon*180/pi;      % convert radians to degrees (0-360 range)
    lon_deg(lon_deg > 180) = lon_deg(lon_deg > 180) - 360;  % convert to -180/180 range
    lat_deg = lat*180/pi;      % latitude doesn't wrap, just convert

end