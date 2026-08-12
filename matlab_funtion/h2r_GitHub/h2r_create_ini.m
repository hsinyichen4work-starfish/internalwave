function h2r_create_ini(ininame,grdname,N,chdscd,clobber)
%
%   Input: 
% 
%   ininame      Netcdf initial file name (character string).
%   grdname     Netcdf grid file name (character string).
%   clobber      Switch to allow writing over an existing
%                file (character string)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Read the grid file and check the topography
%
h       = ncread(grdname, 'h');
maskr   = ncread(grdname, 'mask_rho');
[Lp Mp] = size(maskr);
hmin   = min(min(h(maskr==1)));

L  = Lp - 1;
M  = Mp - 1;
Np = N  + 1;

%
%  Create the initial file
%


type    = 'hycom2roms initial file';

if (exist(ininame, 'file'))
  eval(['!rm ', ininame]);
end
mode = netcdf.getConstant('NETCDF4');
ncid = netcdf.create([ininame],mode);
%
%  Create dimensions
%
%Define the dimensions
dimidxiu    = netcdf.defDim(ncid,'xi_u',L);
dimidxiv     = netcdf.defDim(ncid,'xi_v',Lp);
dimidxirho  = netcdf.defDim(ncid,'xi_rho',Lp);
dimidetau   = netcdf.defDim(ncid,'eta_u',Mp);
dimidetav   = netcdf.defDim(ncid,'eta_v',M);
dimidetarho = netcdf.defDim(ncid,'eta_rho',Mp);
dimidsrho   = netcdf.defDim(ncid,'s_rho',N);
dimidsw     = netcdf.defDim(ncid,'s_w',Np);
dimidtracer = netcdf.defDim(ncid,'tracer',2);
dimidt      = netcdf.defDim(ncid,'time',1);
dimidone    = netcdf.defDim(ncid,'one',1);


%
%  Create variables
%
Data_tstart  =  netcdf.defVar(ncid,'tstart', 'float', [dimidone]);
Data_tend    =  netcdf.defVar(ncid,'tend', 'float', [dimidone]);
Data_theta_s = netcdf.defVar(ncid,'theta_s','double',[dimidone]);
Data_theta_b = netcdf.defVar(ncid,'theta_b','double',[dimidone]);
Data_Tcline  = netcdf.defVar(ncid,'Tclinec','double',[dimidone]);
Data_hc      = netcdf.defVar(ncid,'hc','double',[dimidone]);
Data_scr     = netcdf.defVar(ncid,'sc_r','double',[dimidsrho]);
Data_csr     = netcdf.defVar(ncid,'Cs_r','double',[dimidsrho]);
Data_csw     = netcdf.defVar(ncid,'Cs_w','double',[dimidsw]);
Data_time    = netcdf.defVar(ncid,'ocean_time','double',[dimidt]);

Data_u       =  netcdf.defVar(ncid,'u', 'float', [dimidxiu dimidetau dimidsrho dimidt]);
Data_v       =  netcdf.defVar(ncid,'v', 'float', [dimidxiv dimidetav dimidsrho dimidt]);
Data_ubar    =  netcdf.defVar(ncid,'ubar', 'float', [dimidxiu dimidetau dimidt]);
Data_vbar    =  netcdf.defVar(ncid,'vbar', 'float', [dimidxiv dimidetav dimidt]);
Data_zeta    =  netcdf.defVar(ncid,'zeta', 'float', [dimidxirho dimidetarho dimidt]);
Data_temp    =  netcdf.defVar(ncid,'temp', 'float', [dimidxirho dimidetarho dimidsrho dimidt]);
Data_salt    =  netcdf.defVar(ncid,'salt', 'float', [dimidxirho dimidetarho dimidsrho dimidt]);


%

%  Create attributes
%
netcdf.putAtt(ncid,Data_tstart,'long_name','start processing day');
netcdf.putAtt(ncid,Data_tstart,'units','day');

netcdf.putAtt(ncid,Data_tend,'long_name','end processing day');
netcdf.putAtt(ncid,Data_tend,'units','day');

netcdf.putAtt(ncid,Data_theta_s,'long_name','S-coordinate surface control parameter');
netcdf.putAtt(ncid,Data_theta_s,'units','nondimensional');

netcdf.putAtt(ncid,Data_theta_b,'long_name','S-coordinate bottom control parameter');
netcdf.putAtt(ncid,Data_theta_b,'units','nondimensional');

netcdf.putAtt(ncid,Data_Tcline,'long_name','S-coordinate surface/bottom layer width');
netcdf.putAtt(ncid,Data_Tcline,'units','meter');

netcdf.putAtt(ncid,Data_hc,'long_name','S-coordinate parameter, critical depth');
netcdf.putAtt(ncid,Data_hc,'units','meter');

netcdf.putAtt(ncid,Data_time,'long_name','time since initialization');
netcdf.putAtt(ncid,Data_time,'units','second');


netcdf.putAtt(ncid,Data_temp,'long_name','potential temperature');
netcdf.putAtt(ncid,Data_temp,'units','Celsius');

netcdf.putAtt(ncid,Data_salt,'long_name','salinity');
netcdf.putAtt(ncid,Data_salt,'units','PSU');

netcdf.putAtt(ncid,Data_u,'long_name','u-momentum component');
netcdf.putAtt(ncid,Data_u,'units','meter second-1');

netcdf.putAtt(ncid,Data_v,'long_name','v-momentum component');
netcdf.putAtt(ncid,Data_v,'units','meter second-1');

netcdf.putAtt(ncid,Data_ubar,'long_name','vertically integrated u-momentum component')
netcdf.putAtt(ncid,Data_ubar,'units','meter second-1');

netcdf.putAtt(ncid,Data_vbar,'long_name','vertically integrated v-momentum component');
netcdf.putAtt(ncid,Data_vbar,'units','meter second-1');

netcdf.putAtt(ncid,Data_zeta,'long_name','sea surface height');
netcdf.putAtt(ncid,Data_zeta,'units','meter');


%
% Create global attributes
%
netcdf.putAtt(ncid, -1 ,'title','Initial file produced by h2r');
netcdf.putAtt(ncid, -1 ,'date',date);
netcdf.putAtt(ncid, -1 ,'clim_file',ininame);
netcdf.putAtt(ncid, -1 ,'grd_file',grdname);
netcdf.putAtt(ncid, -1 ,'type',type);
netcdf.putAtt(ncid, -1 ,'history','none');
netcdf.putAtt(ncid, -1 ,'hc',chdscd.hc);
netcdf.putAtt(ncid, -1 ,'VertCoordType','NEW');
%
netcdf.endDef(ncid);
%
%
% Write variables
%


netcdf.putVar(ncid,Data_tstart,1.0);
netcdf.putVar(ncid,Data_tend,1.0);
netcdf.putVar(ncid,Data_theta_b,chdscd.theta_b);
netcdf.putVar(ncid,Data_theta_s,chdscd.theta_s);
netcdf.putVar(ncid,Data_Tcline,chdscd.hc);
netcdf.putVar(ncid,Data_hc,chdscd.hc);
netcdf.putVar(ncid,Data_time,1.0*24*3600);

netcdf.close(ncid)

return


