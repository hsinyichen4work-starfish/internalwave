function h2r_create_frc(frcname,grdname)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %   function h2r_create_frc(frcname,grdname)
    %
    %   Creates an empty ROMS surface forcing NetCDF file (flux
    %   forcing, not bulk formula) with:
    %       sustr, svstr    - wind stress (u/v points)
    %       shflux          - net surface heat flux, non-solar (rho points)
    %       swflux          - surface salt/freshwater flux (rho points)
    %       swrad           - shortwave radiation (rho points)
    %       Pair            - sea level pressure (rho points, optional)
    %
    %   Input:
    %
    %   frcname      Netcdf forcing file name (character string)
    %   grdname      Netcdf grid file name (character string)
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    type    = 'FORCING file';
    history = 'ROMS';
    
    %
    %  Read the grid file and get dimensions
    %
    maskr   = ncread(grdname, 'mask_rho');
    [Lp,Mp] = size(maskr);
    
    L  = Lp - 1;   % xi_u  size
    M  = Mp - 1;   % eta_v size
    
    mode = netcdf.getConstant('NETCDF4');
    mode = bitor(mode, netcdf.getConstant('CLOBBER'));
    ncid = netcdf.create(frcname,mode);
    
    %
    %  Define dimensions
    %
    dimidxiu    = netcdf.defDim(ncid,'xi_u',L);
    dimidxiv    = netcdf.defDim(ncid,'xi_v',Lp);
    dimidxirho  = netcdf.defDim(ncid,'xi_rho',Lp);
    dimidetau   = netcdf.defDim(ncid,'eta_u',Mp);
    dimidetav   = netcdf.defDim(ncid,'eta_v',M);
    dimidetarho = netcdf.defDim(ncid,'eta_rho',Mp);
    
    dimid_sms   = netcdf.defDim(ncid,'sms_time',netcdf.getConstant('NC_UNLIMITED'));
    dimid_shf   = netcdf.defDim(ncid,'shf_time',netcdf.getConstant('NC_UNLIMITED'));
    dimid_swf   = netcdf.defDim(ncid,'swf_time',netcdf.getConstant('NC_UNLIMITED'));
    dimid_srf   = netcdf.defDim(ncid,'srf_time',netcdf.getConstant('NC_UNLIMITED'));
    dimid_pair  = netcdf.defDim(ncid,'pair_time',netcdf.getConstant('NC_UNLIMITED'));
    
    %
    %  Time variables
    %
    Data_sms_time = netcdf.defVar(ncid,'sms_time','double',dimid_sms);
    netcdf.putAtt(ncid,Data_sms_time,'long_name','surface momentum stress time');
    netcdf.putAtt(ncid,Data_sms_time,'units','day');
    
    Data_shf_time = netcdf.defVar(ncid,'shf_time','double',dimid_shf);
    netcdf.putAtt(ncid,Data_shf_time,'long_name','surface net heat flux time');
    netcdf.putAtt(ncid,Data_shf_time,'units','day');
    
    Data_swf_time = netcdf.defVar(ncid,'swf_time','double',dimid_swf);
    netcdf.putAtt(ncid,Data_swf_time,'long_name','surface salt/freshwater flux time');
    netcdf.putAtt(ncid,Data_swf_time,'units','day');
    
    Data_srf_time = netcdf.defVar(ncid,'srf_time','double',dimid_srf);
    netcdf.putAtt(ncid,Data_srf_time,'long_name','surface shortwave radiation time');
    netcdf.putAtt(ncid,Data_srf_time,'units','day');
    
    Data_pair_time = netcdf.defVar(ncid,'pair_time','double',dimid_pair);
    netcdf.putAtt(ncid,Data_pair_time,'long_name','surface air pressure time');
    netcdf.putAtt(ncid,Data_pair_time,'units','day');
    
    %
    %  Wind stress (staggered u/v points)
    %
    Data_sustr = netcdf.defVar(ncid,'sustr','float',[dimidxiu dimidetau dimid_sms]);
    netcdf.putAtt(ncid,Data_sustr,'long_name','surface u-momentum stress');
    netcdf.putAtt(ncid,Data_sustr,'units','Newton meter-2');
    
    Data_svstr = netcdf.defVar(ncid,'svstr','float',[dimidxiv dimidetav dimid_sms]);
    netcdf.putAtt(ncid,Data_svstr,'long_name','surface v-momentum stress');
    netcdf.putAtt(ncid,Data_svstr,'units','Newton meter-2');
    
    %
    %  Net surface heat flux (non-solar), rho points
    %
    Data_shflux = netcdf.defVar(ncid,'shflux','float',[dimidxirho dimidetarho dimid_shf]);
    netcdf.putAtt(ncid,Data_shflux,'long_name','surface net heat flux');
    netcdf.putAtt(ncid,Data_shflux,'units','Watt meter-2');
    
    %
    %  Surface salt/freshwater flux, rho points
    %
    Data_swflux = netcdf.defVar(ncid,'swflux','float',[dimidxirho dimidetarho dimid_swf]);
    netcdf.putAtt(ncid,Data_swflux,'long_name','surface freshwater flux (E-P)');
    netcdf.putAtt(ncid,Data_swflux,'units','centimeter day-1');
    
    %
    %  Shortwave radiation, rho points
    %
    Data_swrad = netcdf.defVar(ncid,'swrad','float',[dimidxirho dimidetarho dimid_srf]);
    netcdf.putAtt(ncid,Data_swrad,'long_name','solar shortwave radiation');
    netcdf.putAtt(ncid,Data_swrad,'units','Watt meter-2');
    netcdf.putAtt(ncid,Data_swrad,'positive_value','downward flux, heating');
    netcdf.putAtt(ncid,Data_swrad,'negative_value','upward flux, cooling');
    
    %
    %  Sea level pressure, rho points (optional)
    %
    Data_pair = netcdf.defVar(ncid,'Pair','float',[dimidxirho dimidetarho dimid_pair]);
    netcdf.putAtt(ncid,Data_pair,'long_name','surface air pressure');
    netcdf.putAtt(ncid,Data_pair,'units','millibar');
    
    %
    %  Global attributes
    %
    netcdf.putAtt(ncid, -1 ,'title','Surface forcing file produced by n2r (NCOM to ROMS)');
    netcdf.putAtt(ncid, -1 ,'date',date);
    netcdf.putAtt(ncid, -1 ,'grd_file',grdname);
    netcdf.putAtt(ncid, -1 ,'type',type);
    netcdf.putAtt(ncid, -1 ,'history',history);
    
    netcdf.endDef(ncid);
    netcdf.close(ncid)
    
    return