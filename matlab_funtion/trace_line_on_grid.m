function [iy_path, ix_path, lon_path, lat_path] = trace_line_on_grid(ncom_lon, ncom_lat, ...
    bnd_lon, bnd_lat, oversample_factor)
%TRACE_LINE_ON_GRID Walk a lat/lon line across the NCOM grid and return the
%ordered, unique sequence of grid cells it crosses.
%
%   [IY_PATH, IX_PATH, LON_PATH, LAT_PATH] = TRACE_LINE_ON_GRID(NCOM_LON, ...
%                                       NCOM_LAT, BND_LON, BND_LAT, OVERSAMPLE_FACTOR)
%
%   Unlike FIND_NEAREST_INDICES (one nearest cell per INPUT point), this
%   function does not care how many points you gave it. It:
%     1. Estimates the local NCOM grid spacing.
%     2. Resamples your line at a step finer than that spacing.
%     3. Finds the nearest NCOM cell for every fine sample.
%     4. Collapses consecutive repeats, keeping only the cells where the
%        nearest cell actually changes.
%
%   The result is the ordered list of distinct NCOM grid cells that the
%   line passes through -- its length is set by the NCOM grid resolution
%   along the path, NOT by numel(BND_LON).
%
%   NCOM_LON, NCOM_LAT   : 2D arrays (ny x nx), NCOM grid (rotated/curvilinear OK)
%   BND_LON, BND_LAT     : vectors describing the line (as few as 2 points
%                          is fine -- e.g. just the two endpoints of a
%                          straight boundary segment)
%   OVERSAMPLE_FACTOR    : optional, default 4. How many fine samples per
%                          grid cell width along the line. Higher = safer
%                          (won't skip a cell) but slower.
%
%   IY_PATH, IX_PATH     : row/col indices of the cells crossed, in order
%   LON_PATH, LAT_PATH   : lon/lat of those cells (from the NCOM grid itself)
%
%   Example:
%       [iy_p, ix_p, lon_p, lat_p] = trace_line_on_grid(ncom_lon, ncom_lat, ...
%                                                        bnd_lon, bnd_lat);
%       fprintf('Line crosses %d distinct NCOM cells\n', numel(iy_p));

if nargin < 5 || isempty(oversample_factor)
oversample_factor = 4;
end

bnd_lon = bnd_lon(:);
bnd_lat = bnd_lat(:);

[lon0, lat0, coslat0] = build_ncom_projection(ncom_lon, ncom_lat);
[X, Y] = project_lonlat(ncom_lon, ncom_lat, lon0, lat0, coslat0);

% --- estimate local NCOM grid spacing (in the same projected units) ---
dx_grid = median(abs(diff(X, 1, 2)), 'all', 'omitnan');   % spacing along columns
dy_grid = median(abs(diff(Y, 1, 1)), 'all', 'omitnan');   % spacing along rows
grid_spacing = mean([dx_grid, dy_grid], 'omitnan');
if ~isfinite(grid_spacing) || grid_spacing <= 0
error('Could not estimate NCOM grid spacing; check ncom_lon/ncom_lat.');
end
step = grid_spacing / oversample_factor;

% --- densify the input line by arc length, in projected units ---
[bx, by] = project_lonlat(bnd_lon, bnd_lat, lon0, lat0, coslat0);
seg_len  = hypot(diff(bx), diff(by));
cumlen   = [0; cumsum(seg_len)];
total_len = cumlen(end);

if total_len <= 0 || numel(bnd_lon) < 2
error('Boundary line must have at least 2 distinct points.');
end

n_fine = max(2, ceil(total_len / step) + 1);
s_fine = linspace(0, total_len, n_fine);

lon_fine = interp1(cumlen, bnd_lon, s_fine, 'linear');
lat_fine = interp1(cumlen, bnd_lat, s_fine, 'linear');

% --- nearest NCOM cell for every fine sample along the line ---
[iy_f, ix_f, ~] = find_nearest_indices(ncom_lon, ncom_lat, lon_fine, lat_fine);

% --- collapse consecutive repeats: keep only where the cell changes ---
keep = [true; (diff(iy_f) ~= 0) | (diff(ix_f) ~= 0)];
iy_path = iy_f(keep);
ix_path = ix_f(keep);

lin_idx  = sub2ind(size(ncom_lon), iy_path, ix_path);
lon_path = ncom_lon(lin_idx);
lat_path = ncom_lat(lin_idx);
end