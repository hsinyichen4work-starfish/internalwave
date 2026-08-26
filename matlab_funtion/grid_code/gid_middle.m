function [mid,rot_ang] = gid_middle(mid_iter)
    mooring_path = '/home/mbui/ModelOutput/NCOM/NOPP_mooring/';
    load([mooring_path,'Amazon_nopp_mooring_final.mat'])

    for j = 1 : mid_iter
        if j == 1
            mid = [midpoints([mooring_lon(1),cpies_lon(end-2)]), midpoints([mooring_lat(1),cpies_lat(end-2)])];
        else
            mid_move = [midpoints([mooring_lon(1),mid(1)]), midpoints([mooring_lat(1),mid(2)])];
            mid = mid_move;
        end
    end
   
    [x,y] = lonlat2xy([mooring_lon(1),cpies_lon(end-2)], ...
        [mooring_lat(1),cpies_lat(end-2)],mid(1),mid(2));
    vec_moring = [-x(1)+x(2),-y(1)+y(2)]; 
    rot_ang = rad2deg(angle(vec_moring(1) + 1i * vec_moring(2)))-90;
end