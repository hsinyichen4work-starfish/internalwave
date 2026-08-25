function [par_ini_eta] = make_bry_need_ssh(hgrd2, par_name, path_setup, boundary_path, lndsea)
    %MAKE_BRY_NEED_SSH  Build the parinie (ssh) NetCDF file for h2r_bry_hv.m
    %
    %   [par_ini_eta] = make_bry_need_ssh(hgrd2, par_name, path_setup, boundary_path, lndsea)
    %
    %   INPUTS
    %   ------
    %   hgrd2         : struct from read_ohgrd, needs hgrd2.lon (jgrd x igrd)
    %   par_name      : base name string, e.g. '2022082200'
    %   path_setup    : directory containing the seahgt*_datafld/_fcstfld files
    %   boundary_path : output directory for the resulting _ssh.nc file
    %   lndsea        : (optional) land/sea mask, (jgrd x igrd), 1=sea 0=land.
    %                   If provided, land points are set to NaN before writing
    %                   so h2r_bry_hv.m's isnan-based masking works correctly.
    %                   If NCOM's fill value for land isn't already NaN in the
    %                   raw field, this argument is required for correctness.
    
    if nargin < 5
        lndsea = [];
    end
    
    [jgrd, igrd] = size(hgrd2.lon);
    
    %% Find and sort the seahgt files chronologically
    d = dir(fullfile(path_setup, 'seahgt*'));
    if isempty(d)
        error('make_bry_need_ssh:noFiles', 'No seahgt* files found in %s', path_setup);
    end
    
    % Parse each name once, up front, so we can sort by actual date/time
    % rather than trusting dir()'s (often alphabetical, but not guaranteed)
    % ordering.
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


    %% Read each SSH field into a (jgrd, igrd, t) array
    ssh = NaN(jgrd, igrd, nfiles);
    for j = 1:nfiles
        disp("new")
        s = extract_ncom_name(parsed(j).name);
        field = read_ncom_flatfile(path_setup, s.fldname, s.igrd, s.jgrd, ...
            s.nest, s.datestr_in, s.timetag, s.appd, s.nlev, s.isface);
        if ~isempty(lndsea)
            if isequal(size(lndsea), size(field))
                field(lndsea == 0) = NaN;   % mask land explicitly
            else
                lndsea = lndsea';
                disp("transpose")
                field(lndsea == 0) = NaN;   % mask land explicitly
            end
        end
        ssh(:,:,j) = field;
    end
    
    %% Transpose to (igrd, jgrd, t) -- the order h2r_bry_hv.m expects
    ssh_xy = permute(ssh, [2 1 3]);
    
    %% Write the parinie NetCDF file
    cd(boundary_path)
    
    par_ini_eta = [par_name, '_ssh.nc'];
    if isfile(par_ini_eta)
        delete(par_ini_eta);
    end
    
    nccreate(par_ini_eta, 'ssh', ...
        'Dimensions', {'xi', igrd, 'eta', jgrd, 'time', Inf}, ...
        'Datatype', 'double');
    
    ncwrite(par_ini_eta, 'ssh', ssh_xy, [1 1 1]);

    
    disp(['Wrote SSH file: ' par_ini_eta ' (' num2str(nfiles) ' time steps)']);
    
end