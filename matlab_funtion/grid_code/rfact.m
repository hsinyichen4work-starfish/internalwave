function r = rfact(hr)
    %RFACT  Compute rx0 (Beckmann-Haidvogel slope parameter) for a bathymetry field.
    %   r = rfact(hr) returns the max |rx0| in xi- and eta-directions at each point.
    
        r1 = 0.*hr;
        r2 = 0.*hr;
        r1(1:end-1,:) = 0.5*(hr(2:end,:) - hr(1:end-1,:)) ./ ( hr(2:end,:) + hr(1:end-1,:) );
        r2(:,1:end-1) = 0.5*(hr(:,2:end) - hr(:,1:end-1)) ./ ( hr(:,2:end) + hr(:,1:end-1) );
        r = max(abs(r1), abs(r2));
    
    end