function blowup_test(i_blow,j_blow,k_blow,figure_path,casenum,files)
 
    ini_test_read = files.ini_test_read;
    grd_test_read = files.grd_test_read;
    ROMS_z = files.ROMS_z;

    blowup = [i_blow,j_blow,k_blow];
    temp0 = ini_test_read.temp;
    salt0 = ini_test_read.salt;
    u0 = ini_test_read.u;  v0 = ini_test_read.v;

    cd(figure_path)
    figure; clf; hold on
    clear ax
    ti = tiledlayout(3,3); 
    ti.Padding = "compact"; ti.TileSpacing = "tight";
    for i = blowup(1) - 1 : 1 : blowup(1) + 1
        for j = blowup(2) - 1 : 1 : blowup(2) + 1
            disp(append("(i,j)=(",num2str(i),",",num2str(j),")"))
            ax(i,j) = nexttile; hold on
            plot(squeeze(temp0(i,j,:)),...
                squeeze(ROMS_z(i,j,:)),"o-");
            xl = xlim;
            line(xl,ROMS_z(i,j,blowup(3))*[1 1])
            title(append("(i,j)=(",num2str(i),",",num2str(j),")"))
        end
    end
    saveas(gcf,append("initial_blowup_temp_case",num2str(casenum),".jpg"))

    figure; clf; hold on
    clear ax
    ti = tiledlayout(1,1); 
    ti.Padding = "compact"; ti.TileSpacing = "tight";
    nexttile; hold on
    for i = blowup(1) - 1 : 1 : blowup(1) + 1
        for j = blowup(2) - 1 : 1 : blowup(2) + 1
            disp(append("(i,j)=(",num2str(i),",",num2str(j),")"))
            plot(squeeze(temp0(i,j,:)),...
                squeeze(ROMS_z(i,j,:)),"o-");
            xl = xlim;
            line(xl,ROMS_z(i,j,blowup(3))*[1 1])
        end
    end
    saveas(gcf,append("initial_blowup_temp2_case",num2str(casenum),".jpg"))

    % figure;
    % ti = tiledlayout(3,3); 
    % ti.Padding = "compact"; ti.TileSpacing = "tight";
    % for di = -1:1
    %     for dj = -1:1
    %         nexttile; hold on % adjust indexing to taste
    %         plot(squeeze(temp0(blowup(1)+di, blowup(2)+dj, :)), 1:size(temp0,3), 'o-');
    %         title(sprintf('(i,j)=(%d,%d)', blowup(1)+di, blowup(2)+dj));
    %     end
    % end
    % saveas(gcf,append("initial_blowup_temp3_case",num2str(casenum),".jpg"))
    
    figure; ti = tiledlayout(3,3); 
    ti.Padding="compact"; ti.TileSpacing="tight";
    for di = -1:1
        for dj = -1:1
            nexttile; hold on
            plot(squeeze(u0(blowup(1)+di, blowup(2)+dj, :)), 1:size(u0,3), 'o-');
            plot(squeeze(v0(blowup(1)+di, blowup(2)+dj, :)), 1:size(v0,3), 'x-');
            title(sprintf('(i,j)=(%d,%d)', blowup(1)+di, blowup(2)+dj));
            legend('u','v',"location","southeast");
        end
    end
    saveas(gcf,append("initial_blowup_vel_case",num2str(casenum),".jpg"))

    figure; ti = tiledlayout(1,2); 
    ti.Padding="compact"; ti.TileSpacing="tight";
    nexttile; hold on
    for di = -1:1
    for dj = -1:1
        plot(squeeze(u0(blowup(1)+di, blowup(2)+dj, :)), 1:size(u0,3), 'o-');
    end
    end
    nexttile; hold on
    for di = -1:1
        for dj = -1:1
        plot(squeeze(v0(blowup(1)+di, blowup(2)+dj, :)), 1:size(v0,3), 'x-');
        end
    end
    saveas(gcf,append("initial_blowup_vel2_case",num2str(casenum),".jpg"))

    pm = grd_test_read.pm;
    pn = grd_test_read.pn;
    fprintf('dx=%.1f m, dy=%.1f m at (blowup(1),blowup(2))\n',...
      1/pm(blowup(1),blowup(2)), 1/pn(blowup(1),blowup(2)));
    fprintf('dx=%.1f m, dy=%.1f m at (blowup(1)+1,blowup(2)+1)\n',...
      1/pm(blowup(1)+1,blowup(2)+1), 1/pn(blowup(1)+1,blowup(2)+1));
    fprintf('dx=%.1f m, dy=%.1f m at (blowup(1)-1,blowup(2)-1)\n',...
      1/pm(blowup(1)-1,blowup(2)-1), 1/pn(blowup(1)-1,blowup(2)-1));
    

    k = blowup(3);i0 = blowup(1); j0 = blowup(2);
    window = 20;
    u_slice = squeeze(u0(i0-window:i0+window, j0-window:j0+window, k));
    v_slice = squeeze(v0(i0-window:i0+window, j0-window:j0+window, k));
    t_slice = squeeze(temp0(i0-window:i0+window, j0-window:j0+window, k));
    s_slice = squeeze(salt0(i0-window:i0+window, j0-window:j0+window, k));

    cd(figure_path)
    figure;
    subplot(2,2,1); imagesc(u_slice); 
    colorbar; title(append("u at k=",num2str(k))); daspect([1 1 1])
    subplot(2,2,2); imagesc(v_slice); 
    colorbar; title(append("v at k=",num2str(k)));daspect([1 1 1])
    subplot(2,2,3); imagesc(t_slice); 
    colorbar; title(append("temp at k=",num2str(k)));daspect([1 1 1])
    subplot(2,2,4); imagesc(s_slice); 
    colorbar; title(append("salt at k=",num2str(k)));daspect([1 1 1])
    saveas(gcf,append("initial_blowup_window_case",num2str(casenum),".jpg"))
    

    h_slice = grd_test_read.h(i0-window:i0+window, j0-window:j0+window);
    figure; imagesc(h_slice); ;daspect([1 1 1])
    colorbar; title('h (bathymetry) near blowup point');
    saveas(gcf,append("initial_blowup_bath_window_case",num2str(casenum),".jpg"))

    h_slice = ROMS_z(i0-window:i0+window, j0-window:j0+window,blowup(3));
    figure; imagesc(h_slice); ;daspect([1 1 1])
    colorbar; title('z grid near blowup point');
    saveas(gcf,append("initial_blowup_zwindow_case",num2str(casenum),".jpg"))
end