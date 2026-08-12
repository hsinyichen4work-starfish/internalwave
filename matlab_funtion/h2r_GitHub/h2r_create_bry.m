function h2r_create_bry(bryname,grdname,obcflag,param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   function h2r_create_bry(bryname,grdname,obcflag,...
%                          chdscd,cycle)
%
%   Input:
%
%   bryname      Netcdf climatology file name (character string)
%   grdname      Netcdf grid file name (character string)
%   obcflag      open boundary flag (1=open, [S E N W])
%   chdscd       S-coordinate parameters (object)

%
%
% get S-coordinate parameters
%
type    = 'BOUNDARY file';
history = 'ROMS';

theta_b = param.theta_b;
theta_s = param.theta_s;
hc      = param.hc;
N       = param.N;
%
%
%  Read the grid file and check the topography
%
% h       = ncread(grdname, 'h');
maskr   = ncread(grdname, 'mask_rho');
[Lp,Mp] = size(maskr);
% hmin   = min(min(h(maskr==1)));

L  = Lp - 1;
M  = Mp - 1;
% Np = N  + 1;

ncid = netcdf.create(bryname,'CLOBBER');
%Define the dimensions
dimidxiu = netcdf.defDim(ncid,'xi_u',L);
dimidxirho = netcdf.defDim(ncid,'xi_rho',Lp);
dimidetav = netcdf.defDim(ncid,'eta_v',M);
dimidetarho = netcdf.defDim(ncid,'eta_rho',Mp);
dimidsrho = netcdf.defDim(ncid,'s_rho',N);
dimidt = netcdf.defDim(ncid,'bry_time',netcdf.getConstant('NC_UNLIMITED'));
dimidone = netcdf.defDim(ncid,'one',1);

Data_theta_s = netcdf.defVar(ncid,'theta_s','double',dimidone);
netcdf.putAtt(ncid,Data_theta_s,'long_name','S-coordinate surface control parameter');
netcdf.putAtt(ncid,Data_theta_s,'units','nondimensional');

Data_theta_b = netcdf.defVar(ncid,'theta_b','double',dimidone);
netcdf.putAtt(ncid,Data_theta_b,'long_name','S-coordinate bottom control parameter');
netcdf.putAtt(ncid,Data_theta_b,'units','nondimensional');

%Data_Tcline = netcdf.defVar(ncid,'Tcline','double',[dimidone]);
Data_hc = netcdf.defVar(ncid,'hc','double',dimidone);
netcdf.putAtt(ncid,Data_hc,'long_name','S-coordinate parameter, critical depth');
netcdf.putAtt(ncid,Data_hc,'units','meter');

Data_brytime = netcdf.defVar(ncid,'bry_time','double',dimidt);
netcdf.putAtt(ncid,Data_brytime,'long_name','time for boundary data');
netcdf.putAtt(ncid,Data_brytime,'units','day');



%
%  Create variables
%
%
if obcflag(1)==1  %%   Southern boundary
%
  Data_temp_south =  netcdf.defVar(ncid,'temp_south', 'float', [dimidxirho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_temp_south,'long_name','southern boundary potential temperature');
  netcdf.putAtt(ncid,Data_temp_south,'units','Celsius');

  Data_salt_south =  netcdf.defVar(ncid,'salt_south', 'float', [dimidxirho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_salt_south,'long_name','southern boundary salinity');
  netcdf.putAtt(ncid,Data_salt_south,'units','PSU');
 
  Data_u_south    =  netcdf.defVar(ncid,'u_south', 'float', [dimidxiu dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_u_south,'long_name','southern boundary u-momentum component');
  netcdf.putAtt(ncid,Data_u_south,'units','meter second-1');

  Data_v_south    =  netcdf.defVar(ncid,'v_south', 'float', [dimidxirho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_v_south,'long_name','southern boundary v-momentum component');
  netcdf.putAtt(ncid,Data_v_south,'units','meter second-1');

  Data_ubar_south =  netcdf.defVar(ncid,'ubar_south', 'float', [dimidxiu dimidt]);
  netcdf.putAtt(ncid,Data_ubar_south,'long_name','southern boundary vertically integrated u-momentum component')
  netcdf.putAtt(ncid,Data_ubar_south,'units','meter second-1');

  Data_vbar_south =  netcdf.defVar(ncid,'vbar_south', 'float', [dimidxirho dimidt]);
  netcdf.putAtt(ncid,Data_vbar_south,'long_name','southern boundary vertically integrated v-momentum component');
  netcdf.putAtt(ncid,Data_vbar_south,'units','meter second-1');

  Data_zeta_south =  netcdf.defVar(ncid,'zeta_south', 'float', [dimidxirho dimidt]);
  netcdf.putAtt(ncid,Data_zeta_south,'long_name','southern boundary sea surface height');
  netcdf.putAtt(ncid,Data_zeta_south,'units','meter');
%
end
%
%
if obcflag(2)==1  %%   Eastern boundary
%
  Data_temp_east =  netcdf.defVar(ncid,'temp_east', 'float', [dimidetarho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_temp_east,'long_name','eastern boundary potential temperature');
  netcdf.putAtt(ncid,Data_temp_east,'units','Celsius');

  Data_salt_east =  netcdf.defVar(ncid,'salt_east', 'float', [dimidetarho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_salt_east,'long_name','eastern boundary salinity');
  netcdf.putAtt(ncid,Data_salt_east,'units','PSU');

  Data_u_east    =  netcdf.defVar(ncid,'u_east', 'float', [dimidetarho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_u_east,'long_name','eastern boundary u-momentum component');
  netcdf.putAtt(ncid,Data_u_east,'units','meter second-1');

  Data_v_east    =  netcdf.defVar(ncid,'v_east', 'float', [dimidetav dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_v_east,'long_name','eastern boundary v-momentum component');
  netcdf.putAtt(ncid,Data_v_east,'units','meter second-1');

  Data_ubar_east =  netcdf.defVar(ncid,'ubar_east', 'float', [dimidetarho dimidt]);
  netcdf.putAtt(ncid,Data_ubar_east,'long_name','eastern boundary vertically integrated u-momentum component')
  netcdf.putAtt(ncid,Data_ubar_east,'units','meter second-1');

  Data_vbar_east =  netcdf.defVar(ncid,'vbar_east', 'float', [dimidetav dimidt]);
  netcdf.putAtt(ncid,Data_vbar_east,'long_name','eastern boundary vertically integrated v-momentum component');
  netcdf.putAtt(ncid,Data_vbar_east,'units','meter second-1');

  Data_zeta_east =  netcdf.defVar(ncid,'zeta_east', 'float', [dimidetarho dimidt]);
  netcdf.putAtt(ncid,Data_zeta_east,'long_name','eastern boundary sea surface height');
  netcdf.putAtt(ncid,Data_zeta_east,'units','meter');

%
end
%
if obcflag(3)==1  %%   Northern boundary
%
  Data_temp_north =  netcdf.defVar(ncid,'temp_north', 'float', [dimidxirho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_temp_north,'long_name','northern boundary potential temperature');
  netcdf.putAtt(ncid,Data_temp_north,'units','Celsius');

  Data_salt_north =  netcdf.defVar(ncid,'salt_north', 'float', [dimidxirho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_salt_north,'long_name','northern boundary salinity');
  netcdf.putAtt(ncid,Data_salt_north,'units','PSU');

  Data_u_north    =  netcdf.defVar(ncid,'u_north', 'float', [dimidxiu dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_u_north,'long_name','northern boundary u-momentum component');
  netcdf.putAtt(ncid,Data_u_north,'units','meter second-1');

  Data_v_north    =  netcdf.defVar(ncid,'v_north', 'float', [dimidxirho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_v_north,'long_name','northern boundary v-momentum component');
  netcdf.putAtt(ncid,Data_v_north,'units','meter second-1');

  Data_ubar_north =  netcdf.defVar(ncid,'ubar_north', 'float', [dimidxiu dimidt]);
  netcdf.putAtt(ncid,Data_ubar_north,'long_name','northern boundary vertically integrated u-momentum component')
  netcdf.putAtt(ncid,Data_ubar_north,'units','meter second-1');

  Data_vbar_north =  netcdf.defVar(ncid,'vbar_north', 'float', [dimidxirho dimidt]);
  netcdf.putAtt(ncid,Data_vbar_north,'long_name','northern boundary vertically integrated v-momentum component');
  netcdf.putAtt(ncid,Data_vbar_north,'units','meter second-1');

  Data_zeta_north =  netcdf.defVar(ncid,'zeta_north', 'float', [dimidxirho dimidt]);
  netcdf.putAtt(ncid,Data_zeta_north,'long_name','northern boundary sea surface height');
  netcdf.putAtt(ncid,Data_zeta_north,'units','meter');

end
%
if obcflag(4)==1  %%   Western boundary
  Data_temp_west =  netcdf.defVar(ncid,'temp_west', 'float', [dimidetarho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_temp_west,'long_name','western boundary potential temperature');
  netcdf.putAtt(ncid,Data_temp_west,'units','Celsius');

  Data_salt_west =  netcdf.defVar(ncid,'salt_west', 'float', [dimidetarho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_salt_west,'long_name','western boundary salinity');
  netcdf.putAtt(ncid,Data_salt_west,'units','PSU');

  Data_u_west    =  netcdf.defVar(ncid,'u_west', 'float', [dimidetarho dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_u_west,'long_name','western boundary u-momentum component');
  netcdf.putAtt(ncid,Data_u_west,'units','meter second-1');
 
  Data_v_west    =  netcdf.defVar(ncid,'v_west', 'float', [dimidetav dimidsrho dimidt]);
  netcdf.putAtt(ncid,Data_v_west,'long_name','western boundary v-momentum component');
  netcdf.putAtt(ncid,Data_v_west,'units','meter second-1');

  Data_ubar_west =  netcdf.defVar(ncid,'ubar_west', 'float', [dimidetarho dimidt]);
  netcdf.putAtt(ncid,Data_ubar_west,'long_name','western boundary vertically integrated u-momentum component')
  netcdf.putAtt(ncid,Data_ubar_west,'units','meter second-1');

  Data_vbar_west =  netcdf.defVar(ncid,'vbar_west', 'float', [dimidetav dimidt]);
  netcdf.putAtt(ncid,Data_vbar_west,'long_name','western boundary vertically integrated v-momentum component');
  netcdf.putAtt(ncid,Data_vbar_west,'units','meter second-1');

  Data_zeta_west =  netcdf.defVar(ncid,'zeta_west', 'float', [dimidetarho dimidt]);
  netcdf.putAtt(ncid,Data_zeta_west,'long_name','western boundary sea surface height');
  netcdf.putAtt(ncid,Data_zeta_west,'units','meter');

end
%

% Create global attributes

netcdf.putAtt(ncid, -1 ,'title','Boundary file produced by r2r');
netcdf.putAtt(ncid, -1 ,'date',date);
netcdf.putAtt(ncid, -1 ,'grd_file',grdname);
netcdf.putAtt(ncid, -1 ,'type',type);
netcdf.putAtt(ncid, -1 ,'history',history);
netcdf.putAtt(ncid, -1 ,'VertCoordType','NEW');
% Leave define mode
netcdf.endDef(ncid);

%
% Write variables
%
netcdf.putVar(ncid,Data_theta_s,theta_s);
netcdf.putVar(ncid,Data_theta_b,theta_b);
%netcdf.putVar(ncid,Data_Tcline,hc);
netcdf.putVar(ncid,Data_hc,hc);

netcdf.close(ncid)
