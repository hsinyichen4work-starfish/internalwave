function [parinit] = make_bry_need_temp(hgrd2, vgrd2, valid_lay, par_name, path_setup, boundary_path, lndsea)
    %MAKE_BRY_NEED_TEMP  Build the parinit (temp + salt) NetCDF file for h2r_bry_hv.m
    %
    %   [parinit] = make_bry_need_temp(hgrd2, vgrd2, par_name, path_setup, boundary_path, lndsea)
    %
    %   INPUTS
    %   ------
    %   hgrd2         : struct from read_ohgrd, needs hgrd2.lon (jgrd x igrd)
    %   vgrd2         : vertical grid array from read_ovgrdA, (jgrd x igrd x lo+1)
    %                   -- only used here to get the number of layers, lo
    %   par_name      : base name string, e.g. '2022082200'
    %   path_setup    : directory containing the seatmp*/salint* flat files
    %   boundary_path : output directory for the resulting _ts.nc file
    %   lndsea        : (optional) land/sea mask, (jgrd x igrd), 1=sea 0=land.
    %                   If provided, land points are set to NaN before writing.
    %
    %   NOTE: read_ncom_flatfile returns 3D fields (nlev>1) in NATIVE
    %   (igrd, jgrd, nlev) order -- UNTRANSPOSED -- unlike 2D fields, which
    %   come back transposed to (jgrd, igrd). This function relies on that
    %   distinction; do not "fix" it by adding a transpose here.
    
    if nargin < 6
        lndsea = [];
    end
    
    [jgrd, igrd] = size(hgrd2.lon);
    lo = size(vgrd2, 3) - 1;   % number of layers (interfaces - 1)
    
    if ~isempty(lndsea)
        % Transpose mask once to match the native (igrd, jgrd) field order,
        % then replicate across layers so it broadcasts correctly in 3D.
        lndsea_xy = lndsea;                        % (igrd, jgrd)
        mask3d    = repmat(lndsea_xy, [1 1 lo]);    % (igrd, jgrd, lo)
        for i = 1 : igrd
            for j = 1 : jgrd
                if ~isnan(valid_lay(i,j)) & valid_lay(i,j) < lo
                    mask3d(i,j,valid_lay(i,j)+1:end) = 0;
                end
            end
        end
    end
    
    %% --- Temperature ---
    d = dir(fullfile(path_setup, 'seatmp*'));
    if isempty(d)
        error('make_bry_need_temp:noFiles', 'No seatmp* files found in %s', path_setup);
    end
    nfiles_t = length(d);
    parsed_t(nfiles_t) = struct('name', [], 'datestr_in', [], 'timetag', []);
    for j = 1:nfiles_t
        s = extract_ncom_name(d(j).name);
        parsed_t(j).name       = d(j).name;
        parsed_t(j).datestr_in = s.datestr_in;
        parsed_t(j).timetag    = s.timetag;
    end
    sortkeys_t = strcat({parsed_t.datestr_in}, {parsed_t.timetag});
    [~, order_t] = sort(sortkeys_t);
    parsed_t = parsed_t(order_t);
    
    temp = NaN(igrd, jgrd, lo, nfiles_t);   % NATIVE order -- matches reader output
    for j = 1:nfiles_t
        s = extract_ncom_name(parsed_t(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        field = field - 273.15;   % Kelvin -> Celsius
        if ~isempty(lndsea)
            field(mask3d == 0) = NaN;
        end
        temp(:,:,:,j) = field;
    end
    
    %% --- Salinity (separately parsed and sorted -- do not reuse temp's file list) ---
    d = dir(fullfile(path_setup, 'salint*'));
    if isempty(d)
        error('make_bry_need_temp:noFiles', 'No salint* files found in %s', path_setup);
    end
    nfiles_s = length(d);
    parsed_s(nfiles_s) = struct('name', [], 'datestr_in', [], 'timetag', []);
    for j = 1:nfiles_s
        s = extract_ncom_name(d(j).name);
        parsed_s(j).name       = d(j).name;
        parsed_s(j).datestr_in = s.datestr_in;
        parsed_s(j).timetag    = s.timetag;
    end
    sortkeys_s = strcat({parsed_s.datestr_in}, {parsed_s.timetag});
    [~, order_s] = sort(sortkeys_s);
    parsed_s = parsed_s(order_s);
    
    if nfiles_s ~= nfiles_t
        warning('make_bry_need_temp:countMismatch', ...
            'Found %d seatmp files but %d salint files -- check your data folder.', ...
            nfiles_t, nfiles_s);
    end
    
    salt = NaN(igrd, jgrd, lo, nfiles_s);   % NATIVE order -- matches reader output
    for j = 1:nfiles_s
        s = extract_ncom_name(parsed_s(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        if ~isempty(lndsea)
            field(mask3d == 0) = NaN;
        end
        salt(:,:,:,j) = field;
    end

    
    %% --- Write the parinit NetCDF file ---
    % No transpose needed: temp/salt are already in (igrd, jgrd, lo, t) order,
    % matching what h2r_bry_hv.m expects (x, y, z, t).
    cd(boundary_path)
    
    parinit = [par_name, '_ts.nc'];
    if isfile(parinit)
        delete(parinit);
    end
    
    nccreate(parinit, 'layer_temperature', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'z', lo, 'time', Inf}, ...
        'Datatype', 'double');
    ncwrite(parinit, 'layer_temperature', temp, [1 1 1 1]);
    
    nccreate(parinit, 'layer_salinity', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'z', lo, 'time', Inf}, ...
        'Datatype', 'double');
    ncwrite(parinit, 'layer_salinity', salt, [1 1 1 1]);

    
    disp(['Wrote temp/salt file: ' parinit ...
        ' (' num2str(nfiles_t) ' temp steps, ' num2str(nfiles_s) ' salt steps)']);
    
end