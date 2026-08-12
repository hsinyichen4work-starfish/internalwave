function mid = midpoints(vec)
%MIDPOINTS Computes midpoints between adjacent elements in a vector
%   mid = MIDPOINTS(vec) returns a vector of midpoints.
%   The input vec must be a 1D array (row or column).
%   The output will have length n-1 and match the orientation of input.

    % Ensure vec is a vector
    if ~isvector(vec)
        error('Input must be a 1D vector.');
    end

    % Compute midpoints
    mid_vals = (vec(1:end-1) + vec(2:end)) / 2;

    % Preserve orientation (row or column)
    if isrow(vec)
        mid = mid_vals;
    else
        mid = mid_vals.';
    end
end
