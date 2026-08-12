function data = read_ncom_flatfile(path_ff, fldname, igrd, jgrd, nest, ...
    datestr_in, timetag, appd, nlev, isface, transpose2d)
%READ_NCOM_FLATFILE  Read one NCOM/COAMPS-style binary flat file.
%
%   data = READ_NCOM_FLATFILE(path_ff, fldname, igrd, jgrd, nest, ...
%              datestr_in, timetag, appd, nlev, isface, transpose2d)
%
%   Generalizes the read pattern in Jie Yu's post_ffout_4yadi.m example
%   to any field in the NCOM output table (2D or 3D, static grid file or
%   time-varying forecast field).
%
%   INPUTS
%   ------
%   path_ff     : directory containing the flat file (string, no trailing
%                 slash needed; e.g. the dated ffout folder for forecast
%                 fields, or the static grid directory for grid fields)
%   fldname     : field name string, e.g. 'grdlat','grdlon','grdang',
%                 'depthr','lndsea','seahgt','seatmp','salint',
%                 'uucurr','vvcurr','wwcurr','udbaro','vdbaro', etc.
%   igrd, jgrd  : horizontal grid dimensions (nx, ny)
%   nest        : nest number (1, 2, or 3)
%   datestr_in  : date tag used in the file name, e.g. '2022082400'
%                 (for static/grid fields, use the date embedded in the
%                 file name itself; for forecast fields, use the analysis
%                 date of the folder, e.g. '2022082300')
%   timetag     : time tag used in the file name, e.g. '00000000' for a
%                 static/grid field, or '00240000' for a 24-hr forecast
%                 field (format: HHHH0000, HHHH = forecast lead hours)
%   appd        : file suffix, '_datafld' for static grid fields,
%                 '_fcstfld' for time-varying forecast fields
%   nlev        : number of vertical levels
%                 - use 1 for 2D fields (e.g. seahgt, grdlat, depthr)
%                 - use 100 for 3D center fields (e.g. seatmp, salint,
%                   uucurr, vvcurr) -- adjust if your config uses a
%                   different level count
%   isface      : true if this is a vertical-face (w-point) field, i.e.
%                 nlev+1 levels in the file name (e.g. wwcurr); false
%                 otherwise. Ignored when nlev==1.
%   transpose2d : (optional, default true) if true, 2D output is
%                 transposed to (jgrd x igrd), matching the convention
%                 used for hgrd.lon/hgrd.lat and ssh in the example
%                 script. 3D output is always returned in native
%                 (igrd x jgrd x nlev) "NCOM form", untransposed --
%                 transpose 2D slices yourself downstream as needed,
%                 exactly as the example script does for sst.
%
%   OUTPUT
%   ------
%   data : for 2D fields, a (jgrd x igrd) array [or (igrd x jgrd) if
%          transpose2d is false]
%          for 3D fields, an (igrd x jgrd x nlev) array, in native NCOM
%          form (not transposed -- see note above)
%
%   EXAMPLES
%   --------
%   % Static grid fields (note the '_datafld' suffix and the date/time
%   % tag embedded in the actual file name on disk -- use those exact
%   % strings, they do not necessarily match your forecast dates):
%   grdlat = read_ncom_flatfile(path_grid, 'grdlat', 1244, 1334, 2, ...
%                '2022082400', '00000000', '_datafld', 1, false);
%   grdlon = read_ncom_flatfile(path_grid, 'grdlon', 1244, 1334, 2, ...
%                '2022082400', '00000000', '_datafld', 1, false);
%   grdang = read_ncom_flatfile(path_grid, 'grdang', 1244, 1334, 2, ...
%                '2022082400', '00000000', '_datafld', 1, false);
%   depthr = read_ncom_flatfile(path_grid, 'depthr', 1244, 1334, 2, ...
%                '2022082400', '00000000', '_datafld', 1, false);
%
%   % 2D forecast field (sea surface height), 24-hr forecast from the
%   % 2022-08-23 00Z analysis:
%   ssh = read_ncom_flatfile(path_ff, 'seahgt', 1244, 1334, 2, ...
%                '2022082300', '00240000', '_fcstfld', 1, false);
%
%   % 3D center field (temperature, still in Kelvin -- convert yourself):
%   seatmp_K = read_ncom_flatfile(path_ff, 'seatmp', 1244, 1334, 2, ...
%                '2022082300', '00240000', '_fcstfld', 100, false);
%   seatmp_C = seatmp_K - 273.15;
%
%   % 3D center velocity fields (still on native u/v faces -- average to
%   % centers and rotate yourself before use, see h2r_bry_hv.m notes):
%   uucurr = read_ncom_flatfile(path_ff, 'uucurr', 1244, 1334, 2, ...
%                '2022082300', '00240000', '_fcstfld', 100, false);
%   vvcurr = read_ncom_flatfile(path_ff, 'vvcurr', 1244, 1334, 2, ...
%                '2022082300', '00240000', '_fcstfld', 100, false);
%
%   % 3D face field (vertical velocity, nlev+1 = 101 levels in the name):
%   wwcurr = read_ncom_flatfile(path_ff, 'wwcurr', 1244, 1334, 2, ...
%                '2022082300', '00240000', '_fcstfld', 100, true);
%
%   Based on the read pattern in Jie Yu's post_ffout_4yadi.m (NRL, 2019).

if nargin < 11
    transpose2d = true;
end

% --- Build the level-tag portion of the file name ---
if nlev == 1
    lvl_str = sprintf('_sfc_000000_000000_%do', nest);
    reclen  = igrd * jgrd;
else
    if isface
        lvl_out = nlev + 1;
    else
        lvl_out = nlev;
    end
    lvl_str = sprintf('_mod_000001_%06d_%do', lvl_out, nest);
    reclen  = igrd * jgrd * lvl_out;
end

% --- Build the grid-dimension portion ---
grd_str = sprintf('%04dx%04d', igrd, jgrd);

% --- Assemble the full file name ---
file_name = fullfile(path_ff, ...
    [fldname, lvl_str, grd_str, '_', datestr_in, '_', timetag, appd]);

% --- Read the binary flat file (big-endian, single precision) ---
fid = fopen(file_name, 'r', 'ieee-be');
if fid == -1
    error('read_ncom_flatfile:fileNotFound', ...
        'Could not open file: %s', file_name);
end
[tmp, count] = fread(fid, reclen, 'real*4');
fclose(fid);

if count ~= reclen
    error('read_ncom_flatfile:sizeMismatch', ...
        ['Read %d values from %s, expected %d. ', ...
         'Check igrd/jgrd/nlev/isface against the file name.'], ...
        count, file_name, reclen);
end

% --- Reshape into the correct array shape ---
if nlev == 1
    data = reshape(tmp, igrd, jgrd);
    if transpose2d
        data = data';   % (jgrd x igrd), matches hgrd.lon/lat convention
    end
else
    data = reshape(tmp, igrd, jgrd, lvl_out);   % kept in native NCOM form
end

end