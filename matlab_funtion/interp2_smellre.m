function zi = interp2_smellre(gridx, gridy, val, targetx, targety, method, win)
%INTERP2_SMELLRE Interpolate VAL at (targetx,targety) using only a small
%local subgrid around the target instead of the full GRIDX/GRIDY grid.
%
%   zi = INTERP2_SMELLRE(gridx, gridy, val, targetx, targety)
%   zi = INTERP2_SMELLRE(gridx, gridy, val, targetx, targety, method)
%   zi = INTERP2_SMELLRE(gridx, gridy, val, targetx, targety, method, win)
%
%   GRIDX, GRIDY, VAL can be either:
%     - 1-D vectors GRIDX(nx), GRIDY(ny) with VAL(ny,nx)  -> plaid grid,
%       the local subgrid is extracted then passed to built-in INTERP2.
%     - 2-D matrices GRIDX, GRIDY, VAL all the same size  -> curvilinear
%       grid (e.g. a rotated ROMS grid), where the nearest node is found
%       and a small window around it is interpolated with a linear
%       scatteredInterpolant (a true plaid INTERP2 is not valid on a
%       curvilinear/rotated grid).
%
%   METHOD is 'linear' (default), 'nearest', or 'cubic'/'spline' (vector
%   grid case only, passed straight to INTERP2).
%
%   WIN sets how many extra points are kept beyond the minimum bracketing
%   pair on each side (default 1). WIN = 1 keeps a small local patch
%   (e.g. 4x4 for the vector case) so the target point stays bracketed
%   even for higher-order methods; the curvilinear case always keeps at
%   least the closest 4 points around the nearest node.
%
%   Example:
%       grd_ang = ncread(gridfile, 'angle');
%       lon_rho = ncread(gridfile, 'lon_rho');
%       lat_rho = ncread(gridfile, 'lat_rho');
%       ang = interp2_smellre(lon_rho, lat_rho, grd_ang, lon, lat);

    if nargin < 6 || isempty(method)
        method = 'linear';
    end
    if nargin < 7 || isempty(win)
        win = 1;
    end

    if isvector(gridx) && isvector(gridy)
        zi = local_vector(gridx, gridy, val, targetx, targety, method, win);
    else
        zi = local_curvilinear(gridx, gridy, val, targetx, targety, method, win);
    end
end

function zi = local_vector(gridx, gridy, val, targetx, targety, method, win)
    gridx = gridx(:)';   % row
    gridy = gridy(:);    % column

    ix = bracket_index(gridx, targetx, win);
    iy = bracket_index(gridy, targety, win);

    zi = interp2(gridx(ix), gridy(iy), val(iy, ix), targetx, targety, method);
end

function idx = bracket_index(g, t, win)
    % Index range into g that brackets t (clamped to the grid edges),
    % padded by win extra points on each side.
    n = numel(g);
    if g(end) < g(1)
        lo = find(g <= t, 1, 'first');
    else
        lo = find(g <= t, 1, 'last');
    end
    if isempty(lo)
        lo = 1;
    end
    hi = min(lo + 1, n);
    lo = max(1, lo - win);
    hi = min(n, hi + win);
    idx = lo:hi;
end

function zi = local_curvilinear(gridx, gridy, val, targetx, targety, method, win)
    d2 = (gridx - targetx).^2 + (gridy - targety).^2;
    [~, k] = min(d2(:));
    [i0, j0] = ind2sub(size(gridx), k);

    [ny, nx] = size(gridx);
    ii = max(1, i0 - win) : min(ny, i0 + win);
    jj = max(1, j0 - win) : min(nx, j0 + win);

    sx = gridx(ii, jj);
    sy = gridy(ii, jj);
    sv = val(ii, jj);

    F = scatteredInterpolant(sx(:), sy(:), sv(:), method, 'nearest');
    zi = F(targetx, targety);
end
