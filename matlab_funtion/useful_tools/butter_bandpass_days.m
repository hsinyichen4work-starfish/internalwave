function y = butter_bandpass_days(x, t_low_days, t_high_days, dt_days, order)
% butter_bandpass_days_nan applies a Butterworth band-pass filter
% to a time series that may contain NaN values.
%
% x           : input signal
% t_low_days  : longer cutoff period in days
%               e.g., 15 means remove variability longer than 15 days
% t_high_days : shorter cutoff period in days
%               e.g., 3 means remove variability shorter than 3 days
% dt_days     : time step in days
%               e.g., 1/24 for hourly data
% order       : filter order, typically 3–5
%
% Example:
%   y = butter_bandpass_days_nan(x, 15, 3, 1/24, 4);
%
% This keeps variability between 3 and 15 days.
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

    % Convert cutoff periods to frequencies in cycles per day
    f_low  = 1 / t_low_days;   % lower frequency cutoff
    f_high = 1 / t_high_days;  % higher frequency cutoff

    % Nyquist frequency
    fN = 1 / (2 * dt_days);

    % Normalized cutoff frequencies
    Wn = [f_low f_high] / fN;

    % Check cutoff range
    if Wn(1) <= 0 || Wn(2) >= 1 || Wn(1) >= Wn(2)
        error('Invalid cutoff periods. Make sure t_low_days > t_high_days and both are resolvable by dt_days.');
    end

    % Design Butterworth band-pass filter
    [b, a] = butter(order, Wn, 'bandpass');

    % Apply zero-phase filtering
    y = filtfilt(b, a, x_filled);

    % Restore original NaN locations
    y(nan_idx) = NaN;

    % Restore original shape
    y = reshape(y, original_size);

end

% function y = butter_bandpass_days(x, t_low_days, t_high_days, dt_days, order)
% % butter_bandpass_days applies a Butterworth band-pass filter to a time series.
% %
% % x           : input signal
% % t_low_days  : longer cutoff period in days
% %               e.g., 15 means remove variability longer than 15 days
% % t_high_days : shorter cutoff period in days
% %               e.g., 3 means remove variability shorter than 3 days
% % dt_days     : time step in days
% %               e.g., 1/24 for hourly data
% % order       : filter order, typically 3–5
% %
% % Example:
% %   y = butter_bandpass_days(x, 15, 3, 1/24, 4);
% %   This keeps variability between 3 and 15 days.
% 
%     % Convert cutoff periods to frequencies in cycles per day
%     f_low  = 1 / t_low_days;   % lower frequency cutoff
%     f_high = 1 / t_high_days;  % higher frequency cutoff
% 
%     % Nyquist frequency
%     fN = 1 / (2 * dt_days);
% 
%     % Normalized cutoff frequencies
%     Wn = [f_low f_high] / fN;
% 
%     % Check cutoff range
%     if Wn(1) <= 0 || Wn(2) >= 1 || Wn(1) >= Wn(2)
%         error('Invalid cutoff periods. Make sure t_low_days > t_high_days and both are resolvable by dt_days.');
%     end
% 
%     % Design Butterworth band-pass filter
%     [b, a] = butter(order, Wn, 'bandpass');
% 
%     % Apply zero-phase filtering
%     y = filtfilt(b, a, x);
% 
% end