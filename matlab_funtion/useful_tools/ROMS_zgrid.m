function [zr] = ROMS_zgrid(h,zeta,scoord,type)
    
    %  On Input:
    %
    %    type    'r': rho point 'w': w point
        if isempty(zeta)
            [Mp,Lp] = size(h);
            zeta = zeros(Mp,Lp);
        end
    
        theta_s = scoord.theta_s;
        theta_b = scoord.theta_b;
        hc      = scoord.hc;
        N       = scoord.N;
        vtrans  = scoord.scoord;
    
        if type=='w'
            zr = zlevs3(h, zeta, theta_s, theta_b, hc, N, 'w', vtrans); 
        else
            zr = zlevs3(h, zeta, theta_s, theta_b, hc, N, 'r', vtrans); 
        end
    
    end