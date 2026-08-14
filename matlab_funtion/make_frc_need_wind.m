function [pariniw] = make_frc_need_wind(hgrd2, grdang, par_name, path_setup, forcing_path, lndsea)
    %MAKE_FRC_NEED_WIND  Build the pariniw (stresu + stresv) file for h2r_frc_hv.m
    %
    %   [pariniw] = make_frc_need_wind(hgrd2, grdang, par_name, path_setup, forcing_path, lndsea)
    %
    %   INPUTS
    %   ------
    %   hgrd2         : struct from read_ohgrd, needs hgrd2.lon (jgrd x igrd)
    %   grdang        : grid angle field, DEGREES from true east, (jgrd x igrd)
    %   par_name      : base name string, e.g. '2022082200'
    %   path_setup    : directory containing the stresu*/stresv* flat files
    %   forcing_path  : output directory for the resulting _wnd.nc file
    %   lndsea        : (optional) land/sea mask, (jgrd x igrd), 1=sea 0=land.
    %                   If provided, land points are set to NaN before writing.
    %
    %   NOTE 1: unlike uucurr/vvcurr (horiz=f, on cell faces), stresu/stresv
    %   are listed as horiz=c in the NCOM variable table -- they are already
    %   co-located with the scalar fields at cell centers, so there is NO
    %   face-to-center averaging step here (unlike make_bry_need_vel.m).
    %
    %   NOTE 2: stresu/stresv are 2D fields, so read_ncom_flatfile returns
    %   them TRANSPOSED to (jgrd, igrd) -- transposed back here to
    %   (igrd, jgrd) before rotation, matching the convention used
    %   elsewhere in this pipeline.
    %
    %   NOTE 3: components are still expressed along the model's rotated
    %   grid x/y axes even though co-located at centers, so they still need
    %   rotation to true east/north via grdang before being handed to
    %   h2r_frc_hv.m for interpolation onto the ROMS grid.

    if nargin < 6
        lndsea = [];
    end

    [jgrd, igrd] = size(hgrd2.lon);

    if ~isempty(lndsea)
        lndsea_xy = lndsea;   % (igrd, jgrd), matches transposed field order
    end

    grdang_xy = grdang';   % (igrd, jgrd)

    %% --- U component (stresu) ---
    d = dir(fullfile(path_setup, 'stresu*'));
    if isempty(d)
        error('make_frc_need_wind:noFiles', 'No stresu* files found in %s', path_setup);
    end
    nfiles_u = length(d);
    parsed_u(nfiles_u) = struct('name', [], 'datestr_in', [], 'timetag', []);
    for j = 1:nfiles_u
        s = extract_ncom_name(d(j).name);
        parsed_u(j).name       = d(j).name;
        parsed_u(j).datestr_in = s.datestr_in;
        parsed_u(j).timetag    = s.timetag;
    end
    sortkeys_u = strcat({parsed_u.datestr_in}, {parsed_u.timetag});
    [~, order_u] = sort(sortkeys_u);
    parsed_u = parsed_u(order_u);

    u = NaN(igrd, jgrd, nfiles_u);
    for j = 1:nfiles_u
        s = extract_ncom_name(parsed_u(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        field = field';   % (jgrd,igrd) -> (igrd,jgrd) -- 2D field, see NOTE 2 above
        if ~isempty(lndsea)
            field(lndsea_xy == 0) = NaN;
        end
        u(:,:,j) = field;
    end

    %% --- V component (stresv) -- separately parsed and sorted ---
    d = dir(fullfile(path_setup, 'stresv*'));
    if isempty(d)
        error('make_frc_need_wind:noFiles', 'No stresv* files found in %s', path_setup);
    end
    nfiles_v = length(d);
    parsed_v(nfiles_v) = struct('name', [], 'datestr_in', [], 'timetag', []);
    for j = 1:nfiles_v
        s = extract_ncom_name(d(j).name);
        parsed_v(j).name       = d(j).name;
        parsed_v(j).datestr_in = s.datestr_in;
        parsed_v(j).timetag    = s.timetag;
    end
    sortkeys_v = strcat({parsed_v.datestr_in}, {parsed_v.timetag});
    [~, order_v] = sort(sortkeys_v);
    parsed_v = parsed_v(order_v);

    if nfiles_v ~= nfiles_u
        warning('make_frc_need_wind:countMismatch', ...
            'Found %d stresu files but %d stresv files -- check your data folder.', ...
            nfiles_u, nfiles_v);
    end

    v = NaN(igrd, jgrd, nfiles_v);
    for j = 1:nfiles_v
        s = extract_ncom_name(parsed_v(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        field = field';   % (jgrd,igrd) -> (igrd,jgrd)
        if ~isempty(lndsea)
            field(lndsea_xy == 0) = NaN;
        end
        v(:,:,j) = field;
    end

    %% --- Rotate to true east/north (no face-to-center averaging needed) ---
    % NOTE: passing grdang_xy' here (not grdang_xy) to exactly match the
    % orientation convention used in make_bry_need_vel.m's vel_rot call.
    [u_true, v_true] = vel_rot(u, v, grdang_xy', 'grid2geo');

    %% --- Compute MT (days since 1900-12-31) for each sorted U time step ---
    t_ref = datenum(1900,12,31,0,0,0);
    MT = NaN(1, nfiles_u);
    for j = 1:nfiles_u
        base_dt  = datenum(parsed_u(j).datestr_in, 'yyyymmddHH');
        lead_hrs = str2double(parsed_u(j).timetag(1:4));
        valid_dt = base_dt + lead_hrs/24;
        MT(j)    = valid_dt - t_ref;
    end

    %% --- Write the pariniw NetCDF file ---
    cd(forcing_path)

    pariniw = [par_name, '_wnd.nc'];
    if isfile(pariniw)
        delete(pariniw);
    end

    nccreate(pariniw, 'stresu', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'time', Inf}, ...
        'Datatype', 'double');
    ncwrite(pariniw, 'stresu', u_true, [1 1 1]);

    nccreate(pariniw, 'stresv', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'time', Inf}, ...
        'Datatype', 'double');
    ncwrite(pariniw, 'stresv', v_true, [1 1 1]);

    nccreate(pariniw, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
    ncwrite(pariniw, 'MT', MT, [1]);

    disp(['Wrote wind stress file: ' pariniw ...
        ' (' num2str(nfiles_u) ' u steps, ' num2str(nfiles_v) ' v steps)']);

end