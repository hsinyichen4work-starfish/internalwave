function [zs] = NCOM_zgrid(NCOM_nc)
    zstt = NCOM_nc.layer_thickness;
    zst  = permute(zstt,[3 2 1]);
    [nn,ll,mm]=size(zst);
    zst(isnan(zst)) = 0;
    zs = zst;
    for i = 1:mm
        for j = 1:ll
            for k = 1:nn
                zs(k,j,i) = -nansum_ca(zst(1:k,j,i)) + 0.5*zst(k,j,i);
            end
        end
    end
    zs = flipud(zs);
end