function y = butter_lowpass_days(x, t_days, dt_days, order)
% butter_lowpass_days_nan applies a Butterworth low-pass filter
% to a time series that may contain NaN values.
%
% x        : input signal
% t_days   : cutoff period in days
%            e.g., 9 for 9-day low-pass
% dt_days  : time step in days
%            e.g., 1/24 for hourly data
% order    : filter order, typically 3–5
%
% The function interpolates over NaNs before filtering,
% then restores NaNs at their original locations.

    % Save original shape
    original_size = size(x);

    % Work with column vector
    x = x(:);

    % Find NaN locations
    nan_idx = isnan(x);

    % If all values are NaN, return NaNs
    if all(nan_idx)
        y = reshape(x, original_size);
        return
    end

    % Time index
    ii = (1:length(x))';

    % Interpolate over NaNs
    x_filled = x;

    x_filled(nan_idx) = interp1( ...
        ii(~nan_idx), ...
        x(~nan_idx), ...
        ii(nan_idx), ...
        'linear', ...
        'extrap');

    % Cutoff frequency, cycles per day
    fc = 1 / t_days;

    % Nyquist frequency
    fN = 1 / (2 * dt_days);

    % Normalized cutoff
    Wn = fc / fN;

    % Check cutoff range
    if Wn <= 0 || Wn >= 1
        error('Invalid cutoff period. Make sure t_days is resolvable by dt_days.');
    end

    % Design Butterworth low-pass filter
    [b, a] = butter(order, Wn, 'low');

    % Apply zero-phase filtering
    y = filtfilt(b, a, x_filled);

    % Restore original NaN locations
    y(nan_idx) = NaN;

    % Restore original shape
    y = reshape(y, original_size);

end

% function y = butter_lowpass_days(x, t_days, dt_days, order)
% % x        : input signal (time series)
% % t_days   : cutoff period in days (e.g., 9 for 9-day low-pass)
% % dt_days  : time step in days (e.g., 1/24 for hourly data)
% % order    : filter order (typically 3–5)
% 
%     % cutoff frequency (cycles per day)
%     fc = 1 / t_days;
% 
%     % Nyquist frequency
%     fN = 1 / (2 * dt_days);
% 
%     % normalized cutoff
%     Wn = fc / fN;
% 
%     % design Butterworth filter
%     [b, a] = butter(order, Wn, 'low');
% 
%     % apply zero-phase filtering
%     y = filtfilt(b, a, x);
% end