function [x, y] = project_lonlat(lon, lat, lon0, lat0, coslat0)
    %PROJECT_LONLAT Local equirectangular projection (degrees -> ~km-consistent x/y).
    %
    %   [X, Y] = PROJECT_LONLAT(LON, LAT, LON0, LAT0, COSLAT0)
    %
    %   Simple flat-earth projection centered at (LON0, LAT0), good enough
    %   for nearest-neighbor search / interpolation over a regional domain.
    
        x = (lon - lon0) * coslat0;
        y = (lat - lat0);
    end