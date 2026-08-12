function out = extract_section_data(lon, lat, dim, idx, varargin)
    %EXTRACT_SECTION  Extract a cross-section (transect) along a grid-index
    %                 line from a curvilinear grid, for any number of fields.
    %
    %   out = extract_section(lon, lat, dim, idx, 'name1', field1, 'name2', field2, ...)
    %
    %   INPUTS
    %   ------
    %   lon, lat : 2D grid arrays (degrees), e.g. lon_rho, lat_rho
    %   dim      : 'row' (constant j, section varies along i / xi-direction)
    %              or 'col' (constant i, section varies along j / eta-direction)
    %   idx      : the index of the row/column to extract
    %   name/field pairs : any number of fields to slice along the same line.
    %              Each field's FIRST TWO dimensions must match size(lon).
    %              Fields can be 2D (e.g. bathymetry) or have any number of
    %              additional trailing dimensions (e.g. depth, time) -- those
    %              are preserved untouched; only the horizontal dims are sliced.
    %
    %   OUTPUT
    %   ------
    %   out : struct with fields:
    %           out.dist          -- along-track distance (km) from section start
    %           out.lon, out.lat  -- lon/lat along the section
    %           out.(name1), out.(name2), ... -- each requested field, sliced
    %
    %   EXAMPLE
    %   -------
    %   % Just bathymetry, as in the original function:
    %   out = extract_section(lon_rho, lat_rho, 'row', 250, 'h', h);
    %   plot(out.dist, -out.h)
    %
    %   % Bathymetry plus a 3D temperature field (lon x lat x depth):
    %   out = extract_section(lon_rho, lat_rho, 'row', 250, 'h', h, 'temp', temp);
    %   pcolor(out.dist, 1:size(out.temp,2), out.temp'); shading interp
    %
    %   % Multiple fields including a 4D one (lon x lat x depth x time):
    %   out = extract_section(lon_rho, lat_rho, 'col', 100, ...
    %             'temp', temp, 'salt', salt, 'u', u_true);
    
        if mod(numel(varargin), 2) ~= 0
            error('extract_section:badInput', ...
                'Fields must be given as name/value pairs, e.g. ''h'', h.');
        end
    
        %% --- Compute the horizontal section geometry once ---
        if strcmpi(dim,'row')
            lon_sec = lon(idx,:);
            lat_sec = lat(idx,:);
        elseif strcmpi(dim,'col')
            lon_sec = lon(:,idx);
            lat_sec = lat(:,idx);
        else
            error('extract_section:badDim', 'dim must be ''row'' or ''col''');
        end
    
        % Along-track distance, computed directly from lon/lat geometry
        n = numel(lon_sec);
        seg_dist = zeros(n-1,1);
        for k = 1:n-1
            seg_dist(k) = gc_dist(lon_sec(k), lat_sec(k), lon_sec(k+1), lat_sec(k+1));
            % gc_dist from easy_grid.m -- returns meters; if lon/lat are in
            % degrees, check gc_dist's expected units and convert if needed
        end
        dist = [0; cumsum(seg_dist)]/1000;   % km
    
        out.dist = dist;
        out.lon  = lon_sec(:);
        out.lat  = lat_sec(:);
    
        %% --- Slice each requested field along the same line ---
        for p = 1:2:numel(varargin)
            fname = varargin{p};
            field = varargin{p+1};
    
            if ~ischar(fname) && ~isstring(fname)
                error('extract_section:badName', ...
                    'Field name at position %d must be a string.', p);
            end
    
            % Verify the field's horizontal dims actually match lon/lat --
            % catches transpose/orientation mismatches immediately with a
            % clear message, instead of a confusing size error deep inside
            % the slicing step (or worse, a silent wrong-location bug).
            if size(field,1) ~= size(lon,1) || size(field,2) ~= size(lon,2)
                error('extract_section:sizeMismatch', ...
                    ['Field ''%s'' has horizontal size %dx%d but lon/lat is ' ...
                     '%dx%d. Check for a transpose/orientation mismatch before ' ...
                     'proceeding.'], fname, size(field,1), size(field,2), ...
                     size(lon,1), size(lon,2));
            end
    
            out.(char(fname)) = slice_along_dim(field, dim, idx);
        end
    end
    
    function sec = slice_along_dim(field, dim, idx)
        % Slices a field of ANY number of dimensions along its first (row)
        % or second (col) dimension at index idx, preserving all other
        % (e.g. depth, time) dimensions untouched.
        nd = ndims(field);
        idxCell = repmat({':'}, 1, nd);
        if strcmpi(dim,'row')
            idxCell{1} = idx;
        else
            idxCell{2} = idx;
        end
        sec = squeeze(field(idxCell{:}));
    end