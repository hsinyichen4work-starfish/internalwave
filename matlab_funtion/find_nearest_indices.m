function [iy, ix, dist_km] = find_nearest_indices(ncom_lon, ncom_lat, bnd_lon, bnd_lat)
    %FIND_NEAREST_INDICES Nearest NCOM grid cell for each boundary lat/lon point.
    %
    %   [IY, IX, DIST_KM] = FIND_NEAREST_INDICES(NCOM_LON, NCOM_LAT, BND_LON, BND_LAT)
    %
    %   NCOM_LON, NCOM_LAT : 2D arrays (ny x nx), curvilinear/rotated NCOM grid
    %   BND_LON, BND_LAT   : vectors, the ROMS boundary line lat/lon points
    %
    %   IY, IX  : row/col indices (one per boundary point) of the nearest
    %             NCOM grid cell
    %   DIST_KM : approximate distance (km) from each boundary point to its
    %             nearest NCOM grid cell -- use this to check whether the
    %             boundary line actually falls on/near the NCOM grid.
    %
    %   This works purely in lat/lon space (via a local flat projection), so
    %   the rotation of the NCOM grid relative to ROMS does not matter.
    %
    %   No toolboxes required (plain loops + vectorized distance calc), so it
    %   runs on base MATLAB.
    
        [lon0, lat0, coslat0] = build_ncom_projection(ncom_lon, ncom_lat);
        [X, Y]   = project_lonlat(ncom_lon, ncom_lat, lon0, lat0, coslat0);
        [bx, by] = project_lonlat(bnd_lon(:), bnd_lat(:), lon0, lat0, coslat0);
    
        [ny, nx] = size(ncom_lon);
        npts     = numel(bx);
    
        iy      = zeros(npts, 1);
        ix      = zeros(npts, 1);
        dist_km = zeros(npts, 1);
    
        for k = 1:npts
            d2 = (X - bx(k)).^2 + (Y - by(k)).^2;      % squared dist, whole grid
            [dmin, lin_idx] = min(d2(:));
            [iy(k), ix(k)]  = ind2sub([ny, nx], lin_idx);
            dist_km(k)      = sqrt(dmin) * 111.19;     % ~km per degree latitude
        end
    end