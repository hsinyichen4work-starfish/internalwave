clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');

%% ============================================================================
% dbry_make.m
%
% Merge of dbrt_900_imporve.m (memory-bounded computation of the
% high-frequency baroclinic energy flux Fx/Fy at the child-grid open
% boundaries) and write_dynamic_bry_flux.m (writing those fluxes out as
% one daily netCDF file per existing roms_bry_<dx>m_<fod>.nc file).
%
% WHAT'S DIFFERENT FROM RUNNING THE TWO OLD SCRIPTS BACK TO BACK:
%
% The old workflow computed Fx/Fy, saved everything (including the big
% p_prime/u_prime/v_prime/p_fast/u_fast/v_fast fields) to a -v7.3 MAT
% file, then a SEPARATE script (check_dbry.m) had to `load()` that MAT
% file back into the workspace just to hand west_Fx/east_Fx/south_Fy/
% north_Fy/time/dating/t1/dx/flux_out_path to write_dynamic_bry_flux.m
% as plain script-level variables.
%
% This script does both steps in one run: the small, fully time-reduced
% fields (ssh, Fx, Fy, *_bar) stay in memory (struct `small`) exactly as
% dbrt_900_imporve.m built them, and the netCDF-writing step at the end
% reads directly from `small`/`small_time` instead of reloading anything
% from disk. The big per-timestep diagnostic fields (p_prime, u_prime,
% ..., v_fast) are still written chunk-by-chunk to the preallocated
% -v7.3 MAT file exactly as before (see dbrt_900_imporve.m's original
% comments for why matfile() indexed assignment is used there) -- they
% are not needed for the flux netCDF output but are kept for the same
% diagnostics/plotting use as the original.
%
% Everything else (chunked+padded processing, de-duplicated time
% samples, no eval()) is unchanged from dbrt_900_imporve.m; see that
% file's header comments for the full rationale.
%% ============================================================================

%% ---- user settings ----
dx = 300;
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path  = '/home/hsinyi/roms_data/bry_63/';
flux_out_path   = '/home/hsinyi/roms_data/bry_dynamic_flux_63/';
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];

date_start = "20220822";
date_end   = "20221125";

cutoff_days = 28/24;   % ~29 hours, per your PI's 28-30 hr suggestion
N_butter    = 5;

CHUNK_DAYS = 15;   % days of *output* produced per chunk
PAD_DAYS   = 6;    % extra days read (and discarded) on each side of a
                    % chunk to give the highpass filter a clean transient

% model bry_time epoch, in MATLAB datenum -- same convention check_dbry.m
% used ( t1 = datenum('1994/01/01') ) to convert bry_time -> real calendar
% dates for display; bry_time itself is stored/matched in raw model days
t1 = datenum('1994/01/01');

