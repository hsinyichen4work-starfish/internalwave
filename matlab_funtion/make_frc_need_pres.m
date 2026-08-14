function [parinip] = make_frc_need_pres(hgrd2, par_name, path_setup, forcing_path, lndsea)
    %MAKE_FRC_NEED_PRES  Build the parinip (slpres) file for h2r_frc_hv.m
    %
    %   [parinip] = make_frc_need_pres(hgrd2, par_name, path_setup, forcing_path, lndsea)
    %
    %   INPUTS
    %   ------
    %   hgrd2         : struct from read_ohgrd, needs hgrd2.lon (jgrd x igrd)
    %   par_name      : base name string, e.g. '2022082200'
    %   path_setup    : directory containing the slpres* flat files
    %   forcing_path  : output directory for the resulting _pres.nc file
    %   lndsea        : (optional) land/sea mask, (jgrd x igrd), 1=sea 0=land.
    %                   If provided, land points are set to NaN before writing.
    %
    %   NOTE: slpres is a 2D field, so read_ncom_flatfile returns it
    %   TRANSPOSED to (jgrd, igrd) -- transposed back here to (igrd, jgrd)
    %   to match the convention used elsewhere in this pipeline.

    if nargin < 5
        lndsea = [];
    end

    [jgrd, igrd] = size(hgrd2.lon);

    if ~isempty(lndsea)
        lndsea_xy = lndsea;   % (igrd, jgrd), matches transposed field order
    end

    d = dir(fullfile(path_setup, 'slpres*'));
    if isempty(d)
        error('make_frc_need_pres:noFiles', 'No slpres* files found in %s', path_setup);
    end
    nfiles = length(d);
    parsed(nfiles) = struct('name', [], 'datestr_in', [], 'timetag', []);
    for j = 1:nfiles
        s = extract_ncom_name(d(j).name);
        parsed(j).name       = d(j).name;
        parsed(j).datestr_in = s.datestr_in;
        parsed(j).timetag    = s.timetag;
    end
    sortkeys = strcat({parsed.datestr_in}, {parsed.timetag});
    [~, order] = sort(sortkeys);
    parsed = parsed(order);

    pres = NaN(igrd, jgrd, nfiles);
    for j = 1:nfiles
        s = extract_ncom_name(parsed(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        field = field';   % (jgrd,igrd) -> (igrd,jgrd) -- 2D field, see NOTE above
        if ~isempty(lndsea)
            field(lndsea_xy == 0) = NaN;
        end
        pres(:,:,j) = field;
    end

    %% --- Compute MT (days since 1900-12-31) ---
    t_ref = datenum(1900,12,31,0,0,0);
    MT = NaN(1, nfiles);
    for j = 1:nfiles
        base_dt  = datenum(parsed(j).datestr_in, 'yyyymmddHH');
        lead_hrs = str2double(parsed(j).timetag(1:4));
        valid_dt = base_dt + lead_hrs/24;
        MT(j)    = valid_dt - t_ref;
    end

    %% --- Write the parinip NetCDF file ---
    cd(forcing_path)

    parinip = [par_name, '_pres.nc'];
    if isfile(parinip)
        delete(parinip);
    end

    nccreate(parinip, 'slpres', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'time', Inf}, ...
        'Datatype', 'double');
    ncwrite(parinip, 'slpres', pres, [1 1 1]);

    nccreate(parinip, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
    ncwrite(parinip, 'MT', MT, [1]);

    disp(['Wrote pressure file: ' parinip ...
        ' (' num2str(nfiles) ' time steps)']);

end