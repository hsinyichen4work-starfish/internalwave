clear; clc;
addpath(genpath('/home/hsinyi/Documents/CODE/matlab_funtion'), '-end');

%% ============================================================================
% dbrt_900_imporve.m
%
% Memory-bounded rewrite of dtnamic_bry_900.m for the high-frequency
% baroclinic energy flux (Fx, Fy) at the child-grid open boundaries.
%
% WHAT CHANGED vs. dtnamic_bry_900.m, and why:
%
% 1) Read each boundary file ONCE, not 4x. The original looped
%    direction-outer / file-inner, so every hourly file (one file per
%    calendar day here, 25 hourly bry_time records each) was re-read
%    separately for north, south, east, AND west, even though a single
%    file already contains all four. This version loops file-outer and
%    slices all four directions out of the one read.
%
% 2) Time-chunked, padded processing instead of loading the whole
%    record. density_calcuation, depth_mean_bar_cal,
%    density_pressure_cal, zlevs3, and center2face all operate
%    independently at each time step -- verified by reading their
%    source, none of them couple across time. The ONLY step that needs
%    temporal context is highpass_time_cal (filtfilt-based), and that
%    only needs a padding window of a few days around each chunk, not
%    the full multi-month record. So this script processes CHUNK_DAYS
%    of *output* at a time, padded by PAD_DAYS of extra data read on
%    each side (clipped at the true record edges), filters the padded
%    window, keeps only the interior (unpadded) result, and discards
%    the chunk's big raw/intermediate 3-D arrays before moving on.
%    Peak memory is therefore set by CHUNK_DAYS + 2*PAD_DAYS, NOT by
%    the total date range -- the same script handles a multi-year
%    record with the same peak memory as a 3-month one.
%
% 3) Only the small, fully time-reduced fields (ssh, Fx, Fy, and the
%    depth-mean *_bar profiles) are accumulated in RAM for the whole
%    record. The big per-timestep 3-D fields kept from the original
%    pipeline (p_prime, u_prime, v_prime, p_fast, u_fast, v_fast -- the
%    ones the commented-out diagnostic plots at the bottom actually
%    use) are written straight to the output MAT-file per chunk via
%    indexed assignment into a PREALLOCATED -v7.3/HDF5-backed dataset
%    (see the matfile() calls below) -- this writes to disk without
%    ever holding the full-record array in memory (verified: assigning
%    a (nalong,128,~2300) single-precision block this way takes <0.1s
%    and does not spike RSS, vs. materializing it in the workspace
%    first). Load slices back later with matfile(...), e.g.
%    mo.north_p_fast(1050,:,:) -- no need to load the whole variable.
%
%    child_z, lthick, rho, rho_prime, p, and the raw temp/salt/u/v are
%    NOT persisted -- they're only intermediate inputs on the way to
%    the *_prime/*_fast/*_bar fields and aren't referenced anywhere
%    downstream in the original script. To persist any of them too,
%    follow the exact same pattern used for p_prime below: preallocate
%    a dataset sized (nalong,nz,nt_total) before the chunk loop, then
%    write mo.<name>(:,:,cols) = <value> inside the chunk loop.
%
% 4) De-duplicated time samples. Each daily file's bry_time runs
%    00:00 that day through 00:00 the next day (25 hourly samples), so
%    consecutive files share one identical timestamp (verified against
%    the real files: file N's last bry_time == file N+1's first,
%    exactly). The original script's plain `cat` kept both copies,
%    giving the time axis (and therefore the filtered output) a
%    repeated, zero-spacing sample at every day boundary. This version
%    drops the duplicate.
%
% 5) No eval(). Field names are built as char/string and accessed with
%    dynamic field syntax (s.(name)) instead -- same result, no string
%    re-parsing, and tools/debugger can see the real field access.
%
% >>> VALIDATION NOTE <<<
% PAD_DAYS is a guess at "enough" transient padding for a 5th-order,
% ~29-hour-cutoff Butterworth filter. It was sanity-checked once on
% this machine (see conversation) by comparing a multi-chunk run
% against a single-chunk (unpadded-internally) reference over the same
% short date range and confirming Fx/Fy matched away from the true
% record edges. If you change cutoff_days, N_butter, CHUNK_DAYS, or
% PAD_DAYS, or if downstream diagnostics look off near a chunk seam,
% re-check by increasing PAD_DAYS and confirming the output doesn't
% change.
%% ============================================================================

%% ---- user settings ----
dx = 900;
child_grid_path = '/home/hsinyi/roms_data/grid/';
child_bry_path  = '/home/hsinyi/roms_data/bry_63/';
cgrid_name = ['roms_grd_',num2str(dx),'m.nc'];

date_start = "20220822";
date_end   = "20221125";

cutoff_days = 28/24;   % ~29 hours, per your PI's 28-30 hr suggestion
N_butter    = 5;

CHUNK_DAYS = 15;   % days of *output* produced per chunk
PAD_DAYS   = 6;    % extra days read (and discarded) on each side of a
                    % chunk to give the highpass filter a clean transient

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

%% ---- preallocate the on-disk output file ----
if exist(mat_save,'file'); delete(mat_save); end
mo = matfile(mat_save, 'Writable', true);
mo.dx = dx; mo.cutoff_days = cutoff_days; mo.N_butter = N_butter;

small = struct();
out_col = struct();
for j = 1:length(dirstr)
    d = dirstr(j);
    dc = char(d);
    nalong = length(geo.(d).lon);

    mo.([dc,'_lon'])   = geo.(d).lon;
    mo.([dc,'_lat'])   = geo.(d).lat;
    mo.([dc,'_bathc']) = geo.(d).bathc;
    mo.([dc,'_angc'])  = geo.(d).angc;

    % small, full-record fields -- accumulated in RAM, written once at the end
    small.(d).ssh     = nan(nalong, 0);
    small.(d).rho_bar = nan(nalong, 0); small.(d).p_bar = nan(nalong, 0);
    small.(d).u_bar   = nan(nalong, 0); small.(d).v_bar = nan(nalong, 0);
    small.(d).Fx      = nan(nalong, 0); small.(d).Fy    = nan(nalong, 0);

    % big, per-timestep fields: preallocate full-size on-disk datasets so
    % each chunk can write directly to its slice without ever holding the
    % full-record array in memory (see VALIDATION NOTE / matfile prealloc)
    mo.([dc,'_p_prime'])(nalong, nz, nt_total) = single(0);
    mo.([dc,'_u_prime'])(nalong, nz, nt_total) = single(0);
    mo.([dc,'_v_prime'])(nalong, nz, nt_total) = single(0);
    mo.([dc,'_p_fast'])(nalong, nz, nt_total)  = single(0);
    mo.([dc,'_u_fast'])(nalong, nz, nt_total)  = single(0);
    mo.([dc,'_v_fast'])(nalong, nz, nt_total)  = single(0);

    out_col.(d) = 0;
end
small_time = [];

%% ---- main chunk loop ----
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
    clear win
end

%% ---- sanity check + save the small full-record fields ----
for j = 1:length(dirstr)
    d = dirstr(j);
    assert(out_col.(d) == nt_total, ...
        'column bookkeeping mismatch for %s: wrote %d, expected %d', d, out_col.(d), nt_total);
end
assert(length(small_time) == nt_total, 'time bookkeeping mismatch');

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
fprintf('done. saved to %s\n', mat_save);

%% ---- example: pull one along-boundary slice back out without loading the whole field ----
% mo = matfile(mat_save);
% p_fast_slice  = mo.west_p_fast(1050,:,:);
% p_prime_slice = mo.west_p_prime(1050,:,:);
% figure; clf;
% ti = tiledlayout(2,1); ti.Padding = "compact"; ti.TileSpacing = "tight";
% nexttile; pcolor(squeeze(p_fast_slice)); shading flat; colorbar; clim([-1 1]*1000)
% nexttile; pcolor(squeeze(p_prime_slice) - mean(squeeze(p_prime_slice),2)); shading flat; colorbar; clim([-1 1]*1000)

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
