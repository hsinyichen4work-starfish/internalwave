function [xc,yc,idx] = cloest_point(xline,yline,xpoint,ypoint)
    distances = sqrt((xline - xpoint).^2 + (yline - ypoint).^2);
    [minDist, idx] = min(distances);
    xc = xline(idx);
    yc = yline(idx);
end