%% write_dynamic_bry_flux.m
%
% Writes one flux netCDF file per day, matching the existing
% roms_bry_<dx>m_<fod>.nc naming convention, containing:
%   up_west, up_east    (from Fx -- west/east boundaries)
%   vp_south, vp_north  (from Fy -- south/north boundaries)
%   bry_time            (same epoch/units as the existing bry files: t1)
%
% IMPORTANT: writes the RAW grid-relative Fx/Fy (e.g. north_Fx, north_Fy),
% NOT the geo-rotated versions (north_Fx_geo etc) -- see earlier discussion:
% ROMS's own internal diag_pflx flux is grid-relative (xi/eta), so the
% externally-supplied Fext must be in the same convention for the
% obc_tune comparison to be meaningful.

if ~exist(flux_out_path,'dir'); mkdir(flux_out_path); end
fod = string(datestr(dating,"yyyymmddHH"));

% real MATLAB datenum for every sample -- kept only for the warning/sanity
% check below, not for the actual day-matching anymore
real_time = time(:) + t1;

% map: boundary direction -> {output varname, source Fx/Fy variable}
dir_map = struct( ...
    'west',  struct('varname','up_west', 'src', west_Fx), ...
    'east',  struct('varname','up_east', 'src', east_Fx), ...
    'south', struct('varname','vp_south','src', south_Fy), ...
    'north', struct('varname','vp_north','src', north_Fy) ...
);
dirstr = ["west","east","south","north"];

for d = 1:length(dating)

    % read this day's ORIGINAL bry file just to get its exact bry_time
    % values, then find those same samples in the master (concatenated,
    % deduplicated) time/Fx/Fy arrays -- more robust than reconstructing
    % day boundaries generically, and naturally handles whatever overlap
    % convention the original per-day files use without extra bookkeeping.
    cbry_name = append(child_bry_path, 'roms_bry_', num2str(dx), 'm_', ...
                        datestr(dating(d),"yyyymmddHH"), '.nc');
    cbry = read_nc_fun(cbry_name);
    day_bry_time = cbry.bry_time(:);
    disp(cbry_name)

    [tf, idx] = ismember(day_bry_time, time);
    if any(~tf)
        warning('%s: %d of %d bry_time samples not found in master time array -- skipping those', ...
            fod(d), sum(~tf), numel(day_bry_time));
    end
    idx = idx(tf);   % keep only the ones that actually matched

    if isempty(idx)
        warning('no matching samples found for %s -- skipping file entirely', fod(d));
        continue
    end

    fname = fullfile(flux_out_path, ...
        append('roms_dbry_flux_900m_', fod(d), '.nc'));
    if exist(fname,'file'); delete(fname); end

    % bry_time: same values/units/epoch as the existing bry files (just
    % the subset of samples falling on this calendar day)
    day_time = time(idx);
    nccreate(fname, 'bry_time', 'Dimensions', {'bry_time', numel(idx)}, ...
             'Datatype', 'double');
    ncwrite(fname, 'bry_time', day_time);
    ncwriteatt(fname, 'bry_time', 'units', 'days since 1900-12-31 00:00:00');
    ncwriteatt(fname, 'bry_time', 'long_name', 'time for dynamic boundary flux');

    for j = 1:length(dirstr)
        dname = char(dirstr(j));
        varname  = dir_map.(dname).varname;
        src_full = dir_map.(dname).src;         % (nalong, nt_total)
        along_dimname = append(dname, '_pts');

        data_day = src_full(:, idx);            % (nalong, ndays_samples)

        nccreate(fname, varname, ...
                 'Dimensions', {along_dimname, size(data_day,1), 'bry_time', numel(idx)}, ...
                 'Datatype', 'double');
        ncwrite(fname, varname, data_day);
        ncwriteatt(fname, varname, 'long_name', ...
            append('HF baroclinic energy flux, ', dname, ' boundary'));
        ncwriteatt(fname, varname, 'units', 'W/m');
    end

    if mod(d,10) == 0 || d == length(dating)
        fprintf('wrote %s (%d samples)\n', fname, numel(idx));
    end
end

fprintf('done -- %d daily flux files written to %s\n', length(dating), flux_out_path);