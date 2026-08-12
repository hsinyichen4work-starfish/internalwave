%---------------------------------------------------------------------------------------
%
%  make_hycom2roms_boundary_file
%
%  Generate boundary perimeter file from HYCOM parent data.

%---------------------------------------------------------------------------------------
% clear all
% close all
disp(' ')
%---------------------------------------------------------------------------------------
% USER-DEFINED VARIABLES & OPTIONS START HERE
%---------------------------------------------------------------------------------------
%
%---------------------------------------------------------------------------------------
% 1.  GENERAL
%---------------------------------------------------------------------------------------

par_dir    = '/data2/mbui/for_olad/061targz/';
par_namea = '061_archv.2011_274_01';
par_grd1    = [par_namea, '_lthick.nc'];
pargrd1  = [par_dir par_grd1];
Np = 41;

chd_dir    = '/data2/olad/h2r/output/';
chd_grd    = 'usw42_grd.nc';
chd_thetas = 6;
chd_thetab = 3;
chd_hc     = 250;
chd_N      = 60;
chd_ang    = 'rad';
chdscoord  = 'new2008';                 % child 'new' or 'old' type scoord
chdgrd     = [chd_dir, chd_grd];

%---------------------------------------------------------------------------------------
% 2. BOUNDARY FILE
%---------------------------------------------------------------------------------------
obcflag              = [1 0 1 1];      % open boundaries flag (1=open , [S E N W])
bry_cycle            =  0;             % 0 means no cycle
bry_filename         = 'usw42_bry_CCS.nc'; % bry filename

%---------------------------------------------------------------------------------------
% USER-DEFINED VARIABLES & OPTIONS END HERE
%---------------------------------------------------------------------------------------
%

% Put the various paths/filenames/variables together

% Child and parent s-coord parameters into chdscd and parscd
chdscd.theta_s = chd_thetas;
chdscd.theta_b = chd_thetab;
chdscd.hc      = chd_hc;
chdscd.N       = chd_N;
chdscd.scoord  = chdscoord;

%---------------------------------------------------------------------------------------
%   BOUNDARY PERIMETER FILE
%---------------------------------------------------------------------------------------

bry_filename  = [chd_dir bry_filename];

disp(['Creating boundary file: ' bry_filename]);
h2r_create_bry(bry_filename,chdgrd,obcflag,chdscd);

% Get parent subgrid bounds
disp(' ')
disp('Get parent subgrids for each open boundary')
limits = h2r_bry_subgrid(pargrd1, chdgrd,obcflag);

fname = [];
for ii = 274
    for jj = 1
        fname = [fname;['061_archv.2011_' sprintf('%03d',ii) '_' sprintf('%02d',jj)]];
    end
end

[TT,UU] = size(fname);

for ii = 1:TT
    par_name = fname(ii,:);
    
    par_ini_u  = [par_name, '_uv.nc'];    
    par_ini_t  = [par_name, '_ts.nc'];    
    par_ini_eta= [par_name, '_ssh.nc'];
    par_grd    = [par_name, '_lthick.nc'];
    
    pariniu = [par_dir par_ini_u];    
    parinit = [par_dir par_ini_t];    
    parinie = [par_dir par_ini_eta];
    pargrd  = [par_dir par_grd];
    
    h2r_bry_hv(pargrd,   ...
        chdgrd, parinie, parinit, pariniu, Np, bry_filename,   ...
        chdscd,obcflag,limits,ii);
end
disp(' ')
disp('=============== Boundary file done ===============')
disp(' ')


