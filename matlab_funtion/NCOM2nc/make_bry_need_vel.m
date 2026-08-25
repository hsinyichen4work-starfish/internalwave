function [pariniu] = make_bry_need_vel(hgrd2, vgrd2, valid_lay, grdang, par_name, path_setup, boundary_path, lndsea)
    %MAKE_BRY_NEED_VEL  Build the pariniu/pariniv (u + v) NetCDF file for h2r_bry_hv.m
    %
    %   [pariniu] = make_bry_need_vel(hgrd2, vgrd2, grdang, par_name, path_setup, boundary_path, lndsea)
    %
    %   INPUTS
    %   ------
    %   hgrd2         : struct from read_ohgrd, needs hgrd2.lon (jgrd x igrd)
    %   vgrd2         : vertical grid array from read_ovgrdA, (jgrd x igrd x lo+1)
    %                   -- only used here to get the number of layers, lo
    %   grdang        : grid angle field, DEGREES from true east, (jgrd x igrd)
    %                   -- same static field read earlier via
    %                   read_ncom_flatfile(..., 'grdang', ...)
    %   par_name      : base name string, e.g. '2022082200'
    %   path_setup    : directory containing the uucurr*/vvcurr* flat files
    %   boundary_path : output directory for the resulting _uv.nc file
    %   lndsea        : (optional) land/sea mask, (jgrd x igrd), 1=sea 0=land.
    %                   If provided, land points are set to NaN before writing.
    %
    %   NOTE 1: read_ncom_flatfile returns 3D fields (nlev>1) in NATIVE
    %   (igrd, jgrd, nlev) order -- UNTRANSPOSED. This function relies on
    %   that; do not add a transpose here.
    %
    %   NOTE 2: this writes ONE combined file (both u_velocity and v_velocity)
    %   since h2r_bry_make_1hr.m sets pariniu and pariniv to the SAME
    %   filename anyway -- consistent with that driver script's convention.
    %
    %   NOTE 3: this writes an MT variable (days since 1900-12-31), one value
    %   per time step, computed from each file's date/forecast-hour tag.
    %   h2r_bry_hv.m currently reads only the FIRST MT value regardless of
    %   loop index (ncread(pariniu,'MT',1,1)) and always reads parent data at
    %   tind=1 -- see the separate note below about the matching edit needed
    %   in h2r_bry_hv.m itself before this consolidated, multi-time-step file
    %   will be read correctly across all your forecast hours.
    
    if nargin < 7
        lndsea = [];
    end
    
    [jgrd, igrd] = size(hgrd2.lon);
    lo = size(vgrd2, 3) - 1;   % number of layers (interfaces - 1)
    
    if ~isempty(lndsea)
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

    grdang_xy = grdang';   % (igrd, jgrd) -- match native 3D order for broadcasting
    
    %% --- U ---
    d = dir(fullfile(path_setup, 'uucurr*'));
    if isempty(d)
        error('make_bry_need_vel:noFiles', 'No uucurr* files found in %s', path_setup);
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
    
    u = NaN(igrd, jgrd, lo, nfiles_u);   % NATIVE order -- matches reader output
    for j = 1:nfiles_u
        s = extract_ncom_name(parsed_u(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        if ~isempty(lndsea)
            field(mask3d == 0) = NaN;
        end
        u(:,:,:,j) = field;
    end
    
    %% --- V (separately parsed and sorted -- do not reuse u's file list) ---
    d = dir(fullfile(path_setup, 'vvcurr*'));
    if isempty(d)
        error('make_bry_need_vel:noFiles', 'No vvcurr* files found in %s', path_setup);
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
        warning('make_bry_need_vel:countMismatch', ...
            'Found %d uucurr files but %d vvcurr files -- check your data folder.', ...
            nfiles_u, nfiles_v);
    end
    
    v = NaN(igrd, jgrd, lo, nfiles_v);   % NATIVE order -- matches reader output
    for j = 1:nfiles_v
        s = extract_ncom_name(parsed_v(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        if ~isempty(lndsea)
            field(mask3d == 0) = NaN;
        end
        v(:,:,:,j) = field;
    end
    
    %% --- Average to centers, then rotate to true east/north ---
    uc = avg_face_to_center(u, 1);   % x-faces -> centers
    vc = avg_face_to_center(v, 2);   % y-faces -> centers
    [u_true, v_true] = vel_rot(uc, vc, grdang_xy', 'grid2geo');
    
    %% --- Compute MT (days since 1900-12-31) for each sorted U time step ---
    t_ref = datenum(1900,12,31,0,0,0);
    MT = NaN(1, nfiles_u);
    for j = 1:nfiles_u
        base_dt   = datenum(parsed_u(j).datestr_in, 'yyyymmddHH');
        lead_hrs  = str2double(parsed_u(j).timetag(1:4));
        valid_dt  = base_dt + lead_hrs/24;
        MT(j)     = valid_dt - t_ref;
    end
    
    %% --- Write the pariniu/pariniv NetCDF file ---
    cd(boundary_path)
    
    pariniu = [par_name, '_uv.nc'];
    if isfile(pariniu)
        delete(pariniu);
    end
    
    nccreate(pariniu, 'u_velocity', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'z', lo, 'time', Inf}, ...
        'Datatype', 'double');
    ncwrite(pariniu, 'u_velocity', u_true, [1 1 1 1]);
    
    nccreate(pariniu, 'v_velocity', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'z', lo, 'time', Inf}, ...
        'Datatype', 'double');
    ncwrite(pariniu, 'v_velocity', v_true, [1 1 1 1]);
    
    nccreate(pariniu, 'MT', 'Dimensions', {'time', Inf}, 'Datatype', 'double');
    ncwrite(pariniu, 'MT', MT, [1]);
    
    disp(['Wrote u/v file: ' pariniu ...
        ' (' num2str(nfiles_u) ' u steps, ' num2str(nfiles_v) ' v steps)']);
    
end