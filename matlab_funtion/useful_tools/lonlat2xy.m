function [x,y] = lonlat2xy(lon,lat,lon_0,lat_0)
    %
    %   Converts lon/lat (degrees) to a local x-y plane (meters) using an
    %   equirectangular projection centered at (lon_0,lat_0), which becomes (0,0).
    %
    %   Inputs:
    %   lon,lat:       Arrays of longitude/latitude in degrees
    %   lon_0,lat_0:   Origin longitude/latitude in degrees -> maps to (0,0)
    %
    %   Outputs:
    %   x,y:  Local Cartesian coordinates in meters
    %         x = eastward distance, y = northward distance
    
        r_earth = 6371315.;  % same as used in easy_grid.m
    
        lat0_rad = lat_0*pi/180;
    
        dlon = (lon - lon_0)*pi/180;
        dlat = (lat - lat_0)*pi/180;
    
        % scale x by cos(lat_0) so it's a proper local Cartesian distance
        x = r_earth*dlon*cos(lat0_rad);
        y = r_earth*dlat;
    
    end