save_mat = true;   % also persist the big *_prime/*_fast fields (for
                    % diagnostics/plotting) to this MAT file, same as
                    % dbrt_900_imporve.m did
mat_save = fullfile('/home/hsinyi/matlab_file/bry_saving', ...
    append("bryfile_dynamic",num2str(dx),"_imporve.mat"));

dirstr = ["north";"south";"east";"west"];

%% ---- grid (small, load once) ----
cgrid = read_nc_fun([child_grid_path,cgrid_name]);
cgrid.lon_rho(cgrid.lon_rho>180) = cgrid.lon_rho(cgrid.lon_rho>180) - 360;

geo.south.bathc = cgrid.h(:,1);   geo.south.angc = cgrid.angle(:,1);
geo.north.bathc = cgrid.h(:,end); geo.north.angc = cgrid.angle(:,end);
geo.east.bathc  = cgrid.h(end,:); geo.west.angc  = cgrid.angle(end,:);
geo.west.bathc  = cgrid.h(1,:);   geo.east.angc  = cgrid.angle(1,:);

geo.south.lon = cgrid.lon_rho(:,1);   geo.south.lat = cgrid.lat_rho(:,1);
geo.north.lon = cgrid.lon_rho(:,end); geo.north.lat = cgrid.lat_rho(:,end);
geo.east.lon  = cgrid.lon_rho(end,:); geo.east.lat  = cgrid.lat_rho(end,:);
geo.west.lon  = cgrid.lon_rho(1,:);   geo.west.lat  = cgrid.lat_rho(1,:);

%% ---- day list & chunk boundaries ----
dating = datenum(date_start,"yyyymmdd") : datenum(date_end,"yyyymmdd");
fod = string(datestr(dating,"yyyymmddHH"));
nfiles = length(fod);
chunk_starts = 1:CHUNK_DAYS:nfiles;

%% ---- probe one file for sizes / vertical-coordinate params ----
probe = read_nc_fun(append(child_bry_path,'roms_bry_',num2str(dx),'m_',fod(1),'.nc'));
nz = size(probe.temp_south, 2);
theta_s = probe.theta_s; theta_b = probe.theta_b; hc = probe.hc;
samples_per_file = length(probe.bry_time);      % 25: one day + 1hr overlap
nt_total = (samples_per_file-1)*nfiles + 1;      % after de-duplication
clear probe

fprintf('nz=%d, nfiles=%d, nt_total (deduped)=%d, %d chunk(s)\n', ...
    nz, nfiles, nt_total, length(chunk_starts));

%% ---- preallocate the on-disk output MAT file (big diagnostic fields) ----
if save_mat
    if exist(mat_save,'file'); delete(mat_save); end
    mo = matfile(mat_save, 'Writable', true);
    mo.dx = dx; mo.cutoff_days = cutoff_days; mo.N_butter = N_butter;
end

small = struct();
out_col = struct();
for j = 1:length(dirstr)
    d = dirstr(j);
    dc = char(d);
    nalong = length(geo.(d).lon);

    if save_mat
        mo.([dc,'_lon'])   = geo.(d).lon;
        mo.([dc,'_lat'])   = geo.(d).lat;
        mo.([dc,'_bathc']) = geo.(d).bathc;
        mo.([dc,'_angc'])  = geo.(d).angc;
    end

    % small, full-record fields -- accumulated in RAM, used both for the
    % MAT save below and directly by the netCDF-writing step at the end
    small.(d).ssh     = nan(nalong, 0);
    small.(d).rho_bar = nan(nalong, 0); small.(d).p_bar = nan(nalong, 0);
    small.(d).u_bar   = nan(nalong, 0); small.(d).v_bar = nan(nalong, 0);
    small.(d).Fx      = nan(nalong, 0); small.(d).Fy    = nan(nalong, 0);

    if save_mat
        % big, per-timestep fields: preallocate full-size on-disk datasets so
        % each chunk can write directly to its slice without ever holding the
        % full-record array in memory
        mo.([dc,'_p_prime'])(nalong, nz, nt_total) = single(0);
        mo.([dc,'_u_prime'])(nalong, nz, nt_total) = single(0);
        mo.([dc,'_v_prime'])(nalong, nz, nt_total) = single(0);
        mo.([dc,'_p_fast'])(nalong, nz, nt_total)  = single(0);
        mo.([dc,'_u_fast'])(nalong, nz, nt_total)  = single(0);
        mo.([dc,'_v_fast'])(nalong, nz, nt_total)  = single(0);
    end

    out_col.(d) = 0;
end
small_time = [];

%% ---- main chunk loop (computation) ----
for ci = 1:length(chunk_starts)
    c_start = chunk_starts(ci);
    c_end   = min(c_start + CHUNK_DAYS - 1, nfiles);
    p_start = max(1, c_start - PAD_DAYS);
    p_end   = min(nfiles, c_end + PAD_DAYS);

    fprintf('chunk %d/%d: output files %d-%d (%s to %s), read files %d-%d\n', ...
        ci, length(chunk_starts), c_start, c_end, fod(c_start), fod(c_end), p_start, p_end);

    win = read_padded_window(child_bry_path, dx, fod, dirstr, p_start, p_end, c_start, c_end);
    interior_idx = find(win.interior_mask);

    small_time = cat(1, small_time, win.time(interior_idx));

    for j = 1:length(dirstr)
        d = dirstr(j); dc = char(d);
        out = process_direction(d, win, geo, theta_s, theta_b, hc, nz, ...
            cutoff_days, N_butter, interior_idx);

        small.(d).ssh     = cat(2, small.(d).ssh,     out.ssh);
        small.(d).rho_bar = cat(2, small.(d).rho_bar, out.rho_bar);
        small.(d).p_bar   = cat(2, small.(d).p_bar,   out.p_bar);
        small.(d).u_bar   = cat(2, small.(d).u_bar,   out.u_bar);
        small.(d).v_bar   = cat(2, small.(d).v_bar,   out.v_bar);
        small.(d).Fx      = cat(2, small.(d).Fx,      out.Fx);
        small.(d).Fy      = cat(2, small.(d).Fy,      out.Fy);

        if save_mat
            ncols = numel(interior_idx);
            cols = out_col.(d) + (1:ncols);
            mo.([dc,'_p_prime'])(:,:,cols) = out.p_prime;
            mo.([dc,'_u_prime'])(:,:,cols) = out.u_prime;
            mo.([dc,'_v_prime'])(:,:,cols) = out.v_prime;
            mo.([dc,'_p_fast'])(:,:,cols)  = out.p_fast;
            mo.([dc,'_u_fast'])(:,:,cols)  = out.u_fast;
            mo.([dc,'_v_fast'])(:,:,cols)  = out.v_fast;
            out_col.(d) = out_col.(d) + ncols;
        end
    end
    clear win
end

%% ---- sanity check + save the small full-record fields ----
if save_mat
    for j = 1:length(dirstr)
        d = dirstr(j);
        assert(out_col.(d) == nt_total, ...
            'column bookkeeping mismatch for %s: wrote %d, expected %d', d, out_col.(d), nt_total);
    end
end
assert(length(small_time) == nt_total, 'time bookkeeping mismatch');

if save_mat
    mo.time = small_time;
    for j = 1:length(dirstr)
        d = dirstr(j); dc = char(d);
        mo.([dc,'_ssh'])     = small.(d).ssh;
        mo.([dc,'_rho_bar']) = small.(d).rho_bar;
        mo.([dc,'_p_bar'])   = small.(d).p_bar;
        mo.([dc,'_u_bar'])   = small.(d).u_bar;
        mo.([dc,'_v_bar'])   = small.(d).v_bar;
        mo.([dc,'_Fx'])      = small.(d).Fx;
        mo.([dc,'_Fy'])      = small.(d).Fy;
    end
    fprintf('done computing. saved diagnostic fields to %s\n', mat_save);
end

%% ---- write the daily flux netCDF files (from write_dynamic_bry_flux.m) ----
% Reads straight out of small_time / small.<dir>.Fx / small.<dir>.Fy --
% no MAT-file reload needed since this script just computed them.
real_time = small_time(:) + t1;
fprintf('flux time range: %s to %s\n', datestr(real_time(1)), datestr(real_time(end)));

write_daily_flux_nc(dating, fod, child_bry_path, flux_out_path, dx, small_time, small);

%% ============================================================================
function win = read_padded_window(child_bry_path, dx, fod, dirstr, p_start, p_end, c_start, c_end)
% Read files p_start:p_end ONCE each (all 4 directions sliced out of the
% same read), de-duplicating the repeated bry_time sample shared by
% consecutive daily files, and flag which resulting columns fall inside
% the [c_start, c_end] interior (non-padding) portion.
    win.time = [];
    win.interior_mask = logical([]);
    for j = 1:length(dirstr)
        d = dirstr(j);
        win.(d).ssh = []; win.(d).temp = []; win.(d).salt = [];
        win.(d).u = []; win.(d).v = [];
    end

    for f = p_start:p_end
        cbry = read_nc_fun(append(child_bry_path,'roms_bry_',num2str(dx),'m_',fod(f),'.nc'));
        if f == p_start
            keep_idx = 1:length(cbry.bry_time);       % first file in window: keep all
        else
            keep_idx = 2:length(cbry.bry_time);        % drop sample shared with previous file
        end
        win.time = cat(1, win.time, cbry.bry_time(keep_idx));
        is_interior = (f >= c_start) && (f <= c_end);
        win.interior_mask = cat(1, win.interior_mask, repmat(is_interior, length(keep_idx), 1));

        for j = 1:length(dirstr)
            d = dirstr(j);
            win.(d).ssh  = cat(2, win.(d).ssh,  cbry.(char("zeta_"+d))(:,keep_idx));
            win.(d).temp = cat(3, win.(d).temp, cbry.(char("temp_"+d))(:,:,keep_idx));
            win.(d).salt = cat(3, win.(d).salt, cbry.(char("salt_"+d))(:,:,keep_idx));
            win.(d).u    = cat(3, win.(d).u,    cbry.(char("u_"+d))(:,:,keep_idx));
            win.(d).v    = cat(3, win.(d).v,    cbry.(char("v_"+d))(:,:,keep_idx));
        end
        clear cbry
    end
end

function out = process_direction(d, win, geo, theta_s, theta_b, hc, nz, cutoff_days, N_butter, interior_idx)
% Same physics as the original script's per-direction pipeline
% (center2face -> zlevs3 -> density -> depth mean/anomaly -> pressure ->
% highpass -> flux), run on one padded time window, then trimmed to the
% interior (non-padding) columns before being returned.
    if d == "north" || d == "south"
        u = center2face(win.(d).u, 1);
        v = win.(d).v;
    else
        u = win.(d).u;
        v = center2face(win.(d).v, 1);
    end

    nt_local = size(win.(d).ssh, 2);
    bathc = geo.(d).bathc(:);

    z_r = zlevs3(repmat(bathc,1,nt_local), win.(d).ssh, theta_s, theta_b, hc, nz, 'r', 'new2008');
    z_r = permute(z_r, [2 1 3]);
    z_w = zlevs3(repmat(bathc,1,nt_local), win.(d).ssh, theta_s, theta_b, hc, nz, 'w', 'new2008');
    lthick = diff(permute(z_w, [2 1 3]), 1, 2);

    rho = density_calcuation(z_r, geo.(d).lon(:), geo.(d).lat(:), win.(d).temp, win.(d).salt, 2);
    [rho_bar, rho_prime] = depth_mean_bar_cal(rho, lthick, 2);
    p = density_pressure_cal(rho_prime, lthick, 2);
    [p_bar, p_prime] = depth_mean_bar_cal(p, lthick, 2);
    [u_bar, u_prime] = depth_mean_bar_cal(u, lthick, 2);
    [v_bar, v_prime] = depth_mean_bar_cal(v, lthick, 2);

    p_fast = highpass_time_cal(p_prime, win.time, cutoff_days, N_butter, 3);
    u_fast = highpass_time_cal(u_prime, win.time, cutoff_days, N_butter, 3);
    v_fast = highpass_time_cal(v_prime, win.time, cutoff_days, N_butter, 3);

    Fx = squeeze(sum(p_fast .* u_fast .* lthick, 2));
    Fy = squeeze(sum(p_fast .* v_fast .* lthick, 2));

    out.ssh     = win.(d).ssh(:, interior_idx);
    out.rho_bar = squeeze(rho_bar(:,1,interior_idx));
    out.p_bar   = squeeze(p_bar(:,1,interior_idx));
    out.u_bar   = squeeze(u_bar(:,1,interior_idx));
    out.v_bar   = squeeze(v_bar(:,1,interior_idx));
    out.Fx      = Fx(:, interior_idx);
    out.Fy      = Fy(:, interior_idx);
    out.p_prime = single(p_prime(:,:,interior_idx));
    out.u_prime = single(u_prime(:,:,interior_idx));
    out.v_prime = single(v_prime(:,:,interior_idx));
    out.p_fast  = single(p_fast(:,:,interior_idx));
    out.u_fast  = single(u_fast(:,:,interior_idx));
    out.v_fast  = single(v_fast(:,:,interior_idx));
end

function write_daily_flux_nc(dating, fod, child_bry_path, flux_out_path, dx, time, small)
% Writes one flux netCDF file per day, matching the existing
% roms_bry_<dx>m_<fod>.nc naming convention, containing:
%   up_west, up_east    (from Fx -- west/east boundaries)
%   vp_south, vp_north  (from Fy -- south/north boundaries)
%   bry_time            (same raw values/epoch as the existing bry files)
%
% Writes the RAW grid-relative Fx/Fy (e.g. small.north.Fx/Fy), NOT the
% geo-rotated versions: ROMS's own internal diag_pflx flux is
% grid-relative (xi/eta), so the externally-supplied Fext must be in the
% same convention for the obc_tune comparison to be meaningful.
    if ~exist(flux_out_path,'dir'); mkdir(flux_out_path); end

    % map: boundary direction -> {output varname, source Fx/Fy field,
    % REQUIRED along-boundary dimension name -- must be exactly 'eta_rho'
    % or 'xi_rho' for partit to recognize and decompose it correctly,
    % matching the convention zeta_west/zeta_south etc already use
    dir_map = struct( ...
        'west',  struct('varname','up_west', 'src', small.west.Fx,  'dim','eta_rho'), ...
        'east',  struct('varname','up_east', 'src', small.east.Fx,  'dim','eta_rho'), ...
        'south', struct('varname','vp_south','src', small.south.Fy, 'dim','xi_rho'), ...
        'north', struct('varname','vp_north','src', small.north.Fy, 'dim','xi_rho') ...
    );
    dirstr = ["west","east","south","north"];

    for d = 1:length(dating)

        % read this day's ORIGINAL bry file just to get its exact bry_time
        % values, then find those same samples in the master (concatenated,
        % deduplicated) time/Fx/Fy arrays -- more robust than reconstructing
        % day boundaries generically, and naturally handles whatever overlap
        % convention the original per-day files use without extra bookkeeping.
        cbry_name = append(child_bry_path, 'roms_bry_', num2str(dx), 'm_', fod(d), '.nc');
        cbry = read_nc_fun(cbry_name);
        day_bry_time = cbry.bry_time(:);

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
            append('roms_dbry_flux_',num2str(dx),'m_', fod(d), '.nc'));
        if exist(fname,'file'); delete(fname); end

        % bry_time: same values/epoch as the existing bry files (just the
        % subset of samples falling on this calendar day)
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
            along_dimname = dir_map.(dname).dim;    % 'eta_rho' or 'xi_rho'

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
end
