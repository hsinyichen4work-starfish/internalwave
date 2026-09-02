function [extracted, info] = extract_along_line(ncom_lon, ncom_lat, ncom_data, ...
    bnd_lon, bnd_lat, oversample_factor, max_dist_km)
%EXTRACT_ALONG_LINE Extract NCOM data at the grid cells a lat/lon line crosses.
%
%   [EXTRACTED, INFO] = EXTRACT_ALONG_LINE(NCOM_LON, NCOM_LAT, NCOM_DATA, ...
%                                    BND_LON, BND_LAT, OVERSAMPLE_FACTOR, MAX_DIST_KM)
%
%   This is the "walk the line" counterpart to EXTRACT_ALONG_BOUNDARY.
%   Instead of returning one value per point you supplied in BND_LON/
%   BND_LAT (which forces a 1-to-1 match), it uses TRACE_LINE_ON_GRID to
%   find every distinct NCOM cell the line passes through, in order, and
%   extracts data there. So the output length is set by the NCOM grid
%   resolution along the path -- it does NOT need to equal numel(BND_LON).
%   You can even just pass the two endpoints of a straight segment.
%
%   NCOM_LON, NCOM_LAT : 2D arrays (ny x nx), NCOM grid (rotated/curvilinear OK)
%   NCOM_DATA          : array with FIRST TWO dims (ny x nx), e.g.
%                        size = [ny, nx, ntime] or [ny, nx, ndepth, ntime]
%   BND_LON, BND_LAT   : vectors describing the line (>= 2 points)
%   OVERSAMPLE_FACTOR  : optional, default 4 (see TRACE_LINE_ON_GRID)
%   MAX_DIST_KM        : optional; currently unused here since every
%                        returned point IS an actual NCOM cell (distance
%                        is by definition small); kept for interface
%                        symmetry with EXTRACT_ALONG_BOUNDARY.
%
%   EXTRACTED : array, size [npath, trailing dims...] where npath = number
%               of distinct NCOM cells crossed (from TRACE_LINE_ON_GRID)
%   INFO      : struct with iy, ix, lon, lat for each returned point
%               (info.iy, info.ix, info.lon, info.lat)
%
%   Example:
%       [ssh_path, info] = extract_along_line(ncom_lon, ncom_lat, ncom_ssh, ...
%                                              bnd_lon([1 end]), bnd_lat([1 end]));
%       fprintf('Path length: %d cells\n', numel(info.iy));

if nargin < 6 || isempty(oversample_factor)
oversample_factor = 4;
end
if nargin < 7
max_dist_km = []; %#ok<NASGU> % reserved, not used (see help text)
end

[ny, nx] = size(ncom_lon);
sz = size(ncom_data);
assert(isequal(sz(1:2), [ny, nx]), ...
'First two dims of ncom_data must match size(ncom_lon) = [ny, nx].');

if numel(sz) > 2
trailing_sz = sz(3:end);
else
trailing_sz = 1;
end
nk = prod(trailing_sz);
data2d = reshape(ncom_data, ny, nx, nk);

[iy_path, ix_path, lon_path, lat_path] = trace_line_on_grid(ncom_lon, ncom_lat, ...
                   bnd_lon, bnd_lat, oversample_factor);
npath = numel(iy_path);
lin_idx = sub2ind([ny, nx], iy_path, ix_path);

extracted = zeros(npath, nk);
for k = 1:nk
slice = data2d(:, :, k);
extracted(:, k) = slice(lin_idx);
end
extracted = reshape(extracted, [npath, trailing_sz]);

info.iy  = iy_path;
info.ix  = ix_path;
info.lon = lon_path;
info.lat = lat_path;
end