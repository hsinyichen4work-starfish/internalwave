function [lon0, lat0, coslat0] = build_ncom_projection(ncom_lon, ncom_lat)
    %BUILD_NCOM_PROJECTION Local equirectangular projection constants for an NCOM grid.
    %
    %   [LON0, LAT0, COSLAT0] = BUILD_NCOM_PROJECTION(NCOM_LON, NCOM_LAT)
    %
    %   Returns the domain-center longitude/latitude and cos(lat0). These are
    %   used to convert lon/lat into a local flat (x,y) coordinate system so
    %   that nearest-neighbor distances behave sensibly regardless of how the
    %   NCOM grid is rotated or curved relative to true north/east.
    
        lon0    = mean(ncom_lon(:), 'omitnan');
        lat0    = mean(ncom_lat(:), 'omitnan');
        coslat0 = cosd(lat0);
    end