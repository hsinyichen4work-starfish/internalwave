
chd_name = 'usw42';
par_name = '061_archv.2011_274_01';

%% Parameters for H2R
% Parent
par_dir    = '/data2/mbui/for_olad/061targz/'; 
par_grd    = [par_name, '_lthick.nc'];
par_ini_u  = [par_name, '_uv.nc'];
par_ini_v  = [par_name, '_uv.nc'];
par_ini_t  = [par_name, '_ts.nc'];
par_ini_s  = [par_name, '_ts.nc'];
par_ini_eta= [par_name, '_ssh.nc'];
par_N = 41;
par_tind   = 1;            % frame number in parent file

% Child...
chd_dir    = '/data2/olad/h2r/output/';
chd_grd    = 'usw42_grd.nc';
chd_file   = [chd_name, '_ini.nc'];        % name of new ini file
chd_thetas = 6;
chd_thetab = 3;
chd_hc     = 250;
chd_N      = 60;
chd_ang    = 'rad';
chdscoord  = 'new2008';                 % child 'new' or 'old' type scoord

%% number of chunk
ndomx      = 1;
ndomy      = 1;

%% Child and parent s-coord parameters into chdscd and parscd
chdscd.N       = chd_N;
chdscd.theta_s = chd_thetas;
chdscd.theta_b = chd_thetab;
chdscd.hc      = chd_hc;
par.N = par_N;

%% ROMS parent and child grid files
pargrd  = [par_dir par_grd];
pariniu = [par_dir par_ini_u];
pariniv = [par_dir par_ini_v];
parinit = [par_dir par_ini_t];
parinis = [par_dir par_ini_s];
parinie = [par_dir par_ini_eta];
chdgrd  = [chd_dir chd_grd];
chdini  = [chd_dir chd_file];

disp(['>>> Creating initial file: ' chdini]);
h2r_create_ini(chdini, chdgrd, chd_N, chdscd, 'clobber')

h2r_make_ini(pargrd, par_tind, pariniu, pariniv, parinit, parinis, ...
    parinie, chdgrd, chdini, chdscd, chdscoord, ndomx, ndomy,chd_ang,par.N)

