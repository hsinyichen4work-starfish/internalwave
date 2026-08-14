function [parinis] = make_frc_need_flux(hgrd2, par_name, path_setup, forcing_path, lndsea)
    %MAKE_FRC_NEED_FLUX  Build the parinis (heaflx + salflx + solflx) file
    %                     for h2r_frc_hv.m
    %
    %   [parinis] = make_frc_need_flux(hgrd2, par_name, path_setup, forcing_path, lndsea)
    %
    %   INPUTS
    %   ------
    %   hgrd2         : struct from read_ohgrd, needs hgrd2.lon (jgrd x igrd)
    %   par_name      : base name string, e.g. '2022082200'
    %   path_setup    : directory containing the heaflx*/salflx*/solflx* flat files
    %   forcing_path  : output directory for the resulting _flx.nc file
    %   lndsea        : (optional) land/sea mask, (jgrd x igrd), 1=sea 0=land.
    %                   If provided, land points are set to NaN before writing.
    %
    %   NOTE: heaflx/salflx/solflx are all 2D fields. read_ncom_flatfile
    %   returns 2D fields TRANSPOSED to (jgrd, igrd) -- unlike the 3D
    %   fields used in make_bry_need_temp.m/make_bry_need_vel.m, which come
    %   back native (igrd, jgrd, nlev). Each field is transposed back here
    %   to (igrd, jgrd) so parinis matches the same (xi, eta, time)
    %   convention used everywhere else in this pipeline.

    if nargin < 5
        lndsea = [];
    end

    [jgrd, igrd] = size(hgrd2.lon);

    if ~isempty(lndsea)
        lndsea_xy = lndsea;   % (igrd, jgrd), matches transposed field order
    end

    fields = {'heaflx','salflx','solflx'};
    varout = {'heaflx','salflx','solflx'};
    data   = struct();
    ntime  = struct();

    for f = 1:numel(fields)
        fld = fields{f};
        d = dir(fullfile(path_setup, [fld '*']));
        if isempty(d)
            error('make_frc_need_flux:noFiles', 'No %s* files found in %s', fld, path_setup);
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

        var = NaN(igrd, jgrd, nfiles);
        for j = 1:nfiles
            s = extract_ncom_name(parsed(j).name);
            field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
                s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
            field = field';   % (jgrd,igrd) -> (igrd,jgrd) -- 2D field, see NOTE above
            if ~isempty(lndsea)
                field(lndsea_xy == 0) = NaN;
            end
            var(:,:,j) = field;
        end

        data.(fld)  = var;
        ntime.(fld) = nfiles;

        if f == 1
            % keep the MT tag from the first field's file list; downstream
            % code assumes heaflx/salflx/solflx share the same time steps
            parsed_ref = parsed;
        elseif nfiles ~= ntime.(fields{1})
            warning('make_frc_need_flux:countMismatch', ...
                'Found %d %s files but %d %s files -- check your data folder.', ...
                nfiles, fld, ntime.(fields{1}), fields{1});
        end
    end

    %% --- Compute MT (days since 1900-12-31) ---
    t_ref = datenum(1900,12,31,0,0,0);
    nfiles_ref = numel(parsed_ref);
    MT = NaN(1, nfiles_ref);
    for j = 1:nfiles_ref
        base_dt  = datenum(parsed_ref(j).datestr_in, 'yyyymmddHH');
        lead_hrs = str2double(parsed_ref(j).timetag(1:4));
        valid_dt = base_dt + lead_hrs/24;
        MT(j)    = valid_dt - t_ref;
    end

    %% --- Write the parinis NetCDF file ---
    cd(forcing_path)

    parinis = [par_name, '_flx.nc'];
    if isfile(parinis)
        delete(parinis);
    end

    for f = 1:numel(fields)
        fld = fields{f};
        nccreate(parinis, varout{f}, ...
            'Dimensions', {'xi', igrd, 'eta', jgrd, 'time', Inf}, ...
            'Datatype', 'double');
        ncwrite(parinis, varout{f}, data.(fld), [1 1 1]);
    end

    nccreate(parinis, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
    ncwrite(parinis, 'MT', MT, [1]);

    disp(['Wrote flux file: ' parinis ...
        ' (' num2str(nfiles_ref) ' time steps)']);

end