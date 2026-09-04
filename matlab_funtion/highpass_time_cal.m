function xf = highpass_time_cal(x, time, cutoff, N, timedim)
    % HIGHPASS_TIME_CAL  High-pass filter (x - lowpass(x)) applied along a
    % specified time dimension, vectorized across all other indices.
    %
    %   xf = highpass_time_cal(x, time, cutoff, N, timedim)
    %
    % x       : any-shape array, e.g. (nalong, nz, nt)
    % time    : time vector, IN DAYS (matching lowhighpass_butter's convention),
    %           length must equal size(x, timedim)
    % cutoff  : high-pass cutoff period, in days (e.g. 30/24 for 30 hours)
    % N       : Butterworth order (5 is a reasonable default)
    % timedim : which dimension of x is time (e.g. 3 for (nalong,nz,nt))
    %
    % Uses x - lowpass(x) rather than calling lowhighpass_butter(...,'high')
    % directly, since that guarantees exact reconstruction (low + high = x),
    % unlike two independently-designed low/high Butterworth filters.
    %
    % NOTE: filtfilt (called inside lowhighpass_butter) operates on a full 2D
    % matrix in one call (each column filtered independently), so no manual
    % per-column loop is needed here -- just permute time to the front,
    % reshape to 2D, filter once, then reshape/permute back.
    %
    % CAUTION: unlike a manual loop, this does not skip columns containing
    % NaN (e.g. masked/land points) -- filtfilt may error or return NaN for
    % those columns. Check `any(isnan(x(:)))` on your real data first, and
    % consider masking/excluding land columns before calling this if needed.
    %
    % Requires lowhighpass_butter.m on the path.
    
    nd = ndims(x);
    perm = [timedim, setdiff(1:nd, timedim)];   % bring time to dim 1
    xp = permute(x, perm);
    sznew = size(xp);
    
    x2 = reshape(xp, sznew(1), []);             % (nt, ncols) -- 2D matrix
    low2 = lowhighpass_butter(time, x2, cutoff, N, 'low');   % one call, all columns
    xf2 = x2 - low2;                             % exact high-pass complement
    
    xfp = reshape(xf2, sznew);
    invperm(perm) = 1:nd;
    xf = permute(xfp, invperm);                  % back to original shape/order
    end