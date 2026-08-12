function grid_boundary_plot(lon,lat,color,width)

    if nargin < 4
        width = 0.5; 
    end
    if nargin < 3
        color = [0 0 0]; 
    end

    hold on
    plot(lon(1,:),lat(1,:),"color",color,"linewidth",width)
    plot(lon(end,:),lat(end,:),"color",color,"linewidth",width)
    plot(lon(:,1),lat(:,1),"color",color,"linewidth",width)
    plot(lon(:,end),lat(:,end),"color",color,"linewidth",width)
end
