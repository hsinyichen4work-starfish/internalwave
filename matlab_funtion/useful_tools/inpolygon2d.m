function [INPOLY, ONPOLY] = inpolygon2d(data_x, data_y, poly_x, poly_y)
%INPOLYGON2D  Vectorized wrapper for inpolygon applied row-wise.
%   [INPOLY, ONPOLY] = INPOLYGON2D(DATA_X, DATA_Y, POLY_X, POLY_Y)
%   checks whether the points in DATA_X, DATA_Y are inside or on the edge
%   of the polygon defined by POLY_X and POLY_Y. DATA_X and DATA_Y must be
%   matrices of the same size, where each row corresponds to a set of 
%   points to check. POLY_X and POLY_Y should be vectors defining the polygon.

    if ~isequal(size(data_x), size(data_y))
        error("Input error: data_x and data_y must be the same size.");
    end

    if ~isequal(size(poly_x), size(poly_y))
        error("Input error: poly_x and poly_y must be the same size.");
    end

    [nRows, nCols] = size(data_x);
    INPOLY = false(nRows, nCols);
    ONPOLY = false(nRows, nCols);

    for j = 1:nRows
        [INPOLY(j, :), ONPOLY(j, :)] = inpolygon(data_x(j, :), data_y(j, :), poly_x, poly_y);
    end
end